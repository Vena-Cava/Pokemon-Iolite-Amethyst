#===============================================================================
# Absolute Zero
# Summons Snow when the Pokémon enters battle. Multiplies the damage of the 
# higher of its Attack or Special Attack by 4/3 when Snow is active.
#===============================================================================

Battle::AbilityEffects::OnSwitchIn.add(:ABSOLUTEZERO,
  proc { |ability, battler, battle, switch_in|
    # Summon Snow when the Pokémon enters battle
    if [:Hail, :Snow].include?(battle.field.weather)
      battle.pbShowAbilitySplash(battler)
      battle.pbDisplay(_INTL("{1} thrives in the snow, plunging its temperatures to zero!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
	else
      battle.pbStartWeatherAbility(:Hail, battler)
      battle.pbDisplay(_INTL("{1} made it snow, plunging its temperatures to zero!", battler.pbThis))
    
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:ABSOLUTEZERO,
  proc { |ability, user, target, move, mults, baseDmg, type|
    # Check if Snow is active
    if user.battle.field.weather == [:Snow, :Hail]
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
# Bioluminescence
# Double Speed at Night or in a Cave
# Half Speed in Harsh Sunlight
#===============================================================================

Battle::AbilityEffects::SpeedCalc.add(:BIOLUMINESCENCE,
  proc { |ability, battler, mult|
    if battler.effectiveWeather == :HarshSun
      next mult / 2
    elsif battler.battle.time == 2   # Night or cave
      next mult * 2
    end
  }
)

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
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.2 if move.kickingMove?
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
    next if user.pbOwnSide.effects[PBEffects::StealthRock] >= 2
    battle.pbShowAbilitySplash(target)

    user.pbOwnSide.effects[PBEffects::StealthRock] += 1
    # battle.pbAnimation("STEALTHROCK", target, user)
    battle.pbDisplay(_INTL("Floating stones were scattered all around {1}!",
                            target.pbOpposingTeam(true)))
    battle.pbHideAbilitySplash(target)
  }
)

#===============================================================================
# Ton of Bricks
#===============================================================================
Battle::AbilityEffects::OnBeingHit.add(:TONOFBRICKS,
  proc { |ability, user, target, move, battle|
    # next if !move.pbContactMove?(user)
    next if !move.physicalMove?
    next if user.pbOwnSide.effects[PBEffects::ScatteredToys] >= 2
    battle.pbShowAbilitySplash(target)

    user.pbOwnSide.effects[PBEffects::ScatteredToys] += 1
    # battle.pbAnimation("SCATTEREDTOYS", target, user)
    battle.pbDisplay(_INTL("Plastic toys were scattered on the ground all around {1}!",
                            target.pbOpposingTeam(true)))
    battle.pbHideAbilitySplash(target)
  }
)

#===============================================================================
# Glass Splinters
#===============================================================================
Battle::AbilityEffects::OnBeingHit.add(:GLASSSPLINTERS,
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
# Muscle Stim
#===============================================================================
Battle::AbilityEffects::MoveImmunity.add(:MUSCLESTIM,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityStatRaisingAbility(user, move, type,
       :ELECTRIC, :ATTACK, 1, show_message)
  }
)

#===============================================================================
# G-Force
#===============================================================================
Battle::AbilityEffects::OnSwitchIn.add(:GFORCE,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.effects[PBEffects::Gravity] > 0
    battle.pbShowAbilitySplash(battler)
    battle.field.effects[PBEffects::Gravity] = 5
    battle.pbDisplay(_INTL("Gravity intensified!"))
    battle.pbHideAbilitySplash(battler)
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
# Boiling Point
# Water-type damaging moves gain +10% burn chance.
# They also thaw the user and the target.
#===============================================================================

Battle::AbilityEffects::OnDealingHit.add(:BOILINGPOINT,
  proc { |ability, user, target, move, battle|
    next if !move.damagingMove?
    next if move.pbCalcType(user) != :WATER

    showed_splash = false

    # Thaw user
    if user.status == :FROZEN
      battle.pbShowAbilitySplash(user) unless showed_splash
      showed_splash = true
      user.pbCureStatus(false)
      battle.pbDisplay(_INTL("{1}'s Boiling Point thawed it out!", user.pbThis))
    end

    # Thaw target
    if target.status == :FROZEN
      battle.pbShowAbilitySplash(user) unless showed_splash
      showed_splash = true
      target.pbCureStatus(false)
      battle.pbDisplay(_INTL("{1} was thawed by the boiling water!", target.pbThis))
    end

    # Burn chance
    if target.status == :NONE &&
      target.pbCanBurn?(user, false) &&
      battle.pbRandom(100) < 10
      battle.pbShowAbilitySplash(user) unless showed_splash
      showed_splash = true
      target.pbBurn(user, _INTL("{1} was burned by {2}'s Boiling Point!", target.pbThis, user.pbThis(true)))
    end

    battle.pbHideAbilitySplash(user) if showed_splash
  }
)

class Battle::Battler
  alias ia_boilingpoint_pbTryUseMove pbTryUseMove unless method_defined?(:ia_boilingpoint_pbTryUseMove)

  def pbTryUseMove(*args)
    move = args.find { |arg| arg.is_a?(Battle::Move) }

    if self.status == :FROZEN &&
       self.hasActiveAbility?(:BOILINGPOINT) &&
       move &&
       move.damagingMove? &&
       move.pbCalcType(self) == :WATER

      @battle.pbShowAbilitySplash(self)
      self.pbCureStatus(false)
      @battle.pbDisplay(_INTL("{1}'s Boiling Point thawed it out!", self.pbThis))
      @battle.pbHideAbilitySplash(self)
    end

    return ia_boilingpoint_pbTryUseMove(*args)
  end
end

#===============================================================================
# Dirt Ball
# Contact moves deal 50% damage.
# Ground moves power is doubled.
# Immune to Burn.
#===============================================================================

Battle::AbilityEffects::DamageCalcFromTarget.add(:DIRTBALL,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= 2 if move.pbContactMove?(user)
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:DIRTBALL,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 2 if type == :GROUND
  }
)

Battle::AbilityEffects::OnSwitchOut.copy(:WATERVEIL, :DIRTBALL)

Battle::AbilityEffects::StatusImmunity.copy(:WATERVEIL, :DIRTBALL)

Battle::AbilityEffects::StatusCure.copy(:WATERVEIL, :DIRTBALL)


#===============================================================================
# Limit Break
# When one of this Pokémon's moves reaches 0 PP,
# its Attack, Special Attack, and Speed rise to +6
# AFTER the move is used.
#===============================================================================

class Battle::Battler
  attr_accessor :limit_break_pending

  alias ia_limitbreak_pbReducePP pbReducePP unless method_defined?(:ia_limitbreak_pbReducePP)
  def pbReducePP(move)
    old_pp = move.pp
    ret = ia_limitbreak_pbReducePP(move)

    if ret &&
       old_pp > 0 &&
       move.pp == 0 &&
       hasActiveAbility?(:LIMITBREAK)
      self.limit_break_pending = true
    end

    return ret
  end
end

class Battle::Move
  alias ia_limitbreak_pbEndOfMoveUsageEffect pbEndOfMoveUsageEffect unless method_defined?(:ia_limitbreak_pbEndOfMoveUsageEffect)

  def pbEndOfMoveUsageEffect(*args)
    ia_limitbreak_pbEndOfMoveUsageEffect(*args)

    user = args[0]
    return if !user
    return if !user.limit_break_pending

    user.limit_break_pending = false

    stats_to_raise = [:ATTACK, :SPECIAL_ATTACK, :SPEED]
    can_raise = stats_to_raise.any? { |s| user.pbCanRaiseStatStage?(s, user) }
    return if !can_raise

    user.battle.pbShowAbilitySplash(user)
	
	user.battle.pbDisplay(_INTL("{1} went even further beyond!", user.pbThis))

    stats_to_raise.each do |stat|
      next if user.statStageAtMax?(stat)
      user.pbRaiseStatStage(stat, 6 - user.stages[stat], user)
    end

    user.battle.pbHideAbilitySplash(user)
  end
end