#===============================================================================
# I&A Mechanics - AI Move Rankings
#===============================================================================

module IA_MultiHitAI
  def self.sturdy_sash_bonus(score, target)
    score += 15 if target.has_active_ability?(:STURDY)
    score += 15 if target.item_active? && target.item_id == :FOCUSSASH
    return score
  end
end

#===============================================================================
# Scattered Toys
#===============================================================================
Battle::AI::Handlers::MoveEffectScore.add("AddScatteredToysToFoeSide",
  proc { |score, move, user, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if user.pbOpposingSide.effects[PBEffects::ScatteredToys]
    next score + 20
  }
)

#===============================================================================
# Chi Block
#===============================================================================
Battle::AI::Handlers::MoveEffectScore.add("ProtectUserSideFromSpecialMoves",
  proc { |score, move, user, ai, battle|
    # Discourage repeated Protect-style use
    if user.effects[PBEffects::ProtectRate] > 1
      score -= 30
    end

    # Prefer it against Special attackers
    ai.each_foe_battler(user.side) do |b, i|
      special_count = 0
      b.each_move { |m| special_count += 1 if m.specialMove? }
      score += special_count * 5
    end

    next score
  }
)

#===============================================================================
# Whiteout
#===============================================================================
Battle::AI::Handlers::MoveEffectScore.add("HealUserDependingOnHail",
  proc { |score, move, user, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !user.battler.canHeal?

    hp_ratio = user.hp.to_f / user.totalhp

    # Strong preference at medium-low HP
    if hp_ratio <= 0.5
      score += 25
    elsif hp_ratio <= 0.7
      score += 15
    end

    # Prefer in Snow/Hail because healing is stronger
    if [:Hail, :Snow].include?(user.battler.effectiveWeather)
      score += 15
    end

    # Discourage if critically low HP
    if hp_ratio <= 0.2
      score -= 15
    end

    next score
  }
)

#===============================================================================
# Terra Firma
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("TrapTargetInBattle",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if target.effects[PBEffects::MeanLook] >= 0
    score += 15 if target.faster_than?(user)
    next score + 10
  }
)

#===============================================================================
# Fruit Squash
#===============================================================================
Battle::AI::Handlers::MoveBasePower.add("EffectivenessIncludesWaterType",
  proc { |power, move, user, target, ai, battle|
    if GameData::Type.exists?(:WATER)
      targetTypes = target.pbTypes(true)
      mult = Effectiveness.calculate(:WATER, *targetTypes)
      power = (power * mult).round
    end
    next power
  }
)

#===============================================================================
# Plasma Ball
#===============================================================================
Battle::AI::Handlers::MoveBasePower.add("EffectivenessIncludesFireType",
  proc { |power, move, user, target, ai, battle|
    if GameData::Type.exists?(:FIRE)
      targetTypes = target.pbTypes(true)
      mult = Effectiveness.calculate(:FIRE, *targetTypes)
      power = (power * mult).round
    end
    next power
  }
)

#===============================================================================
# Pollution
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("PoisonTarget",
                                                        "PoisonTargetSuperEffectiveAgainstWaterGround")

#===============================================================================
# Maglev Switch
#===============================================================================
Battle::AI::Handlers::MoveEffectScore.add("SwitchOutUserAirborne",
  proc { |score, move, user, ai, battle|
    ground_pressure = false

    ai.each_foe_battler(user.side) do |b, i|
      b.each_move do |m|
        next if m.type != :GROUND
        next if m.function_code == "HitsTargetInSkyGroundsTarget"
        ground_pressure = true
        break
      end
    end

    # Don't prefer Maglev if there is no avoidable Ground pressure.
    next score - 10 if !ground_pressure

    # Main reason: avoid Ground moves.
    score += 20

    # Small bonus only: avoids grounded hazards.
    score += 5 if user.pbOwnSide.effects[PBEffects::Spikes] > 0
    score += 5 if user.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
    score += 5 if user.pbOwnSide.effects[PBEffects::ScatteredToys]
    score += 5 if user.pbOwnSide.effects[PBEffects::StickyWeb]

    next score
  }
)

#===============================================================================
# Reforgery
#===============================================================================
Battle::AI::Handlers::MoveEffectScore.add("RaiseUserDefSpDef2BurnUser",
  proc { |score, move, user, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if user.status != :NONE

    physical_count = 0
    special_count  = 0

    user.each_move do |m|
      next if !m.damagingMove?
      physical_count += 1 if m.physicalMove?
      special_count  += 1 if m.specialMove?
    end

    # Self-burn synergies
    score += 20 if user.has_active_ability?(:GUTS)
    score += 10 if user.has_active_ability?(:MARVELSCALE)

    # Facade-style synergy
    score += 10 if user.has_move_with_function?("DoublePowerIfUserPoisonedBurnedParalyzed")

    # Burn is bad for mostly physical attackers without Guts/Facade
    if physical_count > special_count &&
       !user.has_active_ability?(:GUTS) &&
       !user.has_move_with_function?("DoublePowerIfUserPoisonedBurnedParalyzed")
      score -= 15
    end

    # Special attackers care less about Burn
    score += 5 if special_count > physical_count

    # Opponent has Hex/Infernal Parade-style punish moves
    ai.each_foe_battler(user.side) do |b, i|
      if b.has_move_with_function?("DoublePowerIfTargetStatusProblem") ||
         b.has_move_with_function?("DoublePowerIfTargetStatusProblemBurnTarget")
        score -= 15
      end
    end

    next score
  }
)

#===============================================================================
# Limit Break support: prefer spending 1 PP move
#===============================================================================
Battle::AI::Handlers::GeneralMoveScore.add(:limit_break_prefer_1pp_move,
  proc { |score, move, user, ai, battle|
    next score if !user.has_active_ability?(:LIMITBREAK)
    next score if move.pp != 1

    score += 30
    score += 10 if user.stages[:ATTACK] < 6
    score += 10 if user.stages[:SPECIAL_ATTACK] < 6
    score += 10 if user.stages[:SPEED] < 6

    next score
  }
)

#===============================================================================
# Gilded Needle
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("CureUserSaltCureBoostAgainstRock",
  proc { |score, move, user, target, ai, battle|
    # Prefer if the user is Salt Cured.
    score += 20 if user.effects[PBEffects::SaltCure]

    # Prefer against Rock-types because the move gets boosted damage.
    score += 10 if target.has_type?(:ROCK)

    next score
  }
)

Battle::AI::Handlers::MoveBasePower.add("CureUserSaltCureBoostAgainstRock",
  proc { |power, move, user, target, ai, battle|
    next (target.has_type?(:ROCK)) ? (power * 1.5).round : power
  }
)

#===============================================================================
# Trash Compactor
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("MinimizeTarget",
  proc { |score, move, user, target, ai, battle|
    # Bonus if target is not already minimized
    score += 15 if !target.effects[PBEffects::Minimize]

    # Bonus if user can exploit minimized targets
    if user.check_for_move { |m| m.tramplesMinimize? }
      score += 15
    end

    next score
  }
)

#===============================================================================
# Dire Stare
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ParaAndSkipNextTurn",
  proc { |score, move, user, target, ai, battle|
    # Add normal paralysis value.
    para_score = Battle::AI::Handlers.apply_move_effect_against_target_score(
      "ParalyzeTarget", 0, move, user, target, ai, battle
    )
    score += para_score if para_score != Battle::AI::MOVE_USELESS_SCORE

    # Recharge drawback.
    score -= 25

    # Recharge is extra dangerous at low HP.
    if ai.trainer.has_skill_flag?("HPAware")
      hp_ratio = user.hp.to_f / user.totalhp
      score -= 20 if hp_ratio <= 0.33
      score -= 10 if hp_ratio <= 0.5
    end

    # Less bad if target is likely to be slowed by paralysis.
    score += 10 if target.faster_than?(user)

    next score
  }
)

#===============================================================================
# Stormsurge
#===============================================================================
Battle::AI::Handlers::MoveBasePower.add("ParaTargetDoublePowerIfTargetInSky",
  proc { |power, move, user, target, ai, battle|
    if target.effects[PBEffects::TwoTurnAttack] &&
       [
         "TwoTurnAttackInvulnerableInSky",
         "TwoTurnAttackInvulnerableInSkyParalyzeTarget",
         "TwoTurnAttackInvulnerableInSkyTargetCannotAct"
       ].include?(GameData::Move.get(target.effects[PBEffects::TwoTurnAttack]).function_code)
      next power * 2
    end

    next power * 2 if target.effects[PBEffects::SkyDrop] >= 0
    next power
  }
)

Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ParaTargetDoublePowerIfTargetInSky",
  proc { |score, move, user, target, ai, battle|
    para_score = Battle::AI::Handlers.apply_move_effect_against_target_score(
      "ParalyzeTarget", 0, move, user, target, ai, battle
    )

    score += para_score if para_score != Battle::AI::MOVE_USELESS_SCORE
    next score
  }
)

#===============================================================================
# Hits twice.
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("HitTwoTimes",
  proc { |score, move, user, target, ai, battle|
    if target.effects[PBEffects::Substitute] > 0 &&
       !move.move.ignoresSubstitute?(user.battler)
      dmg = move.rough_damage
      num_hits = move.move.pbNumHits(user.battler, [target.battler])
      score += 10 if target.effects[PBEffects::Substitute] < dmg * (num_hits - 1) / num_hits
    end

    score = IA_MultiHitAI.sturdy_sash_bonus(score, target)

    next score
  }
)

#===============================================================================
# Hits Three Times, powers up with each hit (Triple Axle)
#===============================================================================
Battle::AI::Handlers::MoveBasePower.add("HitThreeTimesPowersUpWithEachHit",
  proc { |power, move, user, target, ai, battle|
    next power * 6   # Hits do x1, x2, x3 ret in turn, for x6 in total
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("HitThreeTimesPowersUpWithEachHit",
  proc { |score, move, user, target, ai, battle|
    # Prefer if the target has a Substitute and this move can break it before
    # the last hit
    if target.effects[PBEffects::Substitute] > 0 && !move.move.ignoresSubstitute?(user.battler)
      dmg = move.rough_damage
      score += 10 if target.effects[PBEffects::Substitute] < dmg / 2
    end
	
    score = IA_MultiHitAI.sturdy_sash_bonus(score, target)
	
    next score
  }
)

#===============================================================================
# Hits Two to Five times
#===============================================================================
Battle::AI::Handlers::MoveBasePower.add("HitTwoToFiveTimes",
  proc { |power, move, user, target, ai, battle|
    next power * 5 if user.has_active_ability?(:SKILLLINK)
    next power * 31 / 10   # Average damage dealt
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("HitTwoToFiveTimes",
  proc { |score, move, user, target, ai, battle|
    # Prefer if the target has a Substitute and this move can break it before
    # the last/third hit
    if target.effects[PBEffects::Substitute] > 0 && !move.move.ignoresSubstitute?(user.battler)
      dmg = move.rough_damage
      num_hits = (user.has_active_ability?(:SKILLLINK)) ? 5 : 3   # 3 is about average
      score += 10 if target.effects[PBEffects::Substitute] < dmg * (num_hits - 1) / num_hits
    end
	
    score = IA_MultiHitAI.sturdy_sash_bonus(score, target)
	
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("HitOncePerUserTeamMember",
  proc { |move, user, ai, battle|
    will_fail = true
    battle.eachInTeamFromBattlerIndex(user.index) do |pkmn, i|
      next if !pkmn.able? || pkmn.status != :NONE
      will_fail = false
      break
    end
    next will_fail
  }
)
Battle::AI::Handlers::MoveBasePower.add("HitOncePerUserTeamMember",
  proc { |power, move, user, target, ai, battle|
    ret = 0
    battle.eachInTeamFromBattlerIndex(user.index) do |pkmn, _i|
      ret += 5 + (pkmn.baseStats[:ATTACK] / 10) if pkmn.able? && pkmn.status == :NONE
    end
    next ret
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("HitOncePerUserTeamMember",
  proc { |score, move, user, target, ai, battle|
    # Prefer if the target has a Substitute and this move can break it before
    # the last hit
    if target.effects[PBEffects::Substitute] > 0 && !move.move.ignoresSubstitute?(user.battler)
      dmg = move.rough_damage
      num_hits = 0
      battle.eachInTeamFromBattlerIndex(user.index) do |pkmn, _i|
        num_hits += 1 if pkmn.able? && pkmn.status == :NONE
      end
      score += 10 if target.effects[PBEffects::Substitute] < dmg * (num_hits - 1) / num_hits
    end
	
    score = IA_MultiHitAI.sturdy_sash_bonus(score, target)
	
    next score
  }
)

#===============================================================================
# Dual Cleave
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy(
  "HitTwoTimes",
  "HitTwiceNotEffectiveAgainstFairy"
)

Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("HitTwiceNotEffectiveAgainstFairy",
  proc { |score, move, user, target, ai, battle|
    score += 20 if target.has_type?(:FAIRY)
    score += 10 if target.stages[:DEFENSE] > 0
    score += 10 if target.stages[:SPECIAL_DEFENSE] > 0
    score += 15 if target.stages[:EVASION] > 0
    next score
  }
)

#===============================================================================
# Quick Thinking
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.copy("RaiseUserAtkSpAtk1",
                                            "RaiseUserSpAtkSpd1")
Battle::AI::Handlers::MoveEffectScore.copy("RaiseUserAtkSpAtk1",
                                           "RaiseUserSpAtkSpd1")

#===============================================================================
#Malicious Mercy
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("CannotMakeTargetFaint",
														 "CannotMakeTargetFaintFlinchTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("FlinchTarget",
														"CannotMakeTargetFaintFlinchTarget")

#===============================================================================
# Terrain Priority Moves
#===============================================================================
IA_TERRAIN_PRIORITY_MOVES = {
  "HigherPriorityInElectricTerrain" => :Electric,
  "HigherPriorityInPsychicTerrain"  => :Psychic,
  "HigherPriorityInMistyTerrain"    => :Misty
}

IA_TERRAIN_PRIORITY_MOVES.each do |function_code, terrain|
  Battle::AI::Handlers::MoveEffectAgainstTargetScore.add(function_code,
    proc { |score, move, user, target, ai, battle|
      next score if battle.field.terrain != terrain
      next score if !user.battler.affectedByTerrain?

      # Priority is more useful if the target is faster.
      score += 15 if target.faster_than?(user)

      # Bonus if priority may let the user KO first.
      score += 10 if move.rough_damage >= target.hp

      next score
    }
  )
end

#===============================================================================
# IgnorePsychicTerrain AI fix
#===============================================================================
Battle::AI::Handlers::GeneralMoveScore.add(:ignore_psychic_terrain_priority_fix,
  proc { |score, move, user, ai, battle|
    next score if battle.field.terrain != :Psychic
    next score if !user.battler.affectedByTerrain?
    next score if move.rough_priority(user) <= 0
    next score if !move.move.flags.any? { |f| f[/^IgnorePsychicTerrain$/i] }

    # Refund the AI's Psychic Terrain priority penalty.
    score += 10

    next score
  }
)

#===============================================================================
# Choco-lanche
#===============================================================================
Battle::AI::Handlers::MoveEffectScore.copy("LowerUserAtk1",
                                           "AddMoneyGainedFromBattleLowerUserAtk1")

#===============================================================================
# Troll Toll AI
# Makes AI avoid switching / pivot moves if an opposing Pokémon has Troll Toll.
#===============================================================================
module IA_TrollTollAI
  SWITCHING_MOVES = [
    "SwitchOutUserStatusMove",          # Teleport-style
    "SwitchOutUserDamagingMove",        # U-turn / Volt Switch / Flip Turn
    "LowerTargetAtkSpAtk1SwitchOutUser",# Parting Shot
    "SwitchOutUserPassOnEffects",       # Baton Pass
    "UserMakeSubstituteSwitchOut",      # Shed Tail
    "SwitchOutUserAirborne",            # Maglev Switch
    "SwitchOutUserStartHailWeather"     # Chilly Reception-style
  ]

  def self.foe_has_troll_toll?(user, ai)
    ai.each_foe_battler(user.side) do |b, i|
      next true if b && !b.fainted? && b.has_active_ability?(:TROLLTOLL)
    end
    return false
  end
end

# Avoid hard switching.
Battle::AI::Handlers::ShouldNotSwitch.add(:troll_toll,
  proc { |battler, reserves, ai, battle|
    next false if !IA_TrollTollAI.foe_has_troll_toll?(battler, ai)
    next false if battler.effects[PBEffects::PerishSong] == 1   # Emergency case

    PBDebug.log_ai("#{battler.name} doesn't want to switch because of Troll Toll")
    next true
  }
)

# Avoid pivot/switching moves.
IA_TrollTollAI::SWITCHING_MOVES.each do |code|
  Battle::AI::Handlers::MoveEffectScore.add(code,
    proc { |score, move, user, ai, battle|
      next score if !IA_TrollTollAI.foe_has_troll_toll?(user, ai)
      next score + 10 if user.effects[PBEffects::PerishSong] == 1 # Emergency case

      score -= 35
      score -= 15 if user.hp <= user.totalhp / 3

      next score
    }
  )
end