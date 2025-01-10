  def kickingMove?;      return @flags.any? { |f| f[/^Kicking$/i] };            end


#===============================================================================
# This move becomes physical or special, whichever will deal more damage (only
# considers stats, stat stages and Wonder Room). Makes contact if it is a
# physical move. Has a different animation depending on the move's category.
# Will change Type to fit the user's form. (Building Blocks)
#===============================================================================
class Battle::Move::CategoryDependsOnHigherDamageChangeType < Battle::Move
  def initialize(battle, move)
    super
    @calcCategory = 1
  end
  
  def pbBaseType(user)
    ret = :FAIRY
    if user.species == :STACKEMTOL
      case user.form
      when 1 then ret = :FIRE
      when 2 then ret = :ELECTRIC
      when 3 then ret = :GRASS
      when 4 then ret = :WATER
      when 5 then ret = :ROCK
      when 6 then ret = :STEEL
      when 7 then ret = :GROUND
      end
    end
    return ret
  end

  def physicalMove?(thisType = nil); return (@calcCategory == 0); end
  def specialMove?(thisType = nil);  return (@calcCategory == 1); end
  def contactMove?;                  return physicalMove?;        end

  def pbOnStartUse(user, targets)
    target = targets[0]
    stageMul = [2, 2, 2, 2, 2, 2, 2, 3, 4, 5, 6, 7, 8]
    stageDiv = [8, 7, 6, 5, 4, 3, 2, 2, 2, 2, 2, 2, 2]
    # Calculate user's effective attacking values
    attack_stage         = user.stages[:ATTACK] + 6
    real_attack          = (user.attack.to_f * stageMul[attack_stage] / stageDiv[attack_stage]).floor
    special_attack_stage = user.stages[:SPECIAL_ATTACK] + 6
    real_special_attack  = (user.spatk.to_f * stageMul[special_attack_stage] / stageDiv[special_attack_stage]).floor
    # Calculate target's effective defending values
    defense_stage         = target.stages[:DEFENSE] + 6
    real_defense          = (target.defense.to_f * stageMul[defense_stage] / stageDiv[defense_stage]).floor
    special_defense_stage = target.stages[:SPECIAL_DEFENSE] + 6
    real_special_defense  = (target.spdef.to_f * stageMul[special_defense_stage] / stageDiv[special_defense_stage]).floor
    # Perform simple damage calculation
    physical_damage = real_attack.to_f / real_defense
    special_damage = real_special_attack.to_f / real_special_defense
    # Determine move's category
    if physical_damage == special_damage
      @calcCategry = @battle.pbRandom(2)
    else
      @calcCategory = (physical_damage > special_damage) ? 0 : 1
    end
  end

  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    hitNum = 1 if physicalMove?
    super
  end
end

#===============================================================================
# User's side is protected against special moves this round. (Chi Block)
#===============================================================================
class Battle::Move::ProtectUserSideFromSpecialMoves < Battle::Move
  def pbMoveFailed?(user, targets)
    if user.pbOwnSide.effects[PBEffects::ChiBlock]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return true if pbMoveFailedLastInRound?(user)
    return false
  end

  def pbEffectGeneral(user)
    user.pbOwnSide.effects[PBEffects::ChiBlock] = true
    @battle.pbDisplay(_INTL("Chi Blocking protected {1}!", user.pbTeam(true)))
  end
end

#===============================================================================
# Type depends on the user's form. (Raging Bull)
#===============================================================================
class Battle::Move::TypeDependsOnUserForm < Battle::Move::RemoveScreens
  def initialize(battle, move)
    super
    @calcCategory = 0
  end

  def pbBaseType(user)
    ret = :NORMAL
    if user.species == :TAUROS
      case user.form
      when 1 then ret = :FIGHTING
      when 2 then ret = :FIRE
      when 3 then ret = :WATER
      end
    end
    if user.species == :MINITOR
		ret = :FIGHTING
    end
	if user.species == :MONOTAUR
		ret = :DARK
	end
    if user.species == :MANATAUR
		ret = :FAIRY
		@calcCategory = 1
    end
	if user.species == :MAXITAUR
		ret = :DRAGON
		def physicalMove?(thisType = nil); return (@calcCategory == 0); end
		def specialMove?(thisType = nil);  return (@calcCategory == 1); end
		def contactMove?;                  return physicalMove?;        end

		def pbOnStartUse(user, targets)
			target = targets[0]
			stageMul = [2, 2, 2, 2, 2, 2, 2, 3, 4, 5, 6, 7, 8]
			stageDiv = [8, 7, 6, 5, 4, 3, 2, 2, 2, 2, 2, 2, 2]
			# Calculate user's effective attacking values
			attack_stage         = user.stages[:ATTACK] + 6
			real_attack          = (user.attack.to_f * stageMul[attack_stage] / stageDiv[attack_stage]).floor
			special_attack_stage = user.stages[:SPECIAL_ATTACK] + 6
			real_special_attack  = (user.spatk.to_f * stageMul[special_attack_stage] / stageDiv[special_attack_stage]).floor
			# Calculate target's effective defending values
			defense_stage         = target.stages[:DEFENSE] + 6
			real_defense          = (target.defense.to_f * stageMul[defense_stage] / stageDiv[defense_stage]).floor
			special_defense_stage = target.stages[:SPECIAL_DEFENSE] + 6
			real_special_defense  = (target.spdef.to_f * stageMul[special_defense_stage] / stageDiv[special_defense_stage]).floor
			# Perform simple damage calculation
			physical_damage = real_attack.to_f / real_defense
			special_damage = real_special_attack.to_f / real_special_defense
			# Determine move's category
			if physical_damage == special_damage
				@calcCategry = @battle.pbRandom(2)
			else
				@calcCategory = (physical_damage > special_damage) ? 0 : 1
			end
		end
    end
    return ret
	return @calcCategory
  end
end

#===============================================================================
# Type effectiveness is multiplied by the Water-type's effectiveness against
# the target. (Fruit Squash)
#===============================================================================
class Battle::Move::EffectivenessIncludesWaterType < Battle::Move
  def pbCalcTypeModSingle(moveType, defType, user, target)
    ret = super
    if GameData::Type.exists?(:WATER)
      waterEff = Effectiveness.calculate_one(:WATER, defType)
      ret *= waterEff.to_f / Effectiveness::NORMAL_EFFECTIVE_ONE
    end
    return ret
  end
end

#===============================================================================
# Type effectiveness is multiplied by the Fire-type's effectiveness against
# the target. Burns or paralyzes the target. (Plasma Ball)
#===============================================================================
class Battle::Move::EffectivenessIncludesFireType < Battle::Move
  def pbCalcTypeModSingle(moveType, defType, user, target)
    ret = super
    if GameData::Type.exists?(:FIRE)
      fireEff = Effectiveness.calculate_one(:FIRE, defType)
      ret *= fireEff.to_f / Effectiveness::NORMAL_EFFECTIVE_ONE
    end
    return ret
  end
  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    case @battle.pbRandom(2)
    when 0 then target.pbBurn(user) if target.pbCanBurn?(user, false, self)
    when 1 then target.pbParalyze(user) if target.pbCanParalyze?(user, false, self)
    end
  end
end

#===============================================================================
# Effectiveness against Bug-type is 2x. (Prehensile Tongue)
#===============================================================================
class Battle::Move::SuperEffectiveAgainstBug < Battle::Move
  def pbCalcTypeModSingle(moveType, defType, user, target)
    return Effectiveness::SUPER_EFFECTIVE_ONE if defType == :BUG
    return super
  end
end


#===============================================================================
# Cures user of Salt Curing. (Gilded Needle)
#===============================================================================
class Battle::Battler
	def pbCureSaltCure
		@effects[PBEffects::SaltCure] = false
	end
end

class Battle::Move::CureUserSaltCure < Battle::Move
  def canSnatch?; return true; end

  def pbBaseDamage(baseDmg, user, target)
    baseDmg = (baseDmg * 1.5).round if target.pbHasType?(:ROCK)
    return baseDmg
  end

  def pbEffectGeneral(user)
	if user.effects[PBEffects::SaltCure]
		user.pbCureSaltCure
		@battle.pbDisplay(_INTL("{1} cured its Salt Curing!", user.pbThis))
	end
  end
 end

#===============================================================================
# Heals user by 1/2 of its max HP, or 2/3 of its max HP in a hailstorm. (Whiteout)
#===============================================================================
class Battle::Move::HealUserDependingOnHailstorm < Battle::Move::HealingMove
  def pbHealAmount(user)
    return (user.totalhp * 2 / 3.0).round if user.effectiveWeather == :Hail
    return (user.totalhp / 2.0).round
  end
end

#===============================================================================
# Entry hazard. Lays stealth rocks on the opposing side. (Scattered Toys)
#===============================================================================
class Battle::Move::AddStealthRocksToFoeSide < Battle::Move
  def canMagicCoat?; return true; end

  def pbMoveFailed?(user, targets)
    if user.pbOpposingSide.effects[PBEffects::StealthRock]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::StealthRock] = true
    @battle.pbDisplay(_INTL("Pointed stones float in the air around {1}!",
                            user.pbOpposingTeam(true)))
  end
end


#===============================================================================
# Minimizes the target. (Trash Compactor)
#===============================================================================
class Battle::Move::MinimizeTarget < Battle::Move

  def pbEffectGeneral(target)
    target.effects[PBEffects::Minimize] = true
    super
  end
end

#===============================================================================
# Paralyses first turn, skips second turn (Dire Stare).
#===============================================================================
class Battle::Move::ParaAndSkipNextTurn < Battle::Move::ParalyzeTarget

  def pbEffectGeneral(user)
    user.effects[PBEffects::HyperBeam] = 2
    user.currentMove = @id
  end
end

#===============================================================================
# Power is doubled if the target is using Bounce, Fly or Sky Drop. Hits some
# semi-invulnerable targets. May paralyze the target. (Draconic Stormsurge)
#===============================================================================
class Battle::Move::ParaTargetDoublePowerIfTargetInSky < Battle::Move::ParalyzeTarget
  def hitsFlyingTargets?; return true; end

  def pbBaseDamage(baseDmg, user, target)
    baseDmg *= 2 if target.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                                            "TwoTurnAttackInvulnerableInSkyParalyzeTarget",
                                            "TwoTurnAttackInvulnerableInSkyTargetCannotAct") ||
                    target.effects[PBEffects::SkyDrop] >= 0
    return baseDmg
  end
end

#===============================================================================
# Effectiveness against Fairy-type is 0.5x. (Dual Cleave)
#===============================================================================
class Battle::Move::HitTwiceNotEffectiveAgainstFairy < Battle::Move::HitTwoTimes
  def pbCalcTypeModSingle(moveType, defType, user, target)
    return Effectiveness::NOT_VERY_EFFECTIVE_ONE if defType == :FAIRY
    return super
  end
end

#===============================================================================
# Gigaton Hammer
#===============================================================================
# This move becomes unselectable if you try to use it on consecutive turns.
#-------------------------------------------------------------------------------
class Battle::Move::CantSelectConsecutiveTurns < Battle::Move
  def pbEffectWhenDealingDamage(user, target)
    user.effects[PBEffects::SuccessiveMove] = @id
  end
end

#===============================================================================
# Effectiveness against Poison- and Steel-Type is 2x. (Nature's Reclamation)
#===============================================================================
class Battle::Move::SuperEffectiveAgainstPoisonSteel < Battle::Move
  def pbCalcTypeModSingle(moveType, defType, user, target)
    return Effectiveness::SUPER_EFFECTIVE_ONE if defType == :POISON
	return Effectiveness::SUPER_EFFECTIVE_ONE if defType == :STEEL
    return super
  end
end

#===============================================================================
# Effectiveness against Water- and Ground-Type is 2x. (Pollution)
#===============================================================================
class Battle::Move::SuperEffectiveAgainstWaterSteel < Battle::Move
  def pbCalcTypeModSingle(moveType, defType, user, target)
    return Effectiveness::SUPER_EFFECTIVE_ONE if defType == :WATER
	return Effectiveness::SUPER_EFFECTIVE_ONE if defType == :GROUND
    return super
  end
end

#===============================================================================
# Increases the user's Sp. Attack and Speed by 1 stage each. (Quick Thinking)
#===============================================================================
class Battle::Move::RaiseUserSpAtkSpd1 < Battle::Move::MultiStatUpMove
  def initialize(battle, move)
    super
    @statUp = [:SPECIAL_ATTACK, 1, :SPEED, 1]
  end
end

#===============================================================================
# Increases the user's Defense and Special Defense by 2 stages each. Burns the user. (Reforgery)
#===============================================================================
class Battle::Move::RaiseUserDefSpDef2BurnUser < Battle::Move
  def initialize(battle, move)
    super
    @statUp = [:DEFENSE, 2, :SPECIAL_DEFENSE, 2]
  end

  def pbMoveFailed?(user, targets)
    if user.status != :NONE
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    # Raise Defense and Special Defense
    if user.pbCanRaiseStatStage?(:DEFENSE, user)
      user.pbRaiseStatStage(:DEFENSE, 2, user)
    end
    if user.pbCanRaiseStatStage?(:SPECIAL_DEFENSE, user)
      user.pbRaiseStatStage(:SPECIAL_DEFENSE, 2, user)
    end

    # Burn the user
    user.pbBurn(user, _INTL("{1} was burned by the strain of reforging!", user.pbThis))
  end
end

#===============================================================================
# User switches out and the replacement becomes airborne for 5 turns. (Maglev Switch)
#===============================================================================
class Battle::Move::SwitchOutUserAirborne < Battle::Move
  def unusableInGravity?; return true; end
  
  def pbMoveFailed?(user, targets)
    if !@battle.pbCanChooseNonActive?(user.index)
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if user.effects[PBEffects::Ingrain] ||
       user.effects[PBEffects::SmackDown]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    # Set Magnet Rise effect for 5 turns on the replacement Pokémon
    @battle.pbDisplay(_INTL("{1} prepares to switch out while levitating with electromagnetism!", user.pbThis))
    
    # User switches out
    if @battle.pbCanChooseNonActive?(user.index)
      @battle.pbPursuit(user.index)
      return if user.fainted?
      newPkmn = @battle.pbGetReplacementPokemonIndex(user.index)   # Owner chooses
      return if newPkmn < 0
      @battle.pbRecallAndReplace(user.index, newPkmn, false, true)
      @battle.pbClearChoice(user.index)   # Replacement Pokémon does nothing this round
      @battle.moldBreaker = false
      @battle.pbOnBattlerEnteringBattle(user.index)
      
      # Apply Maglev Switch effect to the new Pokémon
      replacement = @battle.battlers[user.index]
      replacement.effects[PBEffects::MaglevSwitch] = 5
      @battle.pbDisplay(_INTL("{1} is now levitating with electromagnetism!", replacement.pbThis))
    end
  end
end