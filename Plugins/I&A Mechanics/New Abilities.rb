#===============================================================================
# Rock Body
#===============================================================================

Battle::AbilityEffects::EndOfRoundWeather.add(:ROCKBODY,
  proc { |ability, weather, battler, battle|
    next unless weather == :Sandstorm
    next if !battler.canHeal?
    battle.pbShowAbilitySplash(battler)
    battler.pbRecoverHP(battler.totalhp / 16)
    if Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}'s HP was restored.", battler.pbThis))
    else
      battle.pbDisplay(_INTL("{1}'s {2} restored its HP.", battler.pbThis, battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

#===============================================================================
# Lethal Legs
#===============================================================================

Battle::AbilityEffects::DamageCalcFromUser.add(:LETHALLEGS,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:base_damage_multiplier] *= 1.2 if move.kickingMove?
  }
)

#===============================================================================
# Corruption
#===============================================================================

Battle::AbilityEffects::ModifyMoveBaseType.add(:CORRUPTION,
  proc { |ability, user, move, type|
    next if type != :NORMAL || !GameData::Type.exists?(:DARK)
    move.powerBoost = true
    next :DARK
  }
)

#===============================================================================
# Scaliate
#===============================================================================

Battle::AbilityEffects::ModifyMoveBaseType.add(:SCALIATE,
  proc { |ability, user, move, type|
    next if type != :NORMAL || !GameData::Type.exists?(:DRAGON)
    move.powerBoost = true
    next :DRAGON
  }
)

#===============================================================================
# Vampyre
#===============================================================================

Battle::AbilityEffects::ModifyMoveBaseType.add(:VAMPYRE,
  proc { |ability, user, move, type|
    next if type != :FIRE || !GameData::Type.exists?(:GHOST)
    move.powerBoost = true
    next :GHOST
  }
)

#===============================================================================
# Type-Changing Abilities
#===============================================================================

Battle::AbilityEffects::DamageCalcFromUser.copy(:AERILATE, :PIXILATE, :REFRIGERATE, :GALVANIZE, :NORMALIZE, :CORRUPTION, :SCALIATE, :VAMPYRE)


#===============================================================================
# Ignition
#===============================================================================
Battle::AbilityEffects::PriorityChange.add(:IGNITION,
  proc { |ability, battler, move, pri|
    next pri + 1 if (Settings::MECHANICS_GENERATION <= 6 || battler.hp == battler.totalhp) &&
                    move.type == :FIRE
  }
)

#===============================================================================
# Permafrost
#===============================================================================

Battle::AbilityEffects::StatusCheckNonIgnorable.add(:PERMAFROST,
  proc { |ability, battler, status|
    next false if !battler.isSpecies?(:DRUDDIGON) and !battler.isSpecies?(:RUDDIGOIL)
    next true if status.nil? || status == :FROZEN
  }
)

Battle::AbilityEffects::StatusImmunityNonIgnorable.add(:PERMAFROST,
  proc { |ability, battler, status|
    next true if battler.isSpecies?(:DRUDDIGON) or battler.isSpecies?(:RUDDIGOIL)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:PERMAFROST,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1} is frozen solid!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

#===============================================================================
# Botanist
#===============================================================================

Battle::AbilityEffects::DamageCalcFromUser.add(:BOTANIST,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 1.5 if type == :GRASS
  }
)

#===============================================================================
# Immunity Overides
#===============================================================================

class Battle::Move
  alias :_ia_mechanics_pbCalcTypeModSingle :pbCalcTypeModSingle
	def pbCalcTypeModSingle(moveType, defType, user, target)
	  ret = _ia_mechanics_pbCalcTypeModSingle(moveType, defType, user, target)
	  if Effectiveness.ineffective_type?(moveType, defType)
		# Grounded
		if (user.hasActiveAbility?(:GROUNDED) && moveType == :ELECTRIC) &&
          defType == :GROUND
          ret = Effectiveness::NORMAL_EFFECTIVE_ONE
		end
		if (target.hasActiveAbility?(:GROUNDED) && moveType == :GROUND) &&
		  defType == :FLYING
		  ret = Effectiveness::NORMAL_EFFECTIVE_ONE
		end
		# ------
		# Brittle Iron
		if (target.hasActiveAbility?(:BRITTLEIRON) && moveType == :STEEL)
		  ret = Effectiveness::NORMAL_EFFECTIVE_
		end
	  end
	return ret
	end
end

#===============================================================================
# Mach 5
#===============================================================================
Battle::AbilityEffects::OnDealingHit.add(:MACHFIVE,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    user.pbRaiseStatStageByAbility(:SPEED, 1, user)
  }
)

#===============================================================================
# Smooth Stone
#===============================================================================
Battle::AbilityEffects::DamageCalcFromTarget.add(:SMOOTHSTONE,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:base_damage_multiplier] /= 2 if [:WATER].include?(type)
  }
)

#===============================================================================
# Chipped Stone
#===============================================================================
Battle::AbilityEffects::OnBeingHit.add(:CHIPPEDSTONE,
  proc { |ability, user, target, move, battle|
    # next if !move.pbContactMove?(user)
    next if !move.physicalMove?
    next if user.pbOwnSide.effects[PBEffects::Spikes] >= 2
    battle.pbShowAbilitySplash(target)

    user.pbOwnSide.effects[PBEffects::Spikes] += 1
    # battle.pbAnimation("SPIKES", target, user)
    battle.pbDisplay(_INTL("Spikes were scattered on the ground all around {1}!",
                            target.pbOpposingTeam(true)))
    battle.pbHideAbilitySplash(target)
  }
)

#===============================================================================
# True Wisdom
#===============================================================================
Battle::AbilityEffects::DamageCalcFromUser.add(:TRUEWISDOM,
  proc { |ability, user, target, move, mults, baseDmg, type|
    if Effectiveness.super_effective?(target.damageState.typeMod)
      mults[:final_damage_multiplier] *= 2 if move.soundMove?
    end
  }
)

#===============================================================================
# Form Changing
#===============================================================================
class Battle::Battler
  alias :_ia_mechanics_pbCheckForm :pbCheckForm
    def pbCheckForm(endOfRound = false)
	  _ia_mechanics_pbCheckForm(endOfRound)
	  return if fainted? || @effects[PBEffects::Transform]
	  # Puffed Out
      if isSpecies?(:PUFFONO) && self.ability == :PUFFEDOUT
        if @hp <= @totalhp / 2
          if @form.even?
            @battle.pbShowAbilitySplash(self, true)
            @battle.pbHideAbilitySplash(self)
            pbChangeForm(@form + 1, _INTL("{1} inflated!", pbThis))
          end
        end
      end

	end
end

#===============================================================================
# Empty Soundscape
#===============================================================================
Battle::AbilityEffects::MoveBlocking.add(:EMPTYSOUNDSCAPE,
  proc { |ability, bearer, user, targets, move, battle|
    next move.soundMove?
  }
)

#===============================================================================
# Absolute Zero
# Summons Hail when the Pokémon enters battle. Multiplies the damage of the 
# higher of its Attack or Special Attack by 4/3 when Hail is active.
#===============================================================================

Battle::AbilityEffects::OnSwitchIn.add(:ABSOLUTEZERO,
  proc { |ability, battler, battle, switch_in|
    # Summon Hail when the Pokémon enters battle
    if [:Hail, :Snow].include?(battle.field.weather)
      battle.pbShowAbilitySplash(battler)
      battle.pbDisplay(_INTL("{1} thrives in the hailstorm, plunging its temperatures to zero!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
	else
      battle.pbStartWeatherAbility(:Hail, battler)
      battle.pbDisplay(_INTL("{1} summoned a hailstorm, plunging its temperatures to zero!", battler.pbThis))
    
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:ABSOLUTEZERO,
  proc { |ability, user, target, move, mults, baseDmg, type|
    # Check if Hail is active
    if user.battle.field.weather == :Hail
      # Boost the damage if the move matches the user's higher offensive stat
      if user.attack >= user.spatk && move.physicalMove?
        mults[:attack_multiplier] *= 4 / 3.0
      elsif user.spatk > user.attack && move.specialMove?
        mults[:attack_multiplier] *= 4 / 3.0
      end
    end
  }
)

#===============================================================================
# Muscle Stim
#===============================================================================
Battle::AbilityEffects::MoveImmunity.add(:MUSCLESTIM,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityStatRaisingAbility(user, move, type,
       :ELECTRIC, :ATTACK, 1, show_message)
  }
)