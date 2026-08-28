#===============================================================================
# Meal Powers - Fishing Powers
# Patches fishing without editing the original fishing script.
#===============================================================================

module MealPowers
  FISHING_POWER_MULT = {
    0 => 1.0,
    1 => 1.2,
    2 => 1.5,
    3 => 2.0
  }

  FISHING_ITEM_POWER_MULT = {
    0 => 1.0,
    1 => 1.5,
    2 => 3.0,
    3 => 5.0
  }

  def self.fishing_multiplier
    return FISHING_POWER_MULT[level(:FISHING)] || 1.0
  end

  def self.fishing_item_multiplier
    return FISHING_ITEM_POWER_MULT[level(:FISHITEM)] || 1.0
  end
end

#===============================================================================
# Full pbFishing patch
#===============================================================================

def pbFishing(hasEncounter, rodType = 1)
  $stats.fishing_count += 1

  speedup = ($player.first_pokemon &&
    [:STICKYHOLD, :SUCTIONCUPS].include?($player.first_pokemon.ability_id))

  biteChance = 20 + (25 * rodType)
  biteChance *= 1.5 if speedup
  biteChance *= MealPowers.fishing_multiplier
  biteChance = [biteChance, 100].min

  hookChance = 100

  itemChance = FishingLoot::CHANCE[rodType] || 0
  itemChance *= MealPowers.fishing_item_multiplier
  itemChance = [itemChance, 100].min

  lootTable = FishingLoot::TABLE[rodType]
  can_get_loot = lootTable && itemChance > 0
  enc_type = MealPowers.fishing_encounter_type(rodType)
  pokemon_fully_repelled = hasEncounter && MealPowers.encounter_table_fully_repelled?(enc_type)
  hasEncounter = false if pokemon_fully_repelled
  can_bite = hasEncounter || can_get_loot

  effectiveBiteChance = biteChance
  if !hasEncounter && can_get_loot
    effectiveBiteChance = biteChance * itemChance / 100.0
  end

  biteThreshold = (effectiveBiteChance * 10).round
  hookThreshold = (hookChance * 10).round
  itemThreshold = (itemChance * 10).round

  if MealPowers::DEBUG
    puts "========================================"
    puts "FISHING + MEAL POWER DEBUG"
    puts "Rod Type: #{rodType}"
    puts "Has Encounter: #{hasEncounter}"
    puts "Can Get Loot: #{can_get_loot}"
    puts "Can Bite: #{can_bite}"
    puts "Fishing Power Lv: #{MealPowers.level(:FISHING)}"
    puts "Fishing Power Mult: x#{MealPowers.fishing_multiplier}"
    puts "Fishing Item Power Lv: #{MealPowers.level(:FISHITEM)}"
    puts "Fishing Item Power Mult: x#{MealPowers.fishing_item_multiplier}"
    puts "Base/Modified Bite Chance: #{biteChance}%"
    puts "Hook Chance: #{hookChance}%"
    puts "Modified Item Chance: #{itemChance}%"
    puts "Effective Bite Chance: #{effectiveBiteChance}%"
    puts "Bite Threshold: #{biteThreshold}/1000"
    puts "Hook Threshold: #{hookThreshold}/1000"
    puts "Item Threshold: #{itemThreshold}/1000"
    puts "Fishing Encounter Type: #{enc_type}"
    puts "Pokémon Fully Repelled?: #{pokemon_fully_repelled}"
    puts "========================================"
  end

  pbFishingBegin
  msgWindow = pbCreateMessageWindow
  ret = false

  loop do
    time = rand(5..10)
    time = [time, rand(5..10)].min if speedup
    message = ""
    time.times { message += ".   " }

    if pbWaitMessage(msgWindow, time)
      puts "RESULT: Failed waiting for bite" if MealPowers::DEBUG
      pbFishingEnd { pbMessageDisplay(msgWindow, _INTL("Not even a nibble...")) }
      break
    end

    bite_roll = rand(1000)
    puts "Bite Roll: #{bite_roll}/1000" if MealPowers::DEBUG

    if can_bite && bite_roll < biteThreshold
      puts "BITE SUCCESS" if MealPowers::DEBUG

      $scene.spriteset.addUserAnimation(
        Settings::EXCLAMATION_ANIMATION_ID,
        $game_player.x,
        $game_player.y,
        true,
        3
      )

      duration = rand(5..10) / 10.0

      if !pbWaitForInput(msgWindow, message + "\n" + _INTL("Oh! A bite!"), duration)
        puts "RESULT: Missed hook input" if MealPowers::DEBUG
        pbFishingEnd { pbMessageDisplay(msgWindow, _INTL("It got away...")) }
        break
      end

      hook_roll = rand(1000)
      puts "Hook Roll: #{hook_roll}/1000" if MealPowers::DEBUG

      if Settings::FISHING_AUTO_HOOK || hook_roll < hookThreshold
        pbFishingEnd do
          if !hasEncounter && can_get_loot
            puts "FINAL RESULT: ITEM - No Pokémon available" if MealPowers::DEBUG
            pbMessageDisplay(msgWindow, _INTL("You reeled in an item!"))
            pbLootTable(lootTable, 100, :lead)
          else
            item_roll = rand(1000)
            puts "Item Roll: #{item_roll}/1000" if MealPowers::DEBUG
            puts "Item Threshold: #{itemThreshold}/1000" if MealPowers::DEBUG

            if can_get_loot && item_roll < itemThreshold
              puts "FINAL RESULT: ITEM" if MealPowers::DEBUG
              pbMessageDisplay(msgWindow, _INTL("You reeled in an item!"))
              pbLootTable(lootTable, 100, :lead)
            else
              puts "FINAL RESULT: POKÉMON" if MealPowers::DEBUG
              ret = true if hasEncounter
            end
          end
        end
        break
      else
        puts "RESULT: Hook failed" if MealPowers::DEBUG
      end
    else
      puts "RESULT: No bite" if MealPowers::DEBUG
      pbFishingEnd { pbMessageDisplay(msgWindow, _INTL("Not even a nibble...")) }
      break
    end
  end

  pbDisposeMessageWindow(msgWindow)
  return ret
end