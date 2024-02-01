#===============================================================================
# Heals the User by 50% damage dealt to Target.
# Burns the target. (Matcha Gotcha)
#===============================================================================
class Battle::Move::HealUserBurnTarget < Battle::Move::HealUserByHalfOfDamageDone
  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
	target.pbBurn(user) if target.pbCanBurn?(user, false, self)
  end
end

#===============================================================================
# Two turn attack. Ups user's Sp.Atk by 1 stage first turn, attacks second turn.
# (Electro Shot) In rain, takes 1 turn instead.
#===============================================================================
class Battle::Move::TwoTurnAttackOneTurnInRainChargeRaiseUserSpAtk1 < Battle::Move::TwoTurnMove
  attr_reader :statUp

  def initialize(battle, move)
    super
    @statUp = [:SPECIAL_ATTACK, 1]
  end
  
  def pbIsChargingTurn?(user)
    ret = super
    if !user.effects[PBEffects::TwoTurnAttack] &&
       [:Rain, :HeavyRain].include?(user.effectiveWeather)
      @powerHerb = false
      @chargingTurn = true
      @damagingTurn = true
      return false
    end
    return ret
  end

  def pbChargingTurnMessage(user, targets)
    @battle.pbDisplay(_INTL("{1} absorbed electricity!", user.pbThis))
  end

  def pbChargingTurnEffect(user, target)
    if user.pbCanRaiseStatStage?(@statUp[0], user, self)
      user.pbRaiseStatStage(@statUp[0], @statUp[1], user)
    end
  end
end

#===============================================================================
# Power is doubled. (Fickle Beam)
#===============================================================================
class Battle::Move::DoublePower < Battle::Move
  def pbBaseDamage(baseDmg, user, target)
    baseDmg *= 2
    return baseDmg
  end
end

#===============================================================================
# User is protected against moves with the "B" flag this round. If a Pokémon
# makes contact with the user while this effect applies, that Pokémon is
# poisoned. (Baneful Bunker)
#===============================================================================
class Battle::Move::ProtectUserBurningBulwark < Battle::Move::ProtectMove
  def initialize(battle, move)
    super
    @effect = PBEffects::BurningBulwark
  end
end

#===============================================================================
# Power increases with the target's HP. (Hard Press)
#===============================================================================
class Battle::Move::PowerHigherWithTargetHPHardPress < Battle::Move
  def pbBaseDamage(baseDmg, user, target)
    return [100 * target.hp / target.totalhp, 1].max
  end
end

#===============================================================================
# Increases ally's critical hit rate. Increases by two if Dragon-Type (Dragon Cheer)
#===============================================================================
class Battle::Move::RaiseAlliesCriticalHitRate2IfDragon < Battle::Move
  def canSnatch?; return true; end

  def pbMoveFailed?(user, targets)
    if target.effects[PBEffects::FocusEnergy] >= 1
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    if target.pbHasType?(:DRAGON)
	  target.effects[PBEffects::FocusEnergy] = 2
	else
	  target.effects[PBEffects::FocusEnergy] = 1
	end
  end
end

#===============================================================================
# For 2 rounds, disables the target's healing moves. Bypasses Substitute. (Psychic Noise)
#===============================================================================
class Battle::Move::DisableTargetHealingMoves < Battle::Move
  def canMagicCoat?; return true; end
  def ignoresSubstitute?(user); return true; end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::HealBlock] = 2
    @battle.pbDisplay(_INTL("{1} was prevented from healing!", target.pbThis))
    target.pbItemStatusCureCheck
  end
end

#===============================================================================
# If attack misses, user takes crash damage of 1/2 of max HP.
# (Supercell Slam)
#===============================================================================
class Battle::Move::CrashDamageIfFails < Battle::Move
  def recoilMove?;        return true; end

  def pbCrashDamage(user)
    return if !user.takesIndirectDamage?
    @battle.pbDisplay(_INTL("{1} kept going and crashed!", user.pbThis))
    @battle.scene.pbDamageAnimation(user)
    user.pbReduceHP(user.totalhp / 2, false)
    user.pbItemHPHealCheck
    user.pbFaint if user.fainted?
  end
end


#===============================================================================
# Causes the target to flinch. Fails if the Target isn't readying a priority move.
# (Upper Hand)
#===============================================================================
class Battle::Move::FlinchTargetFailsIfTargetNotPriority < Battle::Move::FlinchTarget
  def pbMoveFailed?(user, targets)
    if target.pbPriority < 
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end
end