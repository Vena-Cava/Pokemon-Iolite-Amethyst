#===============================================================================
# Meal Powers - Item Drop Power
# Gives wild Pokémon a chance to drop one additional item when their normal
# Wild Item Drop succeeds.
#===============================================================================

module MealPowers
  ITEM_DROP_BONUS_CHANCE = {
    0 => 0,
    1 => 25,
    2 => 50,
    3 => 100
  }

  #-----------------------------------------------------------------------------
  # Returns the currently active Item Drop Power data.
  #-----------------------------------------------------------------------------
  def self.item_drop_power
    return active.find { |p| p[:id] == :ITEMDROP }
  end

  #-----------------------------------------------------------------------------
  # Returns whether Item Drop Power applies to this Pokémon's type.
  #-----------------------------------------------------------------------------
  def self.item_drop_type_matches?(pkmn)
    power = item_drop_power
    return false if !power
    return false if !pkmn

    type = power[:option]
    return true if type == :ALL

    return pkmn.species_data.types.include?(type)
  end

  #-----------------------------------------------------------------------------
  # Returns the bonus-drop activation chance for this Pokémon.
  #-----------------------------------------------------------------------------
  def self.item_drop_bonus_chance(pkmn)
    return 0 if !item_drop_type_matches?(pkmn)

    power = item_drop_power
    return 0 if !power

    return ITEM_DROP_BONUS_CHANCE[power[:level]] || 0
  end
end

class Battle::Battler
  #-----------------------------------------------------------------------------
  # Called after the Wild Item Drops plugin successfully awards its normal item.
  #
  # If Item Drop Power activates, this makes one additional drop using the
  # defeated Pokémon's own WildDropCommon/WildDropUncommon/WildDropRare data.
  #-----------------------------------------------------------------------------
  def meal_power_try_bonus_item_drop(items)
    power = MealPowers.item_drop_power
    return if !power
    return if !@pokemon
    return if !MealPowers.item_drop_type_matches?(@pokemon)

    chance = MealPowers.item_drop_bonus_chance(@pokemon)
    return if chance <= 0

    activation_roll = rand(100)
    activated = activation_roll < chance

    if MealPowers::DEBUG
      puts "========================================"
      puts "ITEM DROP POWER DEBUG"
      puts "Pokémon: #{@pokemon.name}"
      puts "Species: #{@pokemon.species}"
      puts "Types: #{@pokemon.species_data.types.inspect}"
      puts "Selected Type: #{power[:option]}"
      puts "Item Drop Power Lv: #{power[:level]}"
      puts "Bonus Item Chance: #{chance}%"
      puts "Activation Roll: #{activation_roll}"
      puts "Bonus Activated?: #{activated}"
      puts "========================================"
    end

    return if !activated

    #-------------------------------------------------------------------------
    # Build a list of the drop tiers this species actually has.
    #
    # The original Wild Item Drops rates are:
    #   Common   = 50
    #   Uncommon = 5
    #   Rare     = 1
    #
    # We normalise those weights across the available tiers. The Item Drop
    # Power activation itself has already decided that an additional item
    # should be awarded, so there is no second "no item" result here.
    #-------------------------------------------------------------------------
    weights = [50, 5, 1]
    available_drops = []

    items.each_with_index do |entry, i|
      next if entry.nil?
      next if entry.respond_to?(:empty?) && entry.empty?

      available_drops.push([entry, weights[i]])
    end

    return if available_drops.empty?

    total_weight = available_drops.sum { |data| data[1] }
    drop_roll = rand(total_weight)

    chosen_entry = nil
    running_weight = 0

    available_drops.each do |entry, weight|
      running_weight += weight

      if drop_roll < running_weight
        chosen_entry = entry
        break
      end
    end

    return if chosen_entry.nil?

    item_sym, qty = parse_drop_entry(chosen_entry)
    return if item_sym.nil? || qty <= 0

    old_qty = $bag.quantity(item_sym)
    $bag.add(item_sym, qty)
    added = $bag.quantity(item_sym) - old_qty
    return if added <= 0

    item_data = GameData::Item.get(item_sym)
    name = (added > 1) ? item_data.portion_name_plural : item_data.portion_name
    pocket = item_data.pocket
    colour_tag = shadowc3tag([103, 159, 224], [16, 79, 150])

    if MealPowers::DEBUG
      puts "========================================"
      puts "ITEM DROP POWER BONUS RESULT"
      puts "Item: #{item_sym}"
      puts "Quantity: #{added}"
      puts "Tier Roll: #{drop_roll}/#{total_weight}"
      puts "========================================"
    end

    @battle.pbDisplay(
      _INTL(
        "{1} dropped an additional {2}{3} x{4}</c3>!",
        pbThis,
        colour_tag,
        name,
        added
      )
    )

    @battle.pbDisplay(
      _INTL(
        "You put the {1} in\nyour Bag's <icon=bagPocket{2}>{3}{4}</c3> pocket.",
        name,
        pocket,
        colour_tag,
        PokemonBag.pocket_names[pocket - 1]
      )
    )
  end
end