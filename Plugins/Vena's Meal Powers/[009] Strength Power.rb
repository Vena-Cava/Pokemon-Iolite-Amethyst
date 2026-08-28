#===============================================================================
# Meal Powers - Strength Power
# Rerolls low wild Pokémon IVs within a higher range.
#===============================================================================

module MealPowers
  STRENGTH_POWER_MIN_IV = {
    0 => nil,
    1 => 15,
    2 => 20,
    3 => 25
  }

  IV_STATS = [
    :HP,
    :ATTACK,
    :DEFENSE,
    :SPECIAL_ATTACK,
    :SPECIAL_DEFENSE,
    :SPEED
  ]

  def self.strength_min_iv_for(stat)
    all_level  = level(:STRENGTH, :ALL)
    stat_level = level(:STRENGTH, stat)
    best_level = [all_level, stat_level].max
    return STRENGTH_POWER_MIN_IV[best_level]
  end

  def self.active_strength_power?
    IV_STATS.any? { |stat| !strength_min_iv_for(stat).nil? }
  end
end

EventHandlers.add(:on_wild_pokemon_created, :meal_power_strength_power,
  proc { |pkmn|
    next if !pkmn
    next if pkmn.egg?
    next if !MealPowers.active_strength_power?

    old_ivs = {}
    new_ivs = {}
    changed = {}

    MealPowers::IV_STATS.each do |stat|
      old_ivs[stat] = pkmn.iv[stat]

      min_iv = MealPowers.strength_min_iv_for(stat)
      next if !min_iv

      if pkmn.iv[stat] < min_iv
        pkmn.iv[stat] = rand(min_iv..31)
        changed[stat] = pkmn.iv[stat]
      end

      new_ivs[stat] = pkmn.iv[stat]
    end

    if MealPowers::DEBUG
      puts "========================================"
      puts "STRENGTH POWER DEBUG"
      puts "Pokémon: #{pkmn.name}"
      puts "Species: #{pkmn.species}"
      puts "Active Meal Powers: #{MealPowers.active.inspect}"
      puts "Old IVs: #{old_ivs.inspect}"
      puts "Changed IVs: #{changed.inspect}"
      puts "New IVs: #{new_ivs.inspect}"
      puts "========================================"
    end
  }
)