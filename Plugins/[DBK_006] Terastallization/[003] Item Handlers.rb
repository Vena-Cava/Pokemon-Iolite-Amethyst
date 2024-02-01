#===============================================================================
# Code related to utilizing Tera Shards.
#===============================================================================

#-------------------------------------------------------------------------------
# Gets Tera Shards data.
#-------------------------------------------------------------------------------
module GameData
  class Item
    def is_tera_shard?
      return !@flags.none? { |f| f[/^TeraShard_/i] }
    end
	
    def tera_shard_type
      return if !is_tera_shard?
      @flags.each do |f|
        next if !f[/^TeraShard_(\w+)/i]
        return $~[1].to_sym
      end
    end
  end
end


#-------------------------------------------------------------------------------
# Using Tera Shards from the Bag.
#-------------------------------------------------------------------------------
alias tera_pbUseItem pbUseItem
def pbUseItem(bag, item, bagscene = nil)
  itm = GameData::Item.get(item)
  if itm.field_use && itm.is_tera_shard?
    if $player.pokemon_count == 0
      pbMessage(_INTL("There is no Pokémon."))
      return 0
    end
    tera = itm.tera_shard_type
    qty = [1, Settings::TERA_SHARDS_REQUIRED].max
    qty = 1 if !GameData::Type.exists?(tera)
    if $bag.has?(item, qty)
      ret = false
      annot = []
      $player.party.each do |pkmn|
        elig = pkmn.tera_type != tera && pkmn.getTeraType(true).nil?
        annot.push((elig) ? _INTL("ABLE") : _INTL("NOT ABLE"))
      end
      pbFadeOutIn {
        scene = PokemonParty_Scene.new
        screen = PokemonPartyScreen.new(scene, $player.party)
        screen.pbStartScene(_INTL("Use on which Pokémon?"), false, annot)
        loop do
          scene.pbSetHelpText(_INTL("Use on which Pokémon?"))
          chosen = screen.pbChoosePokemon
          if chosen < 0
            ret = false
            break
          end
          pkmn = $player.party[chosen]
          next if !pbCheckUseOnPokemon(item, pkmn, screen)
          ret = ItemHandlers.triggerUseOnPokemon(item, qty, pkmn, screen)
          screen.pbRefreshAnnotations(proc { |p| p.tera_type != tera && p.getTeraType(true).nil? })
          next unless ret && itm.consumed_after_use?
          bag.remove(item, qty)
          next if bag.has?(item, qty)
          if qty == 1
            pbMessage(_INTL("You used your last {1}.", itm.portion_name)) { screen.pbUpdate }
          else
            pbMessage(_INTL("Not enough {1} remaining...", itm.portion_name_plural)) { screen.pbUpdate }
          end
          break
        end
        screen.pbEndScene
        bagscene&.pbRefresh
      }
      return (ret) ? 1 : 0
    else
      pbMessage(_INTL("You don't have enough {1}...\nYou need {2} shards to change a Pokémon's Tera type.", 
                itm.portion_name_plural, qty))
    end
  else
    return tera_pbUseItem(bag, item, bagscene)
  end
end


#-------------------------------------------------------------------------------
# Using Tera Shards from the Party Menu.
#-------------------------------------------------------------------------------
alias tera_pbUseItemOnPokemon pbUseItemOnPokemon
def pbUseItemOnPokemon(item, pkmn, scene)
  itm = GameData::Item.get(item)
  if itm.is_tera_shard?
    tera = itm.tera_shard_type
    qty = [1, Settings::TERA_SHARDS_REQUIRED].max
    qty = 1 if !GameData::Type.exists?(tera)
    if $bag.has?(item, qty)  
      ret = ItemHandlers.triggerUseOnPokemon(item, qty, pkmn, scene)
      scene.pbClearAnnotations
      scene.pbHardRefresh
      if ret
        $bag.remove(item, qty)
        if !$bag.has?(item, qty)
          if qty == 1
            pbMessage(_INTL("You used your last {1}.", itm.name)) { scene.pbUpdate }
          else
            pbMessage(_INTL("Not enough {1} remaining...", itm.portion_name_plural)) { scene.pbUpdate }
          end
        end
      end
      return ret
    else
      pbMessage(_INTL("You don't have enough {1}...\nYou need {2} shards to change a Pokémon's Tera type.", 
                itm.portion_name_plural, qty)) { scene.pbUpdate }
      return false
    end
  else
    return tera_pbUseItemOnPokemon(item, pkmn, scene)
  end
end


#-------------------------------------------------------------------------------
# Tera Shards - Changes a Pokemon's Tera Type.
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemon.addIf(:tera_shards,
  proc { |item| GameData::Item.get(item).is_tera_shard? },
  proc { |item, qty, pkmn, scene|
    old_tera = pkmn.tera_type
    type = GameData::Item.get(item).tera_shard_type
    if type && pkmn.tera_type != type && pkmn.getTeraType(true).nil? && !pkmn.shadowPokemon?
      case type
      when :Random
        pkmn.tera_type = :Random
      when :Choose
        scene.pbDisplay(_INTL("Select a new Tera type for {1}.", pkmn.name))
        default = GameData::Type.get(pkmn.tera_type).icon_position
        newType = pbChooseTypeList(default < 10 ? default + 1 : default)
        pseudoType = GameData::Type.get(newType).pseudo_type
        if newType != pkmn.tera_type && !pseudoType && ![:QMARKS, :SHADOW].include?(newType)
          pkmn.tera_type = newType
        end
      else
        data = GameData::Type.try_get(type)
        if data && !data.pseudo_type && ![:QMARKS, :SHADOW].include?(type)
          pkmn.tera_type = type
        end
      end
    end
    if pkmn.tera_type != old_tera
      scene.pbDisplay(_INTL("{1}'s Tera type is now {2}.", pkmn.name, GameData::Type.get(pkmn.tera_type).name))
      $stats.total_tera_types_changed += 1
      scene.pbHardRefresh
      next true
    else
      scene.pbDisplay(_INTL("It won't have any effect."))
      next false
    end
  }
)


#-------------------------------------------------------------------------------
# Radiant Tera Jewel
#-------------------------------------------------------------------------------
# Restores your ability to use Terastallization if it was already used in battle.
# Using this item will take up your entire turn, and cannot be used if orders have
# already been given to a Pokemon.
#-------------------------------------------------------------------------------
ItemHandlers::CanUseInBattle.add(:RADIANTTERAJEWEL, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  side  = battler.idxOwnSide
  owner = battle.pbGetOwnerIndexFromBattlerIndex(battler.index)
  orb   = battle.pbGetTeraOrbName(battler.index)      
  if !battle.pbHasTeraOrb?(battler.index)
    scene.pbDisplay(_INTL("You don't have a {1} to charge!", orb))
    next false
  elsif !firstAction
    scene.pbDisplay(_INTL("You can't use this item while issuing orders at the same time!"))
    next false
  elsif battle.terastallize[side][owner] == -1 && $player.tera_charged?
    if showMessages
      scene.pbDisplay(_INTL("You don't need to recharge your {1} yet!", orb))
    end
    next false
  end
  next true
})

ItemHandlers::UseInBattle.add(:RADIANTTERAJEWEL, proc { |item, battler, battle|
  side    = battler.idxOwnSide
  owner   = battle.pbGetOwnerIndexFromBattlerIndex(battler.index)
  battle.terastallize[side][owner] = -1
  $player.tera_charged = true
  orb     = battle.pbGetTeraOrbName(battler.index)
  trainer = battle.pbGetOwnerName(battler.index)
  item    = GameData::Item.get(item).portion_name
  pbSEPlay(sprintf("Anim/Lucky Chant"))
  battle.pbDisplayPaused(_INTL("The {1} fully recharged {2}'s {3}!\n{2} can use Terastallization again!", item, trainer, orb))
})