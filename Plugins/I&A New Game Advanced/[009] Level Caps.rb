#===============================================================================
# Advanced New Game - Level Caps
#===============================================================================

module AdvancedNewGame
  BOSS_IDS = {
    none: 0,
    rival_1: 1,
    gym_1: 2,
    gym_2: 3,
    champion: 99
  }

  BOSS_LEVEL_CAPS = {
    none: 10,
    rival_1: 8,
    gym_1: 14,
    gym_2: 22,
    champion: 65
  }

  def self.level_caps?
    enabled?(:level_caps)
  end

  def self.set_next_boss(symbol)
    return if !BOSS_IDS.has_key?(symbol)
    return if !$game_variables

    $game_variables[VARIABLE_NEXT_BOSS] = BOSS_IDS[symbol]
    $game_variables[VARIABLE_LEVEL_CAP] = BOSS_LEVEL_CAPS[symbol] || 100
  end

  def self.next_boss
    return :none if !$game_variables
    id = $game_variables[VARIABLE_NEXT_BOSS] || 0
    return BOSS_IDS.key(id) || :none
  end

  def self.current_level_cap
    return 100 if !level_caps?
    return 100 if !$game_variables

    cap = $game_variables[VARIABLE_LEVEL_CAP].to_i
    return BOSS_LEVEL_CAPS[:none] || 100 if cap <= 0

    return cap
  end

  def self.at_or_above_level_cap?(pkmn)
    return false if !pkmn
    return false if !level_caps?
    return pkmn.level >= current_level_cap
  end

  def self.clamp_to_level_cap(pkmn)
    return if !pkmn
    return if !level_caps?

    cap = current_level_cap
    return if pkmn.level <= cap

    pkmn.level = cap
    pkmn.calc_stats
  end
end

#===============================================================================
# Stop Pokémon from leveling past the cap
#===============================================================================

class Pokemon
  alias advanced_new_game_exp_set exp=

  def exp=(value)
    if AdvancedNewGame.level_caps?
      cap = AdvancedNewGame.current_level_cap
      cap_exp = growth_rate.minimum_exp_for_level(cap)
      value = [value.to_i, cap_exp.to_i].min
    end

    self.advanced_new_game_exp_set(value)
  end
end

class Battle
  def pbGainExpOne(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages = true)
    pkmn = pbParty(0)[idxParty]
    growth_rate = pkmn.growth_rate

    if AdvancedNewGame.at_or_above_level_cap?(pkmn)
      pbDisplayPaused(_INTL("{1} is already at the current level cap of Lv. {2}.",
        pkmn.name, AdvancedNewGame.current_level_cap
      )) if showMessages
      return
    end

    return if pkmn.exp >= growth_rate.maximum_exp

    isPartic    = defeatedBattler.participants.include?(idxParty)
    hasExpShare = expShare.include?(idxParty)
    level       = defeatedBattler.level

    exp = 0
    a = level * defeatedBattler.pokemon.base_exp

    if expShare.length > 0 && (isPartic || hasExpShare)
      if numPartic == 0
        exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? expShare.length : 1)
      elsif Settings::SPLIT_EXP_BETWEEN_GAINERS
        exp = a / (2 * numPartic) if isPartic
        exp += a / (2 * expShare.length) if hasExpShare
      else
        exp = isPartic ? a : a / 2
      end
    elsif isPartic
      exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? numPartic : 1)
    elsif expAll
      exp = a / 2
    end

    return if exp <= 0

    exp = (exp * 1.5).floor if Settings::MORE_EXP_FROM_TRAINER_POKEMON && trainerBattle?

    if Settings::SCALED_EXP_FORMULA
      exp /= 5
      levelAdjust = ((2 * level) + 10.0) / (pkmn.level + level + 10.0)
      levelAdjust **= 5
      levelAdjust = Math.sqrt(levelAdjust)
      exp *= levelAdjust
      exp = exp.floor
      exp += 1 if isPartic || hasExpShare
    else
      exp /= 7
    end

    isOutsider = (
      pkmn.owner.id != pbPlayer.id ||
      (pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language)
    )

    if isOutsider
      exp = (pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language) ? (exp * 1.7).floor : (exp * 1.5).floor
    end

    exp = exp * 3 / 2 if $bag.has?(:EXPCHARM)

    i = Battle::ItemEffects.triggerExpGainModifier(pkmn.item, pkmn, exp)
    if i < 0
      i = Battle::ItemEffects.triggerExpGainModifier(@initialItems[0][idxParty], pkmn, exp)
    end
    exp = i if i >= 0

    if Settings::AFFECTION_EFFECTS && @internalBattle && pkmn.affection_level >= 4 && !pkmn.mega?
      exp = exp * 6 / 5
      isOutsider = true
    end

    expFinal = growth_rate.add_exp(pkmn.exp, exp)

    reached_cap = false
    if AdvancedNewGame.level_caps?
      cap = AdvancedNewGame.current_level_cap
      cap_exp = growth_rate.minimum_exp_for_level(cap)

      if expFinal >= cap_exp
        expFinal = cap_exp
        reached_cap = true
      end
    end

    expGained = expFinal - pkmn.exp
    return if expGained <= 0

    if showMessages
      if isOutsider
        pbDisplayPaused(_INTL("{1} got a boosted {2} Exp. Points!", pkmn.name, expGained))
      else
        pbDisplayPaused(_INTL("{1} got {2} Exp. Points!", pkmn.name, expGained))
      end
    end

    curLevel = pkmn.level
    newLevel = growth_rate.level_from_exp(expFinal)

    $stats.total_exp_gained += expGained

    tempExp1 = pkmn.exp
    battler = pbFindBattler(idxParty)

    loop do
      levelMinExp = growth_rate.minimum_exp_for_level(curLevel)
      levelMaxExp = growth_rate.minimum_exp_for_level(curLevel + 1)
      tempExp2 = [levelMaxExp, expFinal].min

      pkmn.exp = tempExp2
      @scene.pbEXPBar(battler, levelMinExp, levelMaxExp, tempExp1, tempExp2)

      tempExp1 = tempExp2
      curLevel += 1

      if curLevel > newLevel
        pkmn.calc_stats
        battler&.pbUpdate(false)
        @scene.pbRefreshOne(battler.index) if battler
        break
      end

      pbCommonAnimation("LevelUp", battler) if battler

      oldTotalHP = pkmn.totalhp
      oldAttack  = pkmn.attack
      oldDefense = pkmn.defense
      oldSpAtk   = pkmn.spatk
      oldSpDef   = pkmn.spdef
      oldSpeed   = pkmn.speed

      battler.pokemon.changeHappiness("levelup") if battler&.pokemon
      pkmn.calc_stats
      battler&.pbUpdate(false)
      @scene.pbRefreshOne(battler.index) if battler

      pbDisplayPaused(_INTL("{1} grew to Lv. {2}!", pkmn.name, curLevel)) { pbSEPlay("Pkmn level up") }

      @scene.pbLevelUp(
        pkmn, battler,
        oldTotalHP, oldAttack, oldDefense,
        oldSpAtk, oldSpDef, oldSpeed
      )

      moveList = pkmn.getMoveList
      moveList.each { |m| pbLearnMove(idxParty, m[1]) if m[0] == curLevel }
    end

    if reached_cap && showMessages
      pbDisplayPaused(_INTL("{1} reached the current level cap of Lv. {2}!",
        pkmn.name,
        AdvancedNewGame.current_level_cap
      ))
    end
  end
end

#===============================================================================
# Prevent wasting level-up items at the level cap
#===============================================================================

module AdvancedNewGame
  LEVEL_UP_ITEMS = [
    :RARECANDY,
    :EXPCANDYXS,
    :EXPCANDYS,
    :EXPCANDYM,
    :EXPCANDYL,
    :EXPCANDYXL
  ]

  def self.level_up_item?(item)
    return LEVEL_UP_ITEMS.include?(item)
  end
end

module ItemHandlers
  class << self
    alias advanced_new_game_triggerUseOnPokemon triggerUseOnPokemon

    def triggerUseOnPokemon(item, qty, pkmn, scene)
      if AdvancedNewGame.level_up_item?(item) &&
         AdvancedNewGame.at_or_above_level_cap?(pkmn)

        pbMessage(_INTL("{1} is already at the current level cap of Lv. {2}.",
          pkmn.name,
          AdvancedNewGame.current_level_cap
        ))

        return false
      end

      return advanced_new_game_triggerUseOnPokemon(item, qty, pkmn, scene)
    end
  end
end