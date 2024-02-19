#===============================================================================
# Item handlers.
#===============================================================================

#-------------------------------------------------------------------------------
# Z-Crystal properties.
#-------------------------------------------------------------------------------
module GameData
  class Item
    attr_reader :zcombo, :real_held_description
	
    SCHEMA["HeldDescription"] = [:real_held_description, "q"]
    SCHEMA["ZCombo"]          = [:zcombo,               "*m"]
	
    alias zcrystal_initialize initialize
    def initialize(hash)
      zcrystal_initialize(hash)
      @real_held_description = hash[:real_held_description]
      @zcombo                = hash[:zcombo] || []
      if is_zcrystal?
        @pocket = Settings::BAG_MAX_POCKET_SIZE.length
      end
    end
    
    def is_zcrystal?; return has_flag?("ZCrystal");  end
    
    #---------------------------------------------------------------------------
    # Used to get alternate description text when a Z-Crystal is being held.
    #---------------------------------------------------------------------------
    def held_description
      return description if !@real_held_description
      return pbGetMessageFromHash(MessageTypes::HELD_ITEM_DESCRIPTIONS, @real_held_description)
    end
    
    #---------------------------------------------------------------------------
    # Aliased to update the debug item editor.
    #---------------------------------------------------------------------------
    Item.singleton_class.alias_method :zcrystal_editor_properties, :editor_properties
    def self.editor_properties
      properties = self.zcrystal_editor_properties
      properties.each_with_index do |prop, i|
        next if prop[0] != "Move"
        properties[i][2] = _INTL("The move taught by a TM/HM/TR, or a Z-Move linked to a Z-Crystal.")
        break
      end
      properties.concat([
        ["HeldDescription", StringProperty, _INTL("Alternate description of this item while it's being held by a Pokémon.")],
        ["ZCombo",          StringProperty, _INTL("A move ID followed by any number of species ID's. " +
                                                "Used as the base move and eligible species for a Z-Move.")]
      ])
      return properties
    end
    
    #---------------------------------------------------------------------------
    # Aliased for adding Z-Crystal held item icons.
    #---------------------------------------------------------------------------
    Item.singleton_class.alias_method :zcrystal_held_icon_filename, :held_icon_filename
    def self.held_icon_filename(item)
      ret = self.zcrystal_held_icon_filename(item)
      item_data = GameData::Item.get(item)
      if item_data.is_zcrystal?
        base = "Graphics/UI/Party/icon_"
        new_ret = base + "zcrystal_#{item_data.id}"
      return new_ret if pbResolveBitmap(new_ret)
      new_ret = base + "zcrystal"
      return new_ret if pbResolveBitmap(new_ret)
      end
      return ret
    end
    
    #---------------------------------------------------------------------------
    # Aliased so that Z-Crystals can't be sold/tossed.
    #---------------------------------------------------------------------------
    alias zcrystal_is_important? is_important? 
    def is_important?
      return zcrystal_is_important? || is_zcrystal?
    end
    
    #---------------------------------------------------------------------------
    # Aliased so that Z-Crystals cannot be removed in battle.
    #---------------------------------------------------------------------------
    alias zcrystal_unlosable? unlosable?
    def unlosable?(*args)
      return true if is_zcrystal?
      zcrystal_unlosable?(*args)
    end
    
    
    ############################################################################
    # Z-Move methods.
    ############################################################################
    
    
    #---------------------------------------------------------------------------
    # Gets the Z-Move linked to this Z-Crystal.
    #---------------------------------------------------------------------------
    def zmove
      return if !is_zcrystal?
      return @move
    end
    
    #---------------------------------------------------------------------------
    # Gets the move type of the Z-Move linked to this Z-Crystal.
    #---------------------------------------------------------------------------
    def zmove_type
      return if !is_zcrystal?
      return GameData::Move.get(@move).type
    end
    
    #---------------------------------------------------------------------------
    # Returns true if this Z-Crystal can only be used with a certain species/move.
    #---------------------------------------------------------------------------
    def has_zmove_combo?
      return false if !is_zcrystal?
      return @zcombo.length > 0
    end
    
    #---------------------------------------------------------------------------
    # Returns the base move that is required for this Z-Crystal's Z-Move, if any.
    #---------------------------------------------------------------------------
    def zmove_base_move
      return if !is_zcrystal?
      return @zcombo[0]
    end
    
    #---------------------------------------------------------------------------
    # Returns the eligible species that may use this Z-Crystal's Z-Move, if any.
    #---------------------------------------------------------------------------
    def zmove_species
      return @zcombo[1..@zcombo.length]
    end
  end
end


#-------------------------------------------------------------------------------
# Validates exclusive Z-Move data after all species have been compiled.
#-------------------------------------------------------------------------------
module Compiler
  alias zmove_validate_all_compiled_pokemon_forms validate_all_compiled_pokemon_forms
  def validate_all_compiled_pokemon_forms
    zmove_validate_all_compiled_pokemon_forms
    GameData::Item.each do |item|
	  next if !item.is_zcrystal?
	  if !item.move
	    raise _INTL("{1} is a Z-Crystal, but missing a Z-Move in the 'Move' field.\n{2}", item.id, FileLineData.linereport)
	  end
      next if item.zcombo.empty?
      params = item.zcombo
	  if params.length < 2
	    raise _INTL("{1} is a Z-Crystal, but the 'ZCombo' field is missing a move or a species.\n{2}", item.id, FileLineData.linereport)
	  end
      params.each_with_index do |param, i|
        enum = (i == 0) ? :Move : :Species
        params[i] = cast_csv_value(param, "e", enum)
      end
    end
  end
end


#-------------------------------------------------------------------------------
# Adds Z-Crystal pocket to the bag.
#-------------------------------------------------------------------------------
module Settings
  Settings.singleton_class.alias_method :zcrystal_bag_pocket_names, :bag_pocket_names
  def self.bag_pocket_names
    names = self.zcrystal_bag_pocket_names
    names.push(_INTL("Z-Crystals"))
    return names
  end
   
  BAG_MAX_POCKET_SIZE.push(-1)
  BAG_POCKET_AUTO_SORT.push(true)
end


#-------------------------------------------------------------------------------
# Fix to prevent Z-Crystals from duplicating in the bag.
#-------------------------------------------------------------------------------
class PokemonBag
  alias zcrystal_can_add? can_add?
  def can_add?(item, qty = 1)
    return true if GameData::Item.get(item).is_zcrystal?
    zcrystal_can_add?(item, qty)
  end
  
  alias zcrystal_add add
  def add(item, qty = 1)
    qty = 0 if has?(item, 1) && GameData::Item.get(item).is_zcrystal?
    zcrystal_add(item, qty)
  end
end


#-------------------------------------------------------------------------------
# Z-Crystals
#-------------------------------------------------------------------------------
# Equips a holdable crystal upon use. Pokemon may still equip a Z-Crystal even if
# they are incompatible with it, but a message will display saying that it can't
# be used. This message will not play, however, if the Z-Crystal would also allow
# for the species to Ultra Burst, even if the Pokemon itself can't use the Z-Move
# in its current state.
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemon.addIf(:zcrystals,
  proc { |item| GameData::Item.get(item).is_zcrystal? },
  proc { |item, qty, pkmn, scene|
    crystal    = GameData::Item.get(item).portion_name
    compatible = pkmn.has_zmove?(item) || pkmn.getUltraItem == item
    if pkmn.shadowPokemon? || pkmn.egg?
      scene.pbDisplay(_INTL("It won't have any effect."))
      next false
    elsif pkmn.item == item
      scene.pbDisplay(_INTL("{1} is already holding a piece of {2}.", pkmn.name, crystal))
      next false
    elsif !compatible && !scene.pbConfirm(_INTL("{1} cannot currently use this crystal's Z-Power. Is that OK?", pkmn.name))
      next false
    end
    scene.pbDisplay(_INTL("The piece of {1} will be given to {2} so that it may use its Z-Power!", crystal, pkmn.name))
    if pkmn.item
      heldItem = GameData::Item.get(pkmn.item)
      prefix = (heldItem.is_zcrystal?) ? "a piece of" : (heldItem.portion_name.starts_with_vowel?) ? "an" : "a"
      scene.pbDisplay(_INTL("{1} is already holding {2} {3}.\1", pkmn.name, prefix, heldItem.portion_name))
      if scene.pbConfirm(_INTL("Would you like to switch the two items?"))
        if !$bag.can_add?(pkmn.item)
          scene.pbDisplay(_INTL("The Bag is full. The Pokémon's item could not be removed."))
          next false
        else
          $bag.add(pkmn.item)
          itemname = (heldItem.is_zcrystal?) ? "piece of #{heldItem.name}" : heldItem.portion_name
          scene.pbDisplay(_INTL("You took {1}'s {2} and gave it a piece of {3}.", pkmn.name, itemname, crystal))
        end
      else
        next false
      end
    end
    pkmn.item = item
    pbSEPlay("Pkmn move learnt")
    scene.pbDisplay(_INTL("{1} is now holding a piece of {2}!", pkmn.name, crystal))
    next true
  }
)


#-------------------------------------------------------------------------------
# Z-Booster
#-------------------------------------------------------------------------------
# Restores your ability to use Z-Moves if one was already used in battle. Using
# this item will take up your entire turn, and cannot be used if orders have
# already been given to a Pokemon.
#-------------------------------------------------------------------------------
ItemHandlers::CanUseInBattle.add(:ZBOOSTER, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  side  = battler.idxOwnSide
  owner = battle.pbGetOwnerIndexFromBattlerIndex(battler.index)
  ring  = battle.pbGetZRingName(battler.index)      
  if !battle.pbHasZRing?(battler.index)
    scene.pbDisplay(_INTL("You don't have a {1} to charge!", ring))
    next false
  elsif !firstAction
    scene.pbDisplay(_INTL("You can't use this item while issuing orders at the same time!"))
    next false
  elsif battle.zMove[side][owner] == -1
    if showMessages
      scene.pbDisplay(_INTL("You don't need to recharge your {1} yet!", ring))
    end
    next false
  end
  next true
})

ItemHandlers::UseInBattle.add(:ZBOOSTER, proc { |item, battler, battle|
  side    = battler.idxOwnSide
  owner   = battle.pbGetOwnerIndexFromBattlerIndex(battler.index)
  battle.zMove[side][owner] = -1
  ring    = battle.pbGetZRingName(battler.index)
  trainer = battle.pbGetOwnerName(battler.index)
  item    = GameData::Item.get(item).portion_name
  pbSEPlay(sprintf("Anim/Lucky Chant"))
  battle.pbDisplayPaused(_INTL("The {1} fully recharged {2}'s {3}!\n{2} can use Z-Moves again!", item, trainer, ring))
})