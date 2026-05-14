#===============================================================================
# PokéChests
#===============================================================================

def pbAnimatePokeChest(event = nil)
  event ||= $game_player.pbFacingEvent
  return false if !event || !event.respond_to?(:name)
  return false if !event.name[/pokechest/i]

  return false if !pbConfirmMessage(_INTL("It's a Chest. Open it?"))

  pbSEPlay("Door enter")

  pbMoveRoute(event, [
    PBMoveRoute::WAIT, 2,
    PBMoveRoute::TURN_LEFT,  PBMoveRoute::WAIT, 2,
    PBMoveRoute::TURN_RIGHT, PBMoveRoute::WAIT, 2,
    PBMoveRoute::TURN_UP,    PBMoveRoute::WAIT, 2
  ])

  pbWait(0.4)
  return true
end

#===============================================================================
# Gimmighoul Chests
#===============================================================================

GameData::EncounterType.register({
  :id             => :GimmighoulChest,
  :type           => :none,
  :trigger_chance => 50
})

GameData::EncounterType.register({
  :id             => :GimmifoolChest,
  :type           => :none,
  :trigger_chance => 50
})

def pbGimmighoulChest(event = nil)
  event ||= $game_player.pbFacingEvent
  return false if !event || !event.respond_to?(:name)
  return false if !event.name[/gimmighoulchest/i]

  return false if !pbConfirmMessage(_INTL("It's a strange chest. Open it?"))

  pbAnimatePokeChest(event)

  if $PokemonEncounters.encounter_triggered?(:GimmighoulChest, false, false)
    pbSetSelfSwitch(event.id, "A", true)   # Chest Opens
    pbEncounter(:GimmighoulChest)
	pbLootTable(LootTables::GimmighoulTable, 100, :lead)
    pbSetSelfSwitch(event.id, "B", true)   # Chest disappears
  else
    pbLootTable(LootTables::GimmighoulTable, 100, :lead)
    pbSetSelfSwitch(event.id, "A", true)   # Chest stays open
  end

  return true
end

def pbGimmifoolChest(event = nil)
  event ||= $game_player.pbFacingEvent
  return false if !event || !event.respond_to?(:name)
  return false if !event.name[/gimmifoolchest/i]

  return false if !pbConfirmMessage(_INTL("It's a strange chest. Open it?"))

  pbAnimatePokeChest(event)

  if $PokemonEncounters.encounter_triggered?(:GimmifoolChest, false, false)
    pbEncounter(:GimmifoolChest)
	pbLootTable(LootTables::GimmifoolTable, 100, :lead)
    pbSetSelfSwitch(event.id, "B", true)   # Chest disappears
  else
    pbLootTable(LootTables::GimmifoolTable, 100, :lead)
    pbSetSelfSwitch(event.id, "A", true)   # Chest stays open
  end

  return true
end