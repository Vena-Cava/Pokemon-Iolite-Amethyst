#===============================================================================
# Meal Powers - Money Power
# Adds bonus money after trainer battle rewards are received.
#===============================================================================

module MealPowers
  MONEY_POWER_MULT = {
    0 => 1.0,
    1 => 1.25,
    2 => 1.50,
    3 => 2.00
  }

  def self.money_multiplier
    return MONEY_POWER_MULT[level(:MONEY)] || 1.0
  end
end

class Battle
  alias mealpowers_pbGainMoney pbGainMoney unless method_defined?(:mealpowers_pbGainMoney)

  def pbGainMoney
    old_money = pbPlayer.money

    ret = mealpowers_pbGainMoney

    level = MealPowers.level(:MONEY)
    mult  = MealPowers.money_multiplier

    return ret if level <= 0
    return ret if mult <= 1.0
    return ret if !trainerBattle?

    gained = pbPlayer.money - old_money
    return ret if gained <= 0

    bonus = (gained * (mult - 1.0)).floor
    return ret if bonus <= 0

    pbPlayer.money += bonus
    $stats.battle_money_gained += bonus

    if MealPowers::DEBUG
      puts "========================================"
      puts "MONEY POWER DEBUG"
      puts "Money Power Lv: #{level}"
      puts "Multiplier: x#{mult}"
      puts "Money Before Battle Reward: #{old_money}"
      puts "Money Gained Normally: #{gained}"
      puts "Bonus Money Added: #{bonus}"
      puts "Final Total Gain: #{gained + bonus}"
      puts "========================================"
    end

    pbDisplayPaused(_INTL("Your Meal Power earned you an extra ${1}!",
                          bonus.to_s_formatted))

    return ret
  end
end