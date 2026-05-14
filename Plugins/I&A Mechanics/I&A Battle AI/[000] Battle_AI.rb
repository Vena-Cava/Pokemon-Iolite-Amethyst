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
      :PRECOGNITION
    ],
  
    7 => [
      :FORCEOFNATURE,
      :ENGINEOFINDUSTRY,
      :GALVANICGLADIATOR,
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
      :TOXICOLOGIST
    ],
  
    6 => [
      :ETERNALFLAME,
      :PURIFYINGLIGHT,
      :PURIFYINGBEAST,
      :SMOOTHSTONE,
      :IGNITION,
      :MIRAGE,
      :CATEGORYSIX,
      :NOURISHINGSOUL
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
      :FROSTBLIGHT
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
  
  IA_ALL_STATUS_CURE_ITEMS = [
    :STUFFEDGYRO
  ]
  
  ONE_STAT_RAISE_ITEMS[:LEANGYRO]    = [:ATTACK, 3]
  ONE_STAT_RAISE_ITEMS[:TOUGHGYRO]   = [:DEFENSE, 3]
  ONE_STAT_RAISE_ITEMS[:CHEESYGYRO]  = [:SPECIAL_ATTACK, 3]
  ONE_STAT_RAISE_ITEMS[:SEAFOODGYRO] = [:SPECIAL_DEFENSE, 3]
  ONE_STAT_RAISE_ITEMS[:LOWFATGYRO]  = [:SPEED, 3]
  

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

end