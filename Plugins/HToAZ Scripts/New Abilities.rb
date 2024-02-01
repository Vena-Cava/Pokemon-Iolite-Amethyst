#===============================================================================
# Mind's Eye
#===============================================================================
Battle::AbilityEffects::AccuracyCalcFromUser.add(:MINDSEYE,
  proc { |ability, mods, user, target, move, type|
    mods[:evasion_stage] = 0
  }
)

#===============================================================================
# Toxic Chain
#===============================================================================
Battle::AbilityEffects::OnDealingHit.add(:TOXICCHAIN,
  proc { |ability, user, target, move, battle|
#	next if !move.contactMove?
    next if battle.pbRandom(100) >= 30
    battle.pbShowAbilitySplash(user)
    if target.hasActiveAbility?(:SHIELDDUST) && !battle.moldBreaker
      battle.pbShowAbilitySplash(target)
      if !Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1} is unaffected!", target.pbThis))
      end
      battle.pbHideAbilitySplash(target)
    elsif target.pbCanPoison?(user, Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("{1}'s {2} poisoned {3}!", user.pbThis, user.abilityName, target.pbThis(true))
      end
      target.pbPoison(user, msg)
    end
    battle.pbHideAbilitySplash(user)
  }
)

