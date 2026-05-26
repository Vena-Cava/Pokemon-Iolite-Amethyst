################################################################################
# 
# Battle::AI class changes.
# 
################################################################################
class Battle::AI
  IA_BASE_ABILITY_RATINGS = {
    10 => [
      :EYESOFODIN
    ],
  
    9 => [
      :ABSOLUTEZERO,
      :FIMBULWINTER
    ],
  
    8 => [
      :DIRTBALL,
      :DREAMENGINE,
      :CONTAMINATE,
      :CORRUPTION,
      :PRECOGNITION,
	  :LIMITBREAK,
	  :TRUEWISDOM
    ],
  
    7 => [
      :FORCEOFNATURE,
      :ENGINEOFINDUSTRY,
      :GALVANICGUARDIAN,
      :GUARDIANGLADIATOR,
      :HEARTOFFLAME,
      :NATURESSAVIOR,
      :GUMMYBODY,
      :RADIOACTIVEDECAY,
      :GFORCE,
      :STEELSTEALER,
      :MUSCLESTIM,
      :THERMALINSULATION,
      :BOTANIST,
      :FISHMONGER,
      :SURTRSWRATH,
      :TOXICOLOGIST,
	  :BRUTALBROADCAST,
	  :CONTROLLEDDEMOLITION,
	  :GALVANICGUARDIAN,
	  :HELIOSPHERE,
	  :STONEHENGE,
	  :STORMBODY,
	  :STORMINGBEAST,
	  :VAMPYRE,
	  :COLDASICE
    ],
  
    6 => [
      :ETERNALFLAME,
      :PURIFYINGLIGHT,
      :PURIFYINGBEAST,
      :SMOOTHSTONE,
      :IGNITION,
      :MIRAGE,
      :CATEGORYSIX,
      :NOURISHINGSOUL,
	  :ARCHANGELSFLIGHT,
	  :COLDASICE,
	  :EMPTYSOUNDSCAPE,
	  :EPIDEMIC,
	  :FIERYPASSION,
	  :GROUNDED,
	  :RINGTOSS
    ],
  
    5 => [
      :MINDVEIL,
      :REVERBERATE,
      :DUBSTEP,
      :BOILINGPOINT,
      :ERUPTINGBEAST,
      :REKINDLEDRAGE,
      :CHIPPEDSTONE,
      :GLASSSPLINTERS,
      :TONOFBRICKS,
      :GROUNDWIRE,
      :SHOCKINGSTING,
      :ELDRITCHSKIN,
      :BULWARK,
      :ROCKBODY,
      :SNOWSTRIFE,
      :FROSTBLIGHT,
	  :DONOEVIL,
	  :EFFECTDISRUPTION,
	  :HEARNOEVIL,
	  :JETLAG,
	  :ODINSMEMORY,
	  :PILEOFCOINS,
	  :RETELLER,
	  :ROCKPASS,
	  :SEENOEVIL,
	  :SPEAKNOEVIL,
	  :TROLLTOLL
    ],
  
    4 => [
      :TOONFORCE,
      :POISONBODY,
      :CRACKEDFISTS,
      :STINGLIKEABEE,
      :FLOATLIKEABUTTERFLY,
      :MACHFIVE,
      :CAFFEINERUSH,
      :CHITINOUSSHELL,
      :BIOLUMINESCENCE,
      :LETHALLEGS
    ],
  
    3 => [
      :MINDOVERMATTER,
      :FROSTEDFRUIT,
      :SOGGY,
      :DERMATOPHAGY,
      :LACHRYMATOR,
      :ODINSTHOUGHT,
      :SEALEDTIGHT,
      :PERMAFROST,
      :PUFFEDIN,
      :PUFFEDOUT,
      :STABILITYROD
    ],
  
    2 => [
      :FERMENTATION,
      :BRITTLEIRON
    ]
  }

  IA_BASE_ITEM_RATINGS = {
    6  => [ :INDIGOROSE, :CRYSTALCORE],
    5  => [:SPECIALSCOOP],
  }

  HP_HEAL_ITEMS[:HEARTYGYRO] = 100
  
  ONE_STAT_RAISE_ITEMS[:LEANGYRO]    = [:ATTACK, 3]
  ONE_STAT_RAISE_ITEMS[:TOUGHGYRO]   = [:DEFENSE, 3]
  ONE_STAT_RAISE_ITEMS[:CHEESYGYRO]  = [:SPECIAL_ATTACK, 3]
  ONE_STAT_RAISE_ITEMS[:SEAFOODGYRO] = [:SPECIAL_DEFENSE, 3]
  ONE_STAT_RAISE_ITEMS[:LOWFATGYRO]  = [:SPEED, 3]
  
  IA_BASE_ABILITY_RATINGS.each_pair do |val, abilities|
    BASE_ABILITY_RATINGS[val] ||= []
    abilities.each { |a| BASE_ABILITY_RATINGS[val].push(a) if !BASE_ABILITY_RATINGS[val].include?(a) }
  end

  IA_BASE_ITEM_RATINGS.each_pair do |val, items|
    BASE_ITEM_RATINGS[val] ||= []
    items.each { |i| BASE_ITEM_RATINGS[val].push(i) if !BASE_ITEM_RATINGS[val].include?(i) }
  end

  ALL_STATUS_CURE_ITEMS.push(:STUFFEDGYRO) if !ALL_STATUS_CURE_ITEMS.include?(:STUFFEDGYRO)

  #===============================================================================
  # AI_ChooseMove
  #===============================================================================
  # Returns whether the move will definitely fail against the target (assuming
  # no battle conditions change between now and using the move).
  #-------------------------------------------------------------------------------
  alias ia_pbPredictMoveFailureAgainstTarget pbPredictMoveFailureAgainstTarget unless method_defined?(:ia_pbPredictMoveFailureAgainstTarget)

  def pbPredictMoveFailureAgainstTarget
    ret = ia_pbPredictMoveFailureAgainstTarget

    if !ret
      # Immunity because of Mind Veil
      if @move.rough_priority(@user) > 0 && @target.opposes?(@user)
        each_same_side_battler(@target.side) do |b, i|
          return true if b.has_active_ability?(:MINDVEIL)
        end
      end

      # Immunity because of Bookmark
      return true if @target.has_active_ability?(:BOOKMARK) &&
                     @target.battler.isBookmark?
    end

    return ret
  end
  
end

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

class Battle::AI::AIBattler
  alias ia_effectiveness_of_type_against_battler effectiveness_of_type_against_battler

  def effectiveness_of_type_against_battler(type, user = nil, move = nil)
    ret = ia_effectiveness_of_type_against_battler(type, user, move)

    return ret if !move

    pbTypes(true).each do |defend_type|
      case move.function_code
      when "PoisonTargetSuperEffectiveAgainstWaterGround"
        ret *= 2 if [:WATER, :GROUND].include?(defend_type)
      when "SuperEffectiveAgainstPoisonSteel"
        ret *= 2 if [:POISON, :STEEL].include?(defend_type)
      when "SuperEffectiveAgainstBug"
        ret *= 2 if defend_type == :BUG
      end
    end

    return ret
  end
end