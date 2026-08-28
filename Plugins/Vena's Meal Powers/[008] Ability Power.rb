#===============================================================================
# Meal Powers - Ability Power
# Adds a flat Hidden Ability chance to wild Pokémon.
#===============================================================================

module MealPowers
  ABILITY_POWER_BONUS = {
    0 => 0,
    1 => 10,
    2 => 25,
    3 => 50
  }

  def self.ability_power_bonus
    return ABILITY_POWER_BONUS[level(:ABILITY)] || 0
  end
end

EventHandlers.add(:on_wild_pokemon_created, :meal_power_ability_power,
  proc { |pkmn|
    next if !pkmn
    next if pkmn.egg?
    next if pkmn.hasHiddenAbility?

    bonus = MealPowers.ability_power_bonus
    next if bonus <= 0

    hidden_abilities = pkmn.species_data.hidden_abilities
    next if !hidden_abilities || hidden_abilities.empty?

    roll = rand(100)

    if MealPowers::DEBUG
      puts "========================================"
      puts "ABILITY POWER DEBUG"
      puts "Pokémon: #{pkmn.name}"
      puts "Species: #{pkmn.species}"
      puts "Ability Power Lv: #{MealPowers.level(:ABILITY)}"
      puts "Hidden Ability Bonus Chance: #{bonus}%"
      puts "Roll: #{roll}"
      puts "Hidden Abilities: #{hidden_abilities.inspect}"
      puts "Original Ability Index: #{pkmn.ability_index}"
      puts "Original Ability: #{pkmn.ability_id}"
      puts "========================================"
    end

    next if roll >= bonus

    valid_hidden_indices = []
    hidden_abilities.each_with_index do |ability, i|
      valid_hidden_indices.push(i + 2) if ability
    end

    next if valid_hidden_indices.empty?

    pkmn.ability_index = valid_hidden_indices.sample

    if MealPowers::DEBUG
      puts "========================================"
      puts "ABILITY POWER SUCCESS"
      puts "Pokémon: #{pkmn.name}"
      puts "New Ability Index: #{pkmn.ability_index}"
      puts "New Ability: #{pkmn.ability_id}"
      puts "========================================"
    end
  }
)