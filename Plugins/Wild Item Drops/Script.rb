#===============================================================================
# Wild Drop Items - By Vendily [v21]
#===============================================================================
# This script adds in Wild Drop Items, allowing for Wild Pokémon to drop
#  specially defined items in the PBS upon fainting.
# They do not have to be the same as the items Wild Pokémon might generate with.
#===============================================================================
# The script is plug and play, you just need to add in the PBS information
#  `WildDropCommon`, `WildDropUncommon`, and `WildDropRare`, used in the same
#  way as the `WildItem` version. (You don't have to define all three.)
# The base rate is `[50,5,1]`, but if all three properties are the same then it
#  is a 100% rate.
# Check the `def pbFaint` here if you wish to modify the mechanics further
#  or change the windowskin colour to dark mode.
#===============================================================================

module GameData
  class Species
    attr_reader :wild_drop_common
    attr_reader :wild_drop_uncommon
    attr_reader :wild_drop_rare
    
    class << self
      alias_method :wild_drop_schema, :schema
      def schema(compiling_forms = false)
        ret = wild_drop_schema(compiling_forms)
        ret["WildDropCommon"]   = [:wild_drop_common,   "*s"]
        ret["WildDropUncommon"] = [:wild_drop_uncommon, "*s"]
        ret["WildDropRare"]     = [:wild_drop_rare,     "*s"]
        return ret
      end
      
      alias_method :wild_drop_editor_properties, :editor_properties
      def editor_properties
        ret = wild_drop_editor_properties
        ret.push(["WildDropCommon",    GameDataPoolProperty.new(:Item),    _INTL("Item(s) commonly dropped by wild Pokémon of this species.")])
        ret.push(["WildDropUncommon",  GameDataPoolProperty.new(:Item),    _INTL("Item(s) uncommonly dropped by wild Pokémon of this species.")])
        ret.push(["WildDropRare",      GameDataPoolProperty.new(:Item),    _INTL("Item(s) rarely dropped by wild Pokémon of this species.")])
        return ret
      end
    end
    alias wild_drop_initialize initialize
    def initialize(hash)
      wild_drop_initialize(hash)
      @wild_drop_common   = hash[:wild_drop_common]   || []
      @wild_drop_uncommon = hash[:wild_drop_uncommon] || []
      @wild_drop_rare     = hash[:wild_drop_rare]     || []
    end
  end
end

class Pokemon
  # @return [Array<Array<Symbol>>] the items this species can drop in the wild
  def wildDropItems
    sp_data = species_data
    return [sp_data.wild_drop_common, sp_data.wild_drop_uncommon, sp_data.wild_drop_rare]
  end
end

class Battle::Battler
  alias wild_drop_pbFaint pbFaint

  def pbFaint(showMessage = true)
    old_fainted = @fainted
    wild_drop_pbFaint(showMessage)

    return unless showMessage
    return unless @battle.wildBattle? && opposes?
    return unless @fainted && old_fainted != @fainted
    return unless @pokemon && @battle.internalBattle

    items = @pokemon.wildDropItems
    chances = [50, 5, 1]
    rnd = rand(100)

    drop_list = nil
    if (items[0] == items[1] && items[1] == items[2]) || rnd < chances[0]
      drop_list = items[0]
    elsif rnd < chances[0] + chances[1]
      drop_list = items[1]
    elsif rnd < chances[0] + chances[1] + chances[2]
      drop_list = items[2]
    else
      return
    end

    return if drop_list.nil? || drop_list.empty?

    drop_entry = drop_list
    return if drop_entry.nil?

    item_sym, qty = parse_drop_entry(drop_entry)
    return if item_sym.nil? || qty <= 0

    old_qty = $bag.quantity(item_sym)
    $bag.add(item_sym, qty)
    added = $bag.quantity(item_sym) - old_qty
    return if added <= 0

    item_data = GameData::Item.get(item_sym)
    name = (added > 1) ? item_data.portion_name_plural : item_data.portion_name
    pocket = item_data.pocket
    colour_tag = shadowc3tag([103, 159, 224], [16, 79, 150])

    @battle.pbDisplay(_INTL("{1} dropped {2}{3} x{4}</c3>!", pbThis, colour_tag, name, added))
    @battle.pbDisplay(_INTL("You put the {1} in\nyour Bag's <icon=bagPocket{2}>{3}{4}</c3> pocket.",
      name, pocket, colour_tag, PokemonBag.pocket_names[pocket - 1]))
  end

  private

  def parse_drop_entry(entry)
    parts = if entry.is_a?(Array)
               entry
            else
               entry.split(",").map(&:strip)
            end
    sym = parts[0].to_sym rescue nil
    return [nil, 0] if sym.nil?

    if parts.length == 1
      return [sym, 1]
    elsif parts.length == 2
      qty = parts[1].to_i
      return qty > 0 ? [sym, qty] : [nil, 0]
    elsif parts.length >= 3
      min_qty = parts[1].to_i
      max_qty = parts[2].to_i
      min_qty = 1 if min_qty <= 0
      max_qty = min_qty if max_qty < min_qty
      return [sym, rand(min_qty..max_qty)]
    end

    [nil, 0]
  end
end

