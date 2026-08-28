#===============================================================================
# Meal Powers - Luck Power
# Raises the rarity tier chosen by Random Item Loot Tables.
# Stacks with boosting abilities such as Super Luck.
#===============================================================================

module MealPowers
  LUCK_RARITY_BOOST = {
    0 => 0,
    1 => 1,
    2 => 2,
    3 => 3
  }

  def self.luck_rarity_boost
    return LUCK_RARITY_BOOST[level(:LUCK)] || 0
  end
end