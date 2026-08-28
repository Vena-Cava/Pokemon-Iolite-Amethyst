#===============================================================================
# Meal Powers - Hatching Power
# Stacks with Flame Body/Magma Armor/Steam Engine via FasterEggHatching flag.
#===============================================================================

module MealPowers
  HATCHING_POWER_REDUCTION = {
    0 => 0.0,
    1 => 0.10,
    2 => 0.25,
    3 => 0.50
  }

  def self.hatching_reduction
    return HATCHING_POWER_REDUCTION[level(:HATCHING)] || 0.0
  end

  def self.party_has_faster_egg_hatching?
    return false if !$player || !$player.party
    $player.party.any? do |pkmn|
      next false if !pkmn || pkmn.egg?
      ability = pkmn.ability_id
      next false if !ability
      GameData::Ability.get(ability).has_flag?("FasterEggHatching") rescue false
    end
  end

  def self.extra_hatch_progress_per_step
    reduction = hatching_reduction
    return 0.0 if reduction <= 0.0

    base_step_power = party_has_faster_egg_hatching? ? 2.0 : 1.0

    # Convert "fewer required steps" into the equivalent speed multiplier:
    # Lv. 1: -10% steps -> x1.111...
    # Lv. 2: -25% steps -> x1.333...
    # Lv. 3: -50% steps -> x2.0
    total_speed_mult = 1.0 / (1.0 - reduction)

    return base_step_power * (total_speed_mult - 1.0)
  end
end

EventHandlers.add(:on_player_step_taken, :meal_power_hatching_power,
  proc {
    next if MealPowers.level(:HATCHING) <= 0

    extra_progress = MealPowers.extra_hatch_progress_per_step

    $player.party.each do |pkmn|
      next if !pkmn
      next if !pkmn.egg?
      next if pkmn.steps_to_hatch <= 0

      # Preserve fractional hatch progress between steps so reductions such as
      # 10% and 25% remain accurate despite steps_to_hatch being an integer.
      progress = pkmn.instance_variable_get(:@meal_power_hatch_progress) || 0.0
      progress += extra_progress

      # Small epsilon prevents values such as 0.9999999999999999 from missing
      # a whole hatch step due to floating-point precision.
      extra_steps = (progress + 0.0000001).floor
      progress -= extra_steps
      progress = 0.0 if progress.abs < 0.0000001

      pkmn.instance_variable_set(:@meal_power_hatch_progress, progress)

      hatched_by_meal_power = false

      if extra_steps > 0
        pkmn.steps_to_hatch -= extra_steps

        if pkmn.steps_to_hatch <= 0
          pkmn.steps_to_hatch = 0
          hatched_by_meal_power = true
        end
      end

      # Essentials' own hatch handler runs before this one. If the Meal Power
      # supplies the final hatch progress, trigger the normal hatch sequence now
      # so the Egg cannot become stuck at 0 steps.
      pbHatch(pkmn) if hatched_by_meal_power
    end
  }
)