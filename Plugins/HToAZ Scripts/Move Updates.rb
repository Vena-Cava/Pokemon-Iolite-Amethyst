#===============================================================================
# Decreases the user's Defense by 1 stage. Ends target's protections
# immediately. (Hyperspace Fury)
#===============================================================================
class Battle::Move::HoopaRemoveProtectionsBypassSubstituteLowerUserDef1 < Battle::Move::StatDownMove
  def ignoresSubstitute?(user); return true; end

  def initialize(battle, move)
    super
    @statDown = [:DEFENSE, 1]
  end

  def pbMoveFailed?(user, targets)
    if !user.isSpecies?(:HOOPA)
      @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis(true)))
      return true
    elsif user.form != 1
      @battle.pbDisplay(_INTL("But {1} can't use it the way it is now!", user.pbThis(true)))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::BanefulBunker]          = false
    target.effects[PBEffects::BurningBulwark]         = false
    target.effects[PBEffects::KingsShield]            = false
    target.effects[PBEffects::Obstruct]               = false
    target.effects[PBEffects::Protect]                = false
    target.effects[PBEffects::SpikyShield]            = false
    target.pbOwnSide.effects[PBEffects::CraftyShield] = false
    target.pbOwnSide.effects[PBEffects::MatBlock]     = false
    target.pbOwnSide.effects[PBEffects::QuickGuard]   = false
    target.pbOwnSide.effects[PBEffects::WideGuard]    = false
	
  end
end

#===============================================================================
# Ends target's protections immediately. (Feint)
#===============================================================================
class Battle::Move::RemoveProtections < Battle::Move
  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::BanefulBunker]          = false
	target.effects[PBEffects::BurningBulwark]         = false
    target.effects[PBEffects::KingsShield]            = false
    target.effects[PBEffects::Obstruct]               = false
    target.effects[PBEffects::Protect]                = false
    target.effects[PBEffects::SpikyShield]            = false
    target.pbOwnSide.effects[PBEffects::CraftyShield] = false
    target.pbOwnSide.effects[PBEffects::MatBlock]     = false
    target.pbOwnSide.effects[PBEffects::QuickGuard]   = false
    target.pbOwnSide.effects[PBEffects::WideGuard]    = false
  end
end

#===============================================================================
# Two turn attack. Skips first turn, attacks second turn. Is invulnerable during
# use. Ends target's protections upon hit. (Shadow Force, Phantom Force)
#===============================================================================
class Battle::Move::TwoTurnAttackInvulnerableRemoveProtections < Battle::Move::TwoTurnMove
  def pbChargingTurnMessage(user, targets)
    @battle.pbDisplay(_INTL("{1} vanished instantly!", user.pbThis))
  end

  def pbAttackingTurnEffect(user, target)
    target.effects[PBEffects::BanefulBunker]          = false
	target.effects[PBEffects::BurningBulwark]         = false
    target.effects[PBEffects::KingsShield]            = false
    target.effects[PBEffects::Obstruct]               = false
    target.effects[PBEffects::Protect]                = false
    target.effects[PBEffects::SpikyShield]            = false
    target.pbOwnSide.effects[PBEffects::CraftyShield] = false
    target.pbOwnSide.effects[PBEffects::MatBlock]     = false
    target.pbOwnSide.effects[PBEffects::QuickGuard]   = false
    target.pbOwnSide.effects[PBEffects::WideGuard]    = false
  end
end