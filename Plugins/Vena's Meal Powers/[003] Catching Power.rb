#===============================================================================
# Meal Powers - Catching Power
#===============================================================================

module MealPowers
  CATCHING_POWER_MULT = {
    0 => 1.0,
    1 => 1.1,
    2 => 1.25,
    3 => 2.0
  }

  def self.catching_multiplier
    return CATCHING_POWER_MULT[level(:CATCHING)] || 1.0
  end
end

module MealPowers_CatchingPower
  def pbCaptureCalc(pkmn, battler, catch_rate, ball)
    level = MealPowers.level(:CATCHING)
    mult  = MealPowers.catching_multiplier

    if level > 0
      catch_rate = pkmn.species_data.catch_rate if !catch_rate

      old_rate = catch_rate
      meal_rate = (catch_rate * mult).floor

      if catch_rate > 0
        meal_rate = [meal_rate, 1].max
      end
      meal_rate = 1 if meal_rate < 1

      ball_rate = meal_rate
      ball_mult = 1.0

      if !pkmn.species_data.has_flag?("UltraBeast") || ball == :BEASTBALL
        ball_rate = Battle::PokeBallEffects.modifyCatchRate(ball, meal_rate, self, battler)
      else
        ball_rate = meal_rate / 10.0
      end

      ball_mult = ball_rate.to_f / meal_rate.to_f if meal_rate > 0

      if MealPowers::DEBUG
        puts "========================================"
        puts "CATCHING POWER DEBUG"
        puts "Pokémon: #{pkmn.name}"
        puts "Ball: #{ball}"
        puts "Catching Power Lv: #{level}"
        puts "Meal Multiplier: x#{mult}"
        puts "Ball Multiplier: x#{ball_mult.round(3)}"
        puts "Base Catch Rate: #{old_rate}"
        puts "After Meal Power: #{meal_rate}"
        puts "After Poké Ball: #{ball_rate}"
        puts "========================================"
      end

      catch_rate = meal_rate
    end

    return super(pkmn, battler, catch_rate, ball)
  end
end

class Battle
  prepend MealPowers_CatchingPower
end