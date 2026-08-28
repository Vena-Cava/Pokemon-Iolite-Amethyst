#===============================================================================
# Fishing Loot via PokéChests
# Place below Essentials fishing code and below PokéChests
#===============================================================================

module FishingLoot
  DEBUG = true

  CHANCE = {
    1 => 20,   # Old Rod
    2 => 15,   # Good Rod
    3 => 10    # Super Rod
  }

  TABLE = {
    1 => LootTables::FishingOldTable,
    2 => LootTables::FishingGoodTable,
    3 => LootTables::FishingSuperTable
  }
end

def pbFishing(hasEncounter, rodType = 1)
  $stats.fishing_count += 1

  speedup = ($player.first_pokemon &&
    [:STICKYHOLD, :SUCTIONCUPS].include?($player.first_pokemon.ability_id))

  biteChance = 20 + (25 * rodType)
  biteChance *= 1.5 if speedup
  biteChance = [biteChance, 100].min

  hookChance = 100

  itemChance = FishingLoot::CHANCE[rodType] || 0
  lootTable = FishingLoot::TABLE[rodType]
  can_get_loot = lootTable && itemChance > 0
  can_bite = hasEncounter || can_get_loot

  effectiveBiteChance = biteChance
  if !hasEncounter && can_get_loot
    effectiveBiteChance = biteChance * itemChance / 100.0
  end

  biteThreshold = (effectiveBiteChance * 10).round
  hookThreshold = (hookChance * 10).round
  itemThreshold = (itemChance * 10).round

  if FishingLoot::DEBUG
    puts "========================================"
    puts "FISHING DEBUG"
    puts "Rod Type: #{rodType}"
    puts "Has Encounter: #{hasEncounter}"
    puts "Can Get Loot: #{can_get_loot}"
    puts "Can Bite: #{can_bite}"
    puts "Base Bite Chance: #{biteChance}%"
    puts "Hook Chance: #{hookChance}%"
    puts "Item Chance: #{itemChance}%"
    puts "Effective Bite Chance: #{effectiveBiteChance}%"
    puts "Bite Threshold: #{biteThreshold}/1000"
    puts "Hook Threshold: #{hookThreshold}/1000"
    puts "Item Threshold: #{itemThreshold}/1000"
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
      puts "RESULT: Failed waiting for bite" if FishingLoot::DEBUG
      pbFishingEnd { pbMessageDisplay(msgWindow, _INTL("Not even a nibble...")) }
      break
    end

    bite_roll = rand(1000)
    puts "Bite Roll: #{bite_roll}/1000" if FishingLoot::DEBUG

    if can_bite && bite_roll < biteThreshold
      puts "BITE SUCCESS" if FishingLoot::DEBUG

      $scene.spriteset.addUserAnimation(
        Settings::EXCLAMATION_ANIMATION_ID,
        $game_player.x,
        $game_player.y,
        true,
        3
      )

      duration = rand(5..10) / 10.0

      if !pbWaitForInput(msgWindow, message + "\n" + _INTL("Oh! A bite!"), duration)
        puts "RESULT: Missed hook input" if FishingLoot::DEBUG
        pbFishingEnd { pbMessageDisplay(msgWindow, _INTL("It got away...")) }
        break
      end

      hook_roll = rand(1000)
      puts "Hook Roll: #{hook_roll}/1000" if FishingLoot::DEBUG

      if Settings::FISHING_AUTO_HOOK || hook_roll < hookThreshold
        pbFishingEnd do
          if !hasEncounter && can_get_loot
            puts "FINAL RESULT: ITEM - No Pokémon available" if FishingLoot::DEBUG
            pbMessageDisplay(msgWindow, _INTL("You reeled in an item!"))
            pbLootTable(lootTable, 100, :lead)
          else
            item_roll = rand(1000)
            puts "Item Roll: #{item_roll}/1000" if FishingLoot::DEBUG
            puts "Item Threshold: #{itemThreshold}/1000" if FishingLoot::DEBUG

            if can_get_loot && item_roll < itemThreshold
              puts "FINAL RESULT: ITEM" if FishingLoot::DEBUG
              pbMessageDisplay(msgWindow, _INTL("You reeled in an item!"))
              pbLootTable(lootTable, 100, :lead)
            else
              puts "FINAL RESULT: POKÉMON" if FishingLoot::DEBUG
              ret = true if hasEncounter
            end
          end
        end
        break
      else
        puts "RESULT: Hook failed" if FishingLoot::DEBUG
      end
    else
      puts "RESULT: No bite" if FishingLoot::DEBUG
      pbFishingEnd { pbMessageDisplay(msgWindow, _INTL("Not even a nibble...")) }
      break
    end
  end

  pbDisposeMessageWindow(msgWindow)
  return ret
end