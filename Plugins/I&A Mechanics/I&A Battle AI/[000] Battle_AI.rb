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
<<<<<<< Updated upstream
      :PRECOGNITION,
	  :LIMITBREAK,
	  :TRUEWISDOM
=======
      :PRECOGNITION
>>>>>>> Stashed changes
    ],
  
    7 => [
      :FORCEOFNATURE,
      :ENGINEOFINDUSTRY,
<<<<<<< Updated upstream
      :GALVANICGUARDIAN,
      :GUARDIANGLADIATOR,
      :HEARTOFFLAME,
      :NATURESSAVIOR,
=======
      :GALVANICGLADIATOR,
      :GUARDIANGLADIATOR,
      :HEARTOFFLAME,
      :NATURESSAVIOR,
  
>>>>>>> Stashed changes
      :GUMMYBODY,
      :RADIOACTIVEDECAY,
      :GFORCE,
      :STEELSTEALER,
      :MUSCLESTIM,
      :THERMALINSULATION,
<<<<<<< Updated upstream
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
=======
  
      :BOTANIST,
      :FISHMONGER,
      :SURTRSWRATH,
      :TOXICOLOGIST
>>>>>>> Stashed changes
    ],
  
    6 => [
      :ETERNALFLAME,
      :PURIFYINGLIGHT,
      :PURIFYINGBEAST,
      :SMOOTHSTONE,
      :IGNITION,
      :MIRAGE,
      :CATEGORYSIX,
<<<<<<< Updated upstream
      :NOURISHINGSOUL,
	  :ARCHANGELSFLIGHT,
	  :COLDASICE,
	  :EMPTYSOUNDSCAPE,
	  :EPIDEMIC,
	  :FIERYPASSION,
	  :GROUNDED,
	  :RINGTOSS
=======
      :NOURISHINGSOUL
>>>>>>> Stashed changes
    ],
  
    5 => [
      :MINDVEIL,
      :REVERBERATE,
      :DUBSTEP,
<<<<<<< Updated upstream
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
=======
  
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
      :FROSTBLIGHT
>>>>>>> Stashed changes
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
  
<<<<<<< Updated upstream
=======
  IA_ALL_STATUS_CURE_ITEMS = [
    :STUFFEDGYRO
  ]
  
>>>>>>> Stashed changes
  ONE_STAT_RAISE_ITEMS[:LEANGYRO]    = [:ATTACK, 3]
  ONE_STAT_RAISE_ITEMS[:TOUGHGYRO]   = [:DEFENSE, 3]
  ONE_STAT_RAISE_ITEMS[:CHEESYGYRO]  = [:SPECIAL_ATTACK, 3]
  ONE_STAT_RAISE_ITEMS[:SEAFOODGYRO] = [:SPECIAL_DEFENSE, 3]
  ONE_STAT_RAISE_ITEMS[:LOWFATGYRO]  = [:SPEED, 3]
  
<<<<<<< Updated upstream
  IA_BASE_ABILITY_RATINGS.each_pair do |val, abilities|
    BASE_ABILITY_RATINGS[val] ||= []
    abilities.each { |a| BASE_ABILITY_RATINGS[val].push(a) if !BASE_ABILITY_RATINGS[val].include?(a) }
  end

  IA_BASE_ITEM_RATINGS.each_pair do |val, items|
    BASE_ITEM_RATINGS[val] ||= []
    items.each { |i| BASE_ITEM_RATINGS[val].push(i) if !BASE_ITEM_RATINGS[val].include?(i) }
  end

  ALL_STATUS_CURE_ITEMS.push(:STUFFEDGYRO) if !ALL_STATUS_CURE_ITEMS.include?(:STUFFEDGYRO)
=======
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
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
=======
################################################################################
# 
# Battle::AI::AIBattler class changes.
# 
################################################################################
class Battle::AI::AIBattler
  # Added IA base item ratings
  alias ioam_wants_item? wants_item?
  def wants_item?(item)
    Battle::AI::IA_BASE_ITEM_RATINGS.each_pair do |val, items|
      next if Battle::AI::BASE_ITEM_RATINGS[val] && Battle::AI::BASE_ITEM_RATINGS[val].include?(item)
      Battle::AI::BASE_ITEM_RATINGS[val] = [] if !Battle::AI::BASE_ITEM_RATINGS[val]
      items.each{|itm|
        Battle::AI::BASE_ITEM_RATINGS[val].push(itm)
      }
    end
    return ioam_wants_item?(item)
  end
  
  # Added IA all status cure item ratings
  alias ioam_wants_all_status_cure_item? wants_item?
  def wants_item?(item)
    Battle::AI::IA_ALL_STATUS_CURE_ITEMS.each_pair do |val, items|
      next if Battle::AI::ALL_STATUS_CURE_ITEMS[val] && Battle::AI::ALL_STATUS_CURE_ITEMS[val].include?(item)
      Battle::AI::ALL_STATUS_CURE_ITEMS[val] = [] if !Battle::AI::ALL_STATUS_CURE_ITEMS[val]
      items.each{|itm|
        Battle::AI::ALL_STATUS_CURE_ITEMS[val].push(itm)
      }
    end
    return ioam_wants_all_status_cure_item?(item)
  end

  # Added IA base ability ratings
  alias ioam_wants_ability? wants_ability?
  def wants_ability?(ability = :NONE)
    Battle::AI::IA_BASE_ABILITY_RATINGS.each_pair do |val, abilities|
      next if Battle::AI::BASE_ABILITY_RATINGS[val] && Battle::AI::BASE_ABILITY_RATINGS[val].include?(ability)
      Battle::AI::BASE_ABILITY_RATINGS[val] = [] if !Battle::AI::BASE_ABILITY_RATINGS[val]
      abilities.each{|ab|
        Battle::AI::BASE_ABILITY_RATINGS[val].push(ab)
      }
    end
    return ioam_wants_ability?(ability)
  end

>>>>>>> Stashed changes
end