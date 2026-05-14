#===============================================================================
# Sand Castle
#===============================================================================

GameData::EncounterType.register({
  :id             => :SandCastle,
  :type           => :none,
  :trigger_chance => 50
})

GameData::EncounterType.register({
  :id             => :SandCastleLarge,
  :type           => :none,
  :trigger_chance => 50
})

GameData::EncounterType.register({
  :id             => :DarkGrass,
  :type           => :land,
  :trigger_chance => 21
})

GameData::EncounterType.register({
  :id             => :DarkGrassDay,
  :type           => :land,
  :trigger_chance => 21
})

GameData::EncounterType.register({
  :id             => :DarkGrassNight,
  :type           => :land,
  :trigger_chance => 21
})

GameData::EncounterType.register({
  :id             => :DarkGrassMorning,
  :type           => :land,
  :trigger_chance => 21
})

GameData::EncounterType.register({
  :id             => :DarkGrassAfternoon,
  :type           => :land,
  :trigger_chance => 21
})

GameData::EncounterType.register({
  :id             => :DarkGrassEvening,
  :type           => :land,
  :trigger_chance => 21
})

#===============================================================================
# Sand Castle encounter type support
#===============================================================================

def pbSandCastleRandomEncounter
  if $PokemonEncounters.encounter_triggered?(:SandCastle, false, false)
    pbEncounter(:SandCastle)
  end
end

def pbKickSandCastle(event = nil)
  event ||= $game_player.pbFacingEvent
  return false if !event || !event.respond_to?(:name)
  return false if !event.name[/sandcastle/i]

  if pbConfirmMessage(_INTL("It's a sand castle. Would you like to kick it over?"))
    pbMessage(_INTL("{1} kicked over the sand castle!", $player.name))
    pbSmashEvent(event)
    pbSandCastleRandomEncounter
    return true
  end

  return false
end

def pbSandCastleLargeRandomEncounter
  if $PokemonEncounters.encounter_triggered?(:SandCastleLarge, false, false)
    pbEncounter(:SandCastleLarge)
  end
end

def pbKickSandCastle(event = nil)
  event ||= $game_player.pbFacingEvent
  return false if !event || !event.respond_to?(:name)
  return false if !event.name[/sandcastle/i]

  if pbConfirmMessage(_INTL("It's a sand castle. Would you like to kick it over?"))
    pbMessage(_INTL("{1} kicked over the sand castle!", $player.name))
    pbSmashEvent(event)
    pbSandCastleLargeRandomEncounter
    return true
  end

  return false
end

#===============================================================================
# Dark Grass encounter type support
#===============================================================================
class PokemonEncounters
  alias ia_dark_grass_encounter_type encounter_type

  def encounter_type
    time = pbGetTimeNow

    # Surfing should behave normally
    return ia_dark_grass_encounter_type if $PokemonGlobal.surfing

    terrain_tag = $game_map.terrain_tag($game_player.x, $game_player.y)

    # If standing on Dark Grass, use DarkGrass encounter tables first
    if terrain_tag.id == :DarkGrass
      ret = find_valid_encounter_type_for_time(:DarkGrass, time)
      return ret if ret
    end

    # Otherwise use normal Essentials logic
    return ia_dark_grass_encounter_type
  end
end