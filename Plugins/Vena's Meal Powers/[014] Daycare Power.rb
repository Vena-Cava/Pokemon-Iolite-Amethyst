#===============================================================================
# Meal Powers - Daycare Power
# Makes the Day Care/Nursery generate Eggs more frequently.
#===============================================================================

module MealPowers
  DAYCARE_MULTIPLIER = {
    0 => 1,
    1 => 5,
    2 => 7,
    3 => 10
  }

  def self.daycare_multiplier
    return DAYCARE_MULTIPLIER[level(:DAYCARE)] || 1
  end
end

class DayCare
  #-------------------------------------------------------------------------
  # Performs one normal Egg availability roll without affecting the Day
  # Care's normal step counter, Exp gain or Egg Move sharing.
  #-------------------------------------------------------------------------
  def meal_power_egg_check
    return if @egg_generated
    return if count != 2

    compat = compatibility
    return if compat <= 0

    egg_chance = [0, 20, 50, 70][compat]
    egg_chance = [0, 40, 80, 88][compat] if $bag.has?(:OVALCHARM)

    generated = rand(100) < egg_chance
    @egg_generated = true if generated

    if MealPowers::DEBUG
      puts "========================================"
      puts "DAYCARE POWER EGG CHECK"
      puts "Daycare Power Lv: #{MealPowers.level(:DAYCARE)}"
      puts "Multiplier: x#{MealPowers.daycare_multiplier}"
      puts "Compatibility: #{compat}"
      puts "Oval Charm: #{$bag.has?(:OVALCHARM)}"
      puts "Egg Chance: #{egg_chance}%"
      puts "Egg Generated?: #{generated}"
      puts "========================================"
    end
  end
end

EventHandlers.add(:on_player_step_taken, :meal_power_daycare_power,
  proc {
    level = MealPowers.level(:DAYCARE)
    next if level <= 0
    next if !$PokemonGlobal
    next if !$PokemonGlobal.day_care

    day_care = $PokemonGlobal.day_care

    # No reason to accumulate bonus Egg-generation progress if an Egg is
    # already waiting or if there aren't two deposited Pokémon.
    if day_care.egg_generated || day_care.count != 2
      day_care.instance_variable_set(:@meal_power_daycare_progress, 0)
      next
    end

    multiplier = MealPowers.daycare_multiplier

    # Essentials already supplies x1 generation speed itself.
    # The Meal Power therefore supplies only the additional x4/x6/x9.
    bonus_progress = multiplier - 1

    progress = day_care.instance_variable_get(:@meal_power_daycare_progress) || 0
    progress += bonus_progress

    while progress >= 256
      progress -= 256
      day_care.meal_power_egg_check
      break if day_care.egg_generated
    end

    day_care.instance_variable_set(:@meal_power_daycare_progress, progress)
  }
)