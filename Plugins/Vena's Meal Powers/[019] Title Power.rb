#===============================================================================
# Meal Powers - Title Power
# Gives wild Pokémon additional chances to generate with a Mark.
#
# Lv. 1 = +1 Mark roll
# Lv. 2 = +2 Mark rolls
# Lv. 3 = +3 Mark rolls
#
# These rolls stack with the Mark Charm.
#===============================================================================

module MealPowers
  TITLE_EXTRA_ROLLS = {
    0 => 0,
    1 => 1,
    2 => 2,
    3 => 3
  }

  def self.title_extra_rolls
    return TITLE_EXTRA_ROLLS[level(:TITLE)] || 0
  end
end