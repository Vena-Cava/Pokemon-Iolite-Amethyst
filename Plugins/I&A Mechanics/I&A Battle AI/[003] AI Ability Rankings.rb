#===============================================================================
# I&A Mechanics - AI Ability ranking handlers.
#===============================================================================

#-------------------------------------------------------------------------------
# Type-boosting abilities. Rank only matters if the Pokémon has matching moves.
#-------------------------------------------------------------------------------

[:BOTANIST, :FISHMONGER, :SURTRSWRATH, :TOXICOLOGIST].each do |abil|
  boost_type = {
    :BOTANIST     => :GRASS,
    :FISHMONGER   => :WATER,
    :SURTRSWRATH  => :FIRE,
    :TOXICOLOGIST => :POISON
  }[abil]

  Battle::AI::Handlers::AbilityRanking.add(abil,
    proc { |ability, score, battler, ai|
      next score if battler.has_damaging_move_of_type?(boost_type)
      next 0
    }
  )
end

[:CONTAMINATE, :CORRUPTION].each do |abil|
  Battle::AI::Handlers::AbilityRanking.add(abil,
    proc { |ability, score, battler, ai|
      next score if battler.has_damaging_move_of_type?(:NORMAL)
      next 0
    }
  )
end

#-------------------------------------------------------------------------------
# Weather/field dependent abilities.
#-------------------------------------------------------------------------------

[:ORICHALCUMPULSE, :HADRONENGINE, :ABSOLUTEZERO].each do |abil|
  Battle::AI::Handlers::AbilityRanking.add(abil,
    proc { |ability, score, battler, ai|
      b       = battler.battler
      atk     = b.attack
      spatk   = b.spatk
      weather = b.effectiveWeather
      terrain = b.battle.field.terrain

      condition_met = case ability
                      when :ORICHALCUMPULSE
                        [:Sun, :HarshSun].include?(weather)
                      when :HADRONENGINE
                        terrain == :Electric
                      when :ABSOLUTEZERO
                        [:Snow, :Hail].include?(weather)
                      end

      has_matching_move = battler.check_for_move do |m|
        next false if !m.damagingMove?
        next false if !condition_met
        next true if atk >= spatk && m.physicalMove?
        next true if spatk > atk && m.specialMove?
        next false
      end

      next score if has_matching_move
      next score - 1
    }
  )
end

Battle::AI::Handlers::AbilityRanking.add(:SMOOTHSTONE,
  proc { |ability, score, battler, ai|
    weather = battler.battler.effectiveWeather
    next score if [:Rain, :HeavyRain, :Sandstorm].include?(weather)
    next score - 1
  }
)

Battle::AI::Handlers::AbilityRanking.add(:CATEGORYSIX,
  proc { |ability, score, battler, ai|
    weather = battler.battler.effectiveWeather

    # Sandstorm
    next score + 1 if weather == :Sandstorm

    # Any other weather
    next score if weather != :None

    # No weather
    next score - 1
  }
)

Battle::AI::Handlers::AbilityRanking.add(:BIOLUMINESCENCE,
  proc { |ability, score, battler, ai|
    battle  = battler.battler.battle
    weather = battler.battler.effectiveWeather

    # Penalize in harsh sunlight
    next score - 1 if [:Sun, :HarshSun].include?(weather)

    # Prefer darkness/caves
    next score + 1 if battle.time == 2

    next score
  }
)

#-------------------------------------------------------------------------------
# Move-category dependent abilities.
#-------------------------------------------------------------------------------

[:DUBSTEP, :REVERBERATE].each do |abil|
  Battle::AI::Handlers::AbilityRanking.add(abil,
    proc { |ability, score, battler, ai|
      next score if battler.check_for_move { |m| m.damagingMove? && m.soundMove? }
      next 0
    }
  )
end

Battle::AI::Handlers::AbilityRanking.add(:LETHALLEGS,
  proc { |ability, score, battler, ai|
    next score if battler.check_for_move { |m| m.kickingMove? }
    next 0
  }
)

Battle::AI::Handlers::AbilityRanking.add(:MACHFIVE,
  proc { |ability, score, battler, ai|
    next score if battler.check_for_move { |m| m.contactMove? }
    next 0
  }
)

#-------------------------------------------------------------------------------
# Contact/trigger abilities.
#-------------------------------------------------------------------------------

Battle::AI::Handlers::AbilityRanking.add(:SHOCKINGSTING,
  proc { |ability, score, battler, ai|
    next score
  }
)

Battle::AI::Handlers::AbilityRanking.add(:ELDRITCHSKIN,
  proc { |ability, score, battler, ai|
    next score
  }
)

Battle::AI::Handlers::AbilityRanking.add(:CRACKEDFISTS,
  proc { |ability, score, battler, ai|
    next score if battler.check_for_move { |m| m.contactMove? }
    next score - 1
  }
)

#-------------------------------------------------------------------------------
# Sleep/freeze abilities.
#-------------------------------------------------------------------------------

Battle::AI::Handlers::AbilityRanking.add(:DREAMENGINE,
  proc { |ability, score, battler, ai|
    has_rest = battler.has_move_with_function?("HealUserFullyAndFallAsleep")

    has_stab_move = battler.check_for_move do |m|
      next false if !m.damagingMove?
      next battler.pbTypes(true).include?(m.type)
    end

    next score + 1 if has_rest && has_stab_move
    next score if has_rest
    next score - 1 if has_stab_move
    next score - 2
  }
)

Battle::AI::Handlers::AbilityRanking.add(:CAFFEINERUSH,
  proc { |ability, score, battler, ai|
    next score
  }
)

Battle::AI::Handlers::AbilityRanking.add(:PERMAFROST,
  proc { |ability, score, battler, ai|
    next score
  }
)

#-------------------------------------------------------------------------------
# Item-style abilities.
#-------------------------------------------------------------------------------

Battle::AI::Handlers::AbilityRanking.add(:CHITINOUSSHELL,
  proc { |ability, score, battler, ai|
    weather = battler.battler.effectiveWeather

    next score + 1 if weather == :Sandstorm
    next score
  }
)

Battle::AI::Handlers::AbilityRanking.add(:SEALEDTIGHT,
  proc { |ability, score, battler, ai|
    next score if battler.item
    next score - 1
  }
)

#-------------------------------------------------------------------------------
# Drain/leftovers-style healing abilities.
#-------------------------------------------------------------------------------

Battle::AI::Handlers::AbilityRanking.add(:DERMATOPHAGY,
  proc { |ability, score, battler, ai|
    next score if battler.hp < battler.totalhp
    next score - 1
  }
)

Battle::AI::Handlers::AbilityRanking.add(:PURIFYINGBEAST,
  proc { |ability, score, battler, ai|
    weather = battler.battler.effectiveWeather

    # Best case: healing active
    next score + 1 if [:Rain, :HeavyRain].include?(weather) &&
                       battler.hp < battler.totalhp

    # Rain active
    next score if [:Rain, :HeavyRain].include?(weather)

    # Injured without Rain = strong incentive to establish Rain
    next score - 2 if battler.hp < battler.totalhp

    # Healthy without Rain
    next score - 1
  }
)

#-------------------------------------------------------------------------------
# KO/snowball abilities.
#-------------------------------------------------------------------------------

Battle::AI::Handlers::AbilityRanking.add(:NOURISHINGSOUL,
  proc { |ability, score, battler, ai|
    next score if battler.check_for_move { |m| m.damagingMove? }
    next 0
  }
)

IA_TRIGGER_STAT_ABILITIES = {
  :FORCEOFNATURE => {
    :DRAGON => :ATTACK,
    :GRASS  => :SPECIAL_ATTACK
  },

  :ENGINEOFINDUSTRY => {
    :STEEL    => :ATTACK,
    :ELECTRIC => :SPECIAL_ATTACK
  },

  :GALVANICGLADIATOR => {
    :ELECTRIC => :SPEED,
    :FIGHTING => :ATTACK
  },

  :GUARDIANGLADIATOR => {
    :FIGHTING => :DEFENSE,
    :STEEL    => :SPECIAL_DEFENSE
  },

  :HEARTOFFLAME => {
    :FIRE   => :SPECIAL_ATTACK,
    :DRAGON => :ATTACK
  },

  :NATURESSAVIOR => {
    :GRASS => :SPECIAL_DEFENSE,
    :FAIRY => :SPECIAL_ATTACK
  }
}

IA_TRIGGER_STAT_ABILITIES.each do |ability_id, type_data|
  Battle::AI::Handlers::AbilityRanking.add(ability_id,
    proc { |ability, score, battler, ai|
      triggers = 0
      good_triggers = 0
      multi_triggers = 0

      battler.each_move do |m|
        next if !m.damagingMove?

        move_type = m.type
        next if !type_data[move_type]

        triggers += 1

        boosted_stat = type_data[move_type]

        if boosted_stat == :ATTACK && m.physicalMove?
          good_triggers += 1
        elsif boosted_stat == :SPECIAL_ATTACK && m.specialMove?
          good_triggers += 1
        elsif [:DEFENSE, :SPECIAL_DEFENSE, :SPEED].include?(boosted_stat)
          good_triggers += 1
        end

        multi_triggers += 1 if m.multiHitMove?
      end

	  next score + 2 if multi_triggers >= 1 && good_triggers >= 1
	  next score + 1 if good_triggers >= 2
	  next score if good_triggers >= 1
	  next score - 1 if triggers >= 1
	  next 0
    }
  )
end

#-------------------------------------------------------------------------------
# Hazard abilities.
#-------------------------------------------------------------------------------

[:CHIPPEDSTONE, :GLASSSPLINTERS, :TONOFBRICKS, :GROUNDWIRE].each do |abil|
  Battle::AI::Handlers::AbilityRanking.add(abil,
    proc { |ability, score, battler, ai|
      next score
    }
  )
end