#===============================================================================
# Move Info UI
#===============================================================================
class Battle::Scene  
  #-----------------------------------------------------------------------------
  # Toggles the visibility of the Move Info UI.
  #-----------------------------------------------------------------------------
  def pbToggleMoveInfo(*args)
    return if pbInSafari?
    pbHideInfoUI if @enhancedUIToggle != :move
    @enhancedUIToggle = (@enhancedUIToggle.nil?) ? :move : nil
    (@enhancedUIToggle) ? pbSEPlay("GUI party switch") : pbPlayCloseMenuSE
    @sprites["enhancedUI"].visible = !@enhancedUIToggle.nil?
    (@sprites["enhancedUI"].visible) ? pbHideUIPrompt : pbRefreshUIPrompt
    pbUpdateTargetIcons
    pbUpdateMoveInfoWindow(*args)
  end

  #-----------------------------------------------------------------------------
  # Updates icon sprites to be used for the Move Info UI.
  #-----------------------------------------------------------------------------
  def pbUpdateTargetIcons
    idx = 0
    @battle.allBattlers.each do |b|
      if b && !b.fainted? && b.index.odd?
        @sprites["info_icon#{b.index}"].pokemon = b.displayPokemon
        @sprites["info_icon#{b.index}"].visible = @enhancedUIToggle == :move
        @sprites["info_icon#{b.index}"].x = Graphics.width - 32 - (idx * 64)
        @sprites["info_icon#{b.index}"].y = 48
        if b.dynamax?
          @sprites["info_icon#{b.index}"].set_dynamax_icon_pattern
        elsif b.tera?
          @sprites["info_icon#{b.index}"].set_tera_icon_pattern
        else
          @sprites["info_icon#{b.index}"].zoom_x = 1
          @sprites["info_icon#{b.index}"].zoom_y = 1
          @sprites["info_icon#{b.index}"].pattern = nil
        end
        idx += 1
      else
        @sprites["info_icon#{b.index}"].visible = false
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Draws the Move Info UI.
  #-----------------------------------------------------------------------------
  def pbUpdateMoveInfoWindow(battler, specialAction, cw)
    @enhancedUIOverlay.clear
    return if @enhancedUIToggle != :move
    xpos = 0
    ypos = 78
    move = battler.moves[cw.index].clone
    if battler.dynamax? || specialAction == :dynamax && cw.mode == 2
      move = move.convert_dynamax_move(battler, @battle)
    end
    powBase   = accBase   = priBase   = effBase   = BASE_LIGHT
    powShadow = accShadow = priShadow = effShadow = SHADOW_LIGHT
    basePower = calcPower = power = move.power
    category = move.category
    type = move.pbCalcType(battler)
    terastal = battler.tera? || (specialAction == :tera && cw.teraType > 0)
    #---------------------------------------------------------------------------
    # Gets move type and category (for display purposes).
    case move.function_code
    when "CategoryDependsOnHigherDamageTera",
         "TerapagosCategoryDependsOnHigherDamage"
      if terastal
        case move.function_code
        when "CategoryDependsOnHigherDamageTera"
          type = battler.tera_type
          basePower = calcPower = power = 100
        when "TerapagosCategoryDependsOnHigherDamage"
          type = :STELLAR if battler.isSpecies?(:TERAPAGOS)
        end
        realAtk, realSpAtk = battler.getOffensiveStats
        category = (realAtk > realSpAtk) ? 0 : 1
      else
        type = move.type
        category = move.calcCategory
      end
    when "CategoryDependsOnHigherDamagePoisonTarget", 
         "CategoryDependsOnHigherDamageIgnoreTargetAbility"
      move.pbOnStartUse(battler, [battler.pbDirectOpposing])
      category = move.calcCategory
    end
    #---------------------------------------------------------------------------
    # Draws images.
    typenumber = GameData::Type.get(type).icon_position
    bgnumber = (Settings::USE_MOVE_TYPE_BACKGROUNDS) ? typenumber + 1 : 0
    imagePos = [
      [@path + "move_bg",      xpos,       ypos,     0, bgnumber * 164, 684, 164],
      ["Graphics/UI/types",    xpos + 282, ypos + 8, 0, typenumber * 28, 64, 28],
      ["Graphics/UI/category", xpos + 350, ypos + 8, 0, category * 28, 64, 28]
    ]
    pbDrawMoveFlagIcons(xpos, ypos, move, imagePos)
    pbDrawTypeEffectiveness(xpos, ypos, move, type, imagePos)
    pbDrawImagePositions(@enhancedUIOverlay, imagePos)
    #---------------------------------------------------------------------------
    # Move damage calculations (for display purposes).
    if move.damagingMove?
      if terastal
        if battler.typeTeraBoosted?(type, true)
          bonus = (battler.tera_type == :STELLAR) ? 1.2 : 1.5
          stab = (battler.types.include?(type)) ? 2 : bonus
        else
          stab = (battler.types.include?(type)) ? 1.5 : 1
        end
      else
        stab = (battler.pbHasType?(type)) ? 1.5 : 1
      end
      stab = 1 if defined?(move.pbFixedDamage(battler, battler.pbDirectOpposing))
      hidePower = false
      case move.function_code
      when "ThrowUserItemAtTarget"                     # Fling
        hidePower = true if !battler.item
      when "TypeAndPowerDependOnUserBerry"             # Natural Gift
        hidePower = true if !battler.item || !battler.item.is_berry?
      when "PursueSwitchingFoe",                       # Pursuit
           "RemoveTargetItem",                         # Knock Off
           "HitOncePerUserTeamMember",                 # Beat Up
           "DoublePowerIfTargetActed",                 # Payback
           "DoublePowerIfTargetNotActed",              # Bolt Beak, Fishious Rend
           "PowerHigherWithTargetHP",                  # Crush Grip, Wring Out
           "PowerHigherWithTargetHP100PowerRange",     # Hard Press
           "HitThreeTimesPowersUpWithEachHit",         # Triple Kick
           "PowerHigherWithTargetWeight",              # Low Kick, Grass Knot
           "PowerHigherWithUserFasterThanTarget",      # Electro Ball
           "PowerHigherWithTargetFasterThanUser",      # Gyro Ball
           "FixedDamageUserLevelRandom",               # Psywave
           "RandomlyDamageOrHealTarget",               # Present
           "RandomlyDealsDoubleDamage",                # Fickle Beam
           "RandomPowerDoublePowerIfTargetUnderground" # Magnitude
        hidePower = true if calcPower == 1
      end
      if !hidePower
        calcPower = move.pbBaseDamage(basePower, battler, battler.pbDirectOpposing)
        calcPower = move.pbModifyDamage(calcPower, battler, battler.pbDirectOpposing)
        calcPower = move.pbBaseDamageTera(calcPower, battler, type, true) if terastal
      end
      hidePower = true if calcPower == 1
      powerDiff = (move.function_code == "PowerHigherWithUserHP") ? calcPower - basePower : basePower - calcPower
      calcPower *= stab
      power = (calcPower >= powerDiff) ? calcPower : basePower * stab
    end
    #---------------------------------------------------------------------------
    # Final move attribute calculations.
    acc = move.accuracy
    pri = move.priority
    case move.function_code
    when "ParalyzeFlinchTarget", "BurnFlinchTarget", "FreezeFlinchTarget"
      chance = 10
    when "LowerTargetDefense1FlinchTarget"
      chance = 50
    else
      chance = move.addlEffect
    end
    baseChance = chance
    showTera = terastal && battler.typeTeraBoosted?(type, true)
    bonus, power, acc, pri, chance = pbGetFinalModifiers(
      battler, move, type, basePower, power, acc, pri, chance, showTera)
    calcPower = power if power > basePower
    if power > 1
      if calcPower > basePower
        powBase, powShadow = BASE_RAISED, SHADOW_RAISED
      elsif power < (basePower * stab).floor
        powBase, powShadow = BASE_LOWERED, SHADOW_LOWERED
      end
    end
    if acc > 0
      if acc > move.accuracy
        accBase, accShadow = BASE_RAISED, SHADOW_RAISED
      elsif acc < move.accuracy
        accBase, accShadow = BASE_LOWERED, SHADOW_LOWERED
      end
    end
    if pri != 0
      if pri > move.priority
        priBase, priShadow = BASE_RAISED, SHADOW_RAISED
      elsif pri < move.priority
        priBase, priShadow = BASE_LOWERED, SHADOW_LOWERED
      end
    end
    if chance > 0
      if chance > baseChance
        effBase, effShadow = BASE_RAISED, SHADOW_RAISED
      elsif chance < baseChance
        effBase, effShadow = BASE_LOWERED, SHADOW_LOWERED
      end
    end
    #---------------------------------------------------------------------------
    # Draws text.
    textPos = []
    displayPower    = (power  == 0) ? "---" : (hidePower) ? "???" : power.ceil.to_s
    displayAccuracy = (acc    == 0) ? "---" : acc.ceil.to_s
    displayPriority = (pri    == 0) ? "---" : (pri > 0) ? "+" + pri.to_s : pri.to_s
    displayChance   = (chance == 0) ? "---" : chance.ceil.to_s + "%"
    textPos.push(
      [move.name,       xpos + 10,  ypos + 12, :left,   BASE_LIGHT, SHADOW_LIGHT, :outline],
      [_INTL("Pow"),    xpos + 256, ypos + 40, :left,   BASE_LIGHT, SHADOW_LIGHT],
      [displayPower,    xpos + 309, ypos + 40, :center, powBase,    powShadow],
      [_INTL("Acc"),    xpos + 348, ypos + 40, :left,   BASE_LIGHT, SHADOW_LIGHT],
      [displayAccuracy, xpos + 401, ypos + 40, :center, accBase,    accShadow],
      [_INTL("Pri"),    xpos + 442, ypos + 40, :left,   BASE_LIGHT, SHADOW_LIGHT],
      [displayPriority, xpos + 484, ypos + 40, :center, priBase,    priShadow],
      [_INTL("Eff"),    xpos + 428, ypos + 12, :left,   BASE_LIGHT, SHADOW_LIGHT],
      [displayChance,   xpos + 484, ypos + 12, :center, effBase,    effShadow]
    )
    textPos.push([bonus[0], xpos + 8, ypos + 132, :left, bonus[1], bonus[2], :outline]) if bonus
    pbDrawTextPositions(@enhancedUIOverlay, textPos)
    drawTextEx(@enhancedUIOverlay, xpos + 8, ypos + 74, Graphics.width - 12, 2, 
      GameData::Move.get(move.id).description, BASE_LIGHT, SHADOW_LIGHT)
  end
  
  #-----------------------------------------------------------------------------
  # Draws the move flag icons for each move in the Move Info UI.
  #-----------------------------------------------------------------------------
  def pbDrawMoveFlagIcons(xpos, ypos, move, imagePos)
    flagX = xpos + 6
    flagY = ypos + 35
    icons = 0
    flags = move.flags.clone
    if GameData::Target.get(move.target).targets_foe
      flags.push("NoProtect")      if !flags.include?("CanProtect")
      flags.push("NoMirrorMove")   if !flags.include?("CanMirrorMove")
    end
    flags.uniq!
    flags.each do |flag|
      break if icons > 8
      flag = "ZMove"               if flag.include?("ZMove_")
      flag = "DynamaxMove"         if flag.include?("DynamaxMove_") || flag == "GmaxMove"
      flag = "HighCriticalHitRate" if flag.include?("HighCriticalHitRate_")
      path = @path + "Move Flags/" + flag
      next if !pbResolveBitmap(path)
      imagePos.push([path, flagX + (icons * 26), flagY])
      icons += 1
    end
  end
  
  #-----------------------------------------------------------------------------
  # Draws the type effectiveness display for each opponent in the Move Info UI.
  #-----------------------------------------------------------------------------
  def pbDrawTypeEffectiveness(xpos, ypos, move, type, imagePos)
    idx = 0
    @battle.allBattlers.each do |b|
      next if b.index.even?
      if b && !b.fainted? && move.category < 2
        poke = b.displayPokemon
        unknown_species = $player.pokedex.battled_count(poke.species) == 0 && !$player.pokedex.owned?(poke.species)
        unknown_species = false if Settings::SHOW_TYPE_EFFECTIVENESS_FOR_NEW_SPECIES
        unknown_species = true if b.celestial?
        value = Effectiveness.calculate(type, *b.pbTypes(true))
        if unknown_species                             then effct = 0
        elsif b.tera? && type == :STELLAR              then effct = 3
        elsif Effectiveness.ineffective?(value)        then effct = 1
        elsif Effectiveness.not_very_effective?(value) then effct = 2
        elsif Effectiveness.super_effective?(value)    then effct = 3
        else effct = 4
        end
        imagePos.push([@path + "move_effectiveness", Graphics.width - 64 - (idx * 64), ypos - 76, effct * 64, 0, 64, 76])
        @sprites["info_icon#{b.index}"].visible = true
      else
        @sprites["info_icon#{b.index}"].visible = false
      end
      idx += 1
    end
  end
  
  #-----------------------------------------------------------------------------
  # Applies final move attribute modifiers and any additional bonus text.
  #-----------------------------------------------------------------------------
  def pbGetFinalModifiers(battler, move, type, baseDmg, power, acc, pri, chance, showTera)
    bonus = nil
    powMults = {
      :power_multiplier        => 1.0,
      :attack_multiplier       => 1.0,
      :defense_multiplier      => 1.0,
      :final_damage_multiplier => 1.0
    }
    accMods = {
      :base_accuracy           => acc,
      :accuracy_stage          => 0,
      :evasion_stage           => 0,
      :accuracy_multiplier     => 1.0,
      :evasion_multiplier      => 1.0
    }
    target = (@battle.pbOpposingBattlerCount == 1) ? battler.pbDirectOpposing(true) : nil
    #---------------------------------------------------------------------------
    # Bonus text and modifiers for ability changes to move.
    #---------------------------------------------------------------------------
    if battler.abilityActive?
      5.times do |i|
        break if bonus
        case i
        #-----------------------------------------------------------------------
        when 0 # Abilities that alter move type.
          next if type == move.type
          newType = Battle::AbilityEffects.triggerModifyMoveBaseType(battler.ability, battler, move, move.type)
          next if newType != type
          bonus = [_INTL("Type changed by the {1} ability.", battler.abilityName), BASE_RAISED, SHADOW_RAISED]
          power *= 1.2 if move.powerBoost
          move.powerBoost = false
        #-----------------------------------------------------------------------
        when 1 # Abilities that alter additional effect chance.
          next if power == 0 || [0, 100].include?(chance) || battler.ability_id != :SERENEGRACE
          chance = [chance * 2, 100].min
          bonus = [_INTL("Effect chance boosted by the {1} ability.", battler.abilityName), BASE_RAISED, SHADOW_RAISED]
        #-----------------------------------------------------------------------
        when 2 # Abilities that alter priority.
          oldPri = pri
          pri = Battle::AbilityEffects.triggerPriorityChange(battler.ability, battler, move, pri)
          if pri > oldPri
            bonus = [_INTL("Priority boosted by the {1} ability.", battler.abilityName), BASE_RAISED, SHADOW_RAISED]
          elsif pri < oldPri
            bonus = [_INTL("Priority lowered by the {1} ability.", battler.abilityName), BASE_LOWERED, SHADOW_LOWERED]
          end
        #-----------------------------------------------------------------------
        when 3 # Abilities that alter accuracy.
          next if acc == 0
          oldAcc = acc
          Battle::AbilityEffects.triggerAccuracyCalcFromUser(
            battler.ability, accMods, battler, (target || battler), move, type
          )
          acc = [accMods[:base_accuracy] * accMods[:accuracy_multiplier], 100].min
          if acc > oldAcc || acc == 0
            bonus = [_INTL("Accuracy boosted by the {1} ability.", battler.abilityName), BASE_RAISED, SHADOW_RAISED]
          elsif acc < oldAcc
            bonus = [_INTL("Accuracy lowered by the {1} ability.", battler.abilityName), BASE_LOWERED, SHADOW_LOWERED]
          end
        #-----------------------------------------------------------------------
        when 4 # Abilities that alter base power.
          next if power == 0
          next if battler.hasActiveAbility?(:ANALYTIC)
          next if !target && battler.hasActiveAbility?(:RIVALRY)
          oldPower = power
          Battle::AbilityEffects.triggerDamageCalcFromUser(
            battler.ability, battler, (target || battler), move, powMults, baseDmg, type
          )
          power *= powMults[:power_multiplier]
          if power > oldPower
            bonus = [_INTL("Power boosted by the {1} ability.", battler.abilityName), BASE_RAISED, SHADOW_RAISED]
          elsif power < oldPower
            bonus = [_INTL("Power weakened by the {1} ability.", battler.abilityName), BASE_LOWERED, SHADOW_LOWERED]
          end
        end
      end
    end
    #---------------------------------------------------------------------------
    # Bonus text and modifiers for held item changes to move.
    #---------------------------------------------------------------------------
    if battler.item && battler.itemActive?
      if ![0, 100].include?(acc)  # Held items that alter accuracy.
        oldAcc = acc
        accMods[:base_accuracy] = acc
        accMods[:accuracy_multiplier] = 1.0
        Battle::ItemEffects.triggerAccuracyCalcFromUser(
          battler.item, accMods, battler, (target || battler), move, type
        )
        acc = [accMods[:base_accuracy] * accMods[:accuracy_multiplier], 100].min
        if acc != oldAcc
          if acc > oldAcc || acc == 0
            bonus = [_INTL("Accuracy boosted by the held {1}.", battler.itemName), BASE_RAISED, SHADOW_RAISED]
          elsif acc < oldAcc
            bonus = [_INTL("Accuracy lowered by the held {1}.", battler.itemName), BASE_LOWERED, SHADOW_LOWERED]
          end
        end
      end
      if power > 0                # Held items that alter base power.
        oldPower = power
        powMults[:power_multiplier] = 1.0
        Battle::ItemEffects.triggerDamageCalcFromUser(
          battler.item, battler, (target || battler), move, powMults, baseDmg, type
        )
        power *= powMults[:power_multiplier]
        if power > oldPower
          bonus = [_INTL("Power boosted by the held {1}.", battler.itemName), BASE_RAISED, SHADOW_RAISED]
        elsif power < oldPower
          bonus = [_INTL("Power weakened by the held {1}.", battler.itemName), BASE_LOWERED, SHADOW_LOWERED]
        end
      end
    end
    #---------------------------------------------------------------------------
    # Special note for Mega Launcher + Heal Pulse.
    #---------------------------------------------------------------------------
    if battler.hasActiveAbility?(:MEGALAUNCHER) && move.healingMove? && move.pulseMove?
      bonus = [_INTL("Healing boosted by the {1} ability.", battler.abilityName), BASE_RAISED, SHADOW_RAISED]
    end
    #---------------------------------------------------------------------------
    # Bonus text for moves that utilize special battle mechanics.
    #---------------------------------------------------------------------------
    if showTera && move.damagingMove?
	    bonus = [_INTL("Power boosted by Terastallization."), BASE_RAISED, SHADOW_RAISED]
    elsif defined?(move.zMove?) && move.zMove? && move.has_zpower?
      effect, stage = move.get_zpower_effect
      case effect
      when "HealUser"    then text = _INTL("Z-Power: Fully restores the user's HP.")
      when "HealSwitch"  then text = _INTL("Z-Power: Fully restores an incoming Pokémon's HP.")
      when "CriticalHit" then text = _INTL("Z-Power: Raises the user's critical hit rate.")
      when "ResetStats"  then text = _INTL("Z-Power: Resets the user's lowered stat stages.")
      when "FollowMe"    then text = _INTL("Z-Power: The user becomes the center of attention.")
      else
        if stage
          stat = (effect == "AllStats") ? "stats" : GameData::Stat.get(effect.to_sym).name
          case stage
          when "3" then text = _INTL("Z-Power: Drastically raises the user's {1}.", stat)
          when "2" then text = _INTL("Z-Power: Sharply raises the user's {1}.", stat)
          else          text = _INTL("Z-Power: Raises the user's {1}.", stat)
          end
        end
      end
      bonus = [text, BASE_RAISED, SHADOW_RAISED] if text
    end
    return bonus, power, acc, pri, chance
  end
end