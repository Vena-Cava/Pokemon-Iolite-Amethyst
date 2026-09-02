#===============================================================================
# Meal Powers - Sparkling Power
# Gives matching wild Pokémon additional chances to be Shiny.
#
# Lv. 1 = +1 Shiny roll
# Lv. 2 = +2 Shiny rolls
# Lv. 3 = +3 Shiny rolls
#
# These rolls occur after Essentials' normal Shiny rolls, so they stack with
# effects such as the Shiny Charm and higher Shiny chances from battled count.
#===============================================================================

module MealPowers
  SPARKLING_EXTRA_ROLLS = {
    0 => 0,
    1 => 1,
    2 => 2,
    3 => 3
  }

  #-----------------------------------------------------------------------------
  # Returns the currently active Sparkling Power data.
  #-----------------------------------------------------------------------------
  def self.sparkling_power
    return active.find { |p| p[:id] == :SPARKLING }
  end

  #-----------------------------------------------------------------------------
  # Returns whether Sparkling Power applies to this Pokémon's type.
  #-----------------------------------------------------------------------------
  def self.sparkling_type_matches?(pkmn)
    power = sparkling_power
    return false if !power
    return false if !pkmn

    type = power[:option]
    return true if type == :ALL

    return pkmn.species_data.types.include?(type)
  end

  #-----------------------------------------------------------------------------
  # Returns the number of additional Shiny rolls for this Pokémon.
  #-----------------------------------------------------------------------------
  def self.sparkling_extra_rolls(pkmn)
    return 0 if !sparkling_type_matches?(pkmn)

    power = sparkling_power
    return 0 if !power

    return SPARKLING_EXTRA_ROLLS[power[:level]] || 0
  end
end

#===============================================================================
# Apply Sparkling Power after Essentials has completed its normal wild Pokémon
# generation, including Shiny Charm and battled-count Shiny retries.
#===============================================================================

EventHandlers.add(:on_wild_pokemon_created, :meal_power_sparkling_power,
  proc { |pkmn|
    power = MealPowers.sparkling_power
    next if !power
    next if !MealPowers.sparkling_type_matches?(pkmn)

    extra_rolls = MealPowers.sparkling_extra_rolls(pkmn)
    next if extra_rolls <= 0

    # By this point, Essentials has already completed all of its normal Shiny
    # rolls. If one of those succeeded, Sparkling Power doesn't need to reroll.
    already_shiny = pkmn.shiny?

    rolls_used = 0
    roll_results = []

    if !already_shiny
      extra_rolls.times do
        # Give the Pokémon a new Personal ID, exactly like Essentials does for
        # its existing Shiny retry system.
        pkmn.shiny = nil
        pkmn.personalID = rand(2**16) | (rand(2**16) << 16)

        rolls_used += 1
        shiny_result = pkmn.shiny?
        roll_results.push(shiny_result)

        # Once a roll succeeds, there is no reason to keep rerolling.
        break if shiny_result
      end
    end

    if MealPowers::DEBUG
      puts "========================================"
      puts "SPARKLING POWER DEBUG"
      puts "Pokémon: #{pkmn.name}"
      puts "Species: #{pkmn.species}"
      puts "Types: #{pkmn.species_data.types.inspect}"
      puts "Selected Type: #{power[:option]}"
      puts "Sparkling Power Lv: #{power[:level]}"
      puts "Additional Shiny Rolls: #{extra_rolls}"
      puts "Already Shiny Before Sparkling?: #{already_shiny}"
      puts "Sparkling Rolls Used: #{rolls_used}"

      roll_results.each_with_index do |result, i|
        puts "Sparkling Roll #{i + 1} Shiny?: #{result}"
      end

      puts "Final Shiny?: #{pkmn.shiny?}"
      puts "========================================"
    end
  }
)