################################################################################
#
# Moves that start effects on one side.
#
################################################################################

#===============================================================================
# G-Max Mammolanche
#===============================================================================
# Starts the Leech Seed effect on the opposing side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::StartMammolancheOnFoeSide < Battle::DynamaxMove::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.effects[PBEffects::LeechSeed] >= 0
      @battle.pbDisplay(_INTL("{1} evaded the attack!", target.pbThis)) if show_message
      return true
    end
    return false
  end

  def pbMissMessage(user, target)
    @battle.pbDisplay(_INTL("{1} evaded the attack!", target.pbThis))
    return true
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::LeechSeed] = user.index
    @battle.pbDisplay(_INTL("{1} was seeded!", target.pbThis))
  end
end

#===============================================================================
# G-Max Searing Skies
#===============================================================================
# Burns the opposing side, even if they are Fire-Type.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::BurnFoeSideIgnoreImmunity < Battle::DynamaxMove::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    return !target.pbCanBurn?(user, show_message, self)
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbBurn(user)
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    target.pbBurn(user) if target.pbCanBurn?(user, false, self)
	return true if !target.pbHasType?(:FIRE)
  end
end

#===============================================================================
# G-Max Kraken's Call
#===============================================================================
# Starts the Leech Seed effect on the opposing side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::StartKrakensCallOnFoeSide < Battle::DynamaxMove::Move
  def pbEffectAgainstTarget(user, target)
    return if target.fainted? || target.damageState.substitute
    return if target.effects[PBEffects::Trapping] > 0
    # Set trapping effect duration and info
    if user.hasActiveItem?(:GRIPCLAW)
      target.effects[PBEffects::Trapping] = (Settings::MECHANICS_GENERATION >= 5) ? 8 : 6
    else
      target.effects[PBEffects::Trapping] = 5 + @battle.pbRandom(2)
    end
    target.effects[PBEffects::TrappingMove] = @id
    target.effects[PBEffects::TrappingUser] = user.index
    # Message
	msg = _INTL("{1} was trapped in the Kraken's grip!", target.pbThis)
    @battle.pbDisplay(msg)
  end
end


