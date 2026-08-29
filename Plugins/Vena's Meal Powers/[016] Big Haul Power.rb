#===============================================================================
# Meal Powers - Big Haul Power
# Gives Random Item Loot Tables a chance to award one additional item.
#===============================================================================

module MealPowers
  BIG_HAUL_CHANCE = {
    0 => 0,
    1 => 25,
    2 => 50,
    3 => 100
  }

  def self.big_haul_chance
    return BIG_HAUL_CHANCE[level(:BIGHAUL)] || 0
  end
end