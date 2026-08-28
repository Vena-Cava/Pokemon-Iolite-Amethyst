#===============================================================================
# Meal Powers - Friendship Power
# Boosts friendship gain and wild Pokémon starting friendship.
#===============================================================================

module MealPowers
  FRIENDSHIP_POWER_MULT = {
    0 => 1.0,
    1 => 1.1,
    2 => 1.3,
    3 => 1.5
  }

  def self.friendship_multiplier
    return FRIENDSHIP_POWER_MULT[level(:FRIENDSHIP)] || 1.0
  end
end

#===============================================================================
# Wild Pokémon starting friendship
#===============================================================================

EventHandlers.add(:on_wild_pokemon_created, :meal_power_friendship_starting_value,
  proc { |pkmn|
    next if !pkmn
    next if pkmn.egg?

    level = MealPowers.level(:FRIENDSHIP)
    mult  = MealPowers.friendship_multiplier
    next if level <= 0 || mult == 1.0

    old_happiness = pkmn.happiness
    new_happiness = (old_happiness * mult).floor
    new_happiness = [[new_happiness, 0].max, 255].min
    pkmn.happiness = new_happiness

    if MealPowers::DEBUG
      puts "========================================"
      puts "FRIENDSHIP POWER DEBUG - WILD START"
      puts "Pokémon: #{pkmn.name}"
      puts "Friendship Power Lv: #{level}"
      puts "Multiplier: x#{mult}"
      puts "Old Happiness: #{old_happiness}"
      puts "New Happiness: #{new_happiness}"
      puts "========================================"
    end
  }
)

#===============================================================================
# Friendship gain
#===============================================================================

class Pokemon
  alias mealpowers_changeHappiness changeHappiness unless method_defined?(:mealpowers_changeHappiness)

  def changeHappiness(method, *args)
    old_happiness = self.happiness
    ret = mealpowers_changeHappiness(method, *args)

    level = MealPowers.level(:FRIENDSHIP)
    return ret if level <= 0
    return ret if self.happiness <= old_happiness

    gained = self.happiness - old_happiness
    bonus = level
    self.happiness = [self.happiness + bonus, 255].min

    if MealPowers::DEBUG
      puts "========================================"
      puts "FRIENDSHIP POWER DEBUG - GAIN"
      puts "Pokémon: #{self.name}"
      puts "Method: #{method}"
      puts "Friendship Power Lv: #{level}"
      puts "Base Gain: #{gained}"
      puts "Bonus Gain: +#{bonus}"
      puts "Final Happiness: #{self.happiness}"
      puts "========================================"
    end

    return ret
  end
end