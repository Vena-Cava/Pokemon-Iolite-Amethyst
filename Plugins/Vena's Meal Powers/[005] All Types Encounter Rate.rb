#===============================================================================
# Meal Powers - All Types Encounter/Repel Rate
#===============================================================================

module MealPowers
  ENCOUNTER_ALL_RATE_BONUS = {
    0 => 0.0,
    1 => 0.50,
    2 => 0.75,
    3 => 1.00
  }

  REPEL_ALL_RATE_REDUCTION = {
    0 => 0.0,
    1 => 0.50,
    2 => 0.75,
    3 => 1.00
  }

  def self.all_types_encounter_multiplier
    enc_lv   = level(:ENCOUNTER, :ALL)
    repel_lv = level(:REPEL, :ALL)

    enc_mult   = 1.0 + (ENCOUNTER_ALL_RATE_BONUS[enc_lv] || 0.0)
    repel_mult = 1.0 - (REPEL_ALL_RATE_REDUCTION[repel_lv] || 0.0)

    return enc_mult * repel_mult
  end
end

alias mealpowers_pbBattleOnStepTaken pbBattleOnStepTaken unless defined?(mealpowers_pbBattleOnStepTaken)

def pbBattleOnStepTaken(*args)
  encounters = $PokemonEncounters
  multiplier = MealPowers.all_types_encounter_multiplier

  return mealpowers_pbBattleOnStepTaken(*args) if !encounters || multiplier == 1.0

  step_chances = encounters.instance_variable_get(:@step_chances)
  old_chances = {}

  if step_chances
    step_chances.each do |enc_type, chance|
      old_chances[enc_type] = chance
      step_chances[enc_type] = chance * multiplier
    end
  end

  ret = nil

  begin
    ret = mealpowers_pbBattleOnStepTaken(*args)
  ensure
    old_chances.each do |enc_type, chance|
      step_chances[enc_type] = chance
    end if step_chances
  end

  if MealPowers::DEBUG && ret
    puts "========================================"
    puts "MEAL ALL TYPES ENCOUNTER RATE DEBUG"
    puts "Encounter All Lv: #{MealPowers.level(:ENCOUNTER, :ALL)}"
    puts "Repel All Lv: #{MealPowers.level(:REPEL, :ALL)}"
    puts "Multiplier: x#{multiplier}"
    puts "Old Chances: #{old_chances.inspect}"
    puts "========================================"
  end

  return ret
end