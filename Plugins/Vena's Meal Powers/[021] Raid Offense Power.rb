#===============================================================================
# Raid Offense Power
#===============================================================================
# Increases the effective Attack and Special Attack of the player's raid team
# while attacking a Raid Boss.
#
# Lv. 1: x1.25
# Lv. 2: x1.50
# Lv. 3: x2.00
#
# This does not modify the Pokémon's actual stored stats or stat stages.
# Instead, it applies an Attack multiplier during the raid damage calculation.
#===============================================================================

module MealPowers
  RAID_OFFENSE_MULTIPLIERS = {
    0 => 1.0,
    1 => 1.25,
    2 => 1.50,
    3 => 2.00
  }

  def self.raid_offense_multiplier
    return RAID_OFFENSE_MULTIPLIERS[level(:RAIDOFFENSE)] || 1.0
  end
end


#===============================================================================
# Damage calculation
#===============================================================================
class Battle::Move
  alias meal_powers_raid_offense_pbCalcDamageMults_Other pbCalcDamageMults_Other

  def pbCalcDamageMults_Other(user, target, numTargets, type, baseDmg, multipliers)
    meal_powers_raid_offense_pbCalcDamageMults_Other(
      user,
      target,
      numTargets,
      type,
      baseDmg,
      multipliers
    )

    level = MealPowers.level(:RAIDOFFENSE)
    return if level <= 0

    # Only Pokémon fighting on the player's side receive the bonus.
    return if user.opposes?

    # This also ensures the power only functions during Raid Battles.
    return if !target.isRaidBoss?

    # These moves don't actually use the user's Attack/Sp. Atk, so Raid
    # Offense Power shouldn't strengthen them.
    return if @function_code == "UseUserDefenseInsteadOfUserAttack"
    return if @function_code == "UseTargetAttackInsteadOfUserAttack"

    multiplier = MealPowers.raid_offense_multiplier
    multipliers[:attack_multiplier] *= multiplier

    if MealPowers::DEBUG
      category = specialMove? ? "Special Attack" : "Attack"
      puts "========================================"
      puts "RAID OFFENSE POWER DEBUG"
      puts "User: #{user.name}"
      puts "Move: #{@name}"
      puts "Raid Offense Power Lv: #{level}"
      puts "Affected Stat: #{category}"
      puts "Multiplier: x#{multiplier}"
      puts "========================================"
    end
  end
end