#===============================================================================
# * Weather System - Water, Land and Cave encounters code
#===============================================================================

class PokemonEncounters
  # Checks the defined encounters for the current map and returns the encounter
  # type that the given weather should produce. Only returns an encounter type if
  # it has been defined for the current map.
  def find_valid_encounter_type_for_weather(base_type, new_type)
    ret = nil
    try_type = nil
    weather = $game_screen.weather_type if $game_screen.weather_type != :None
    try_type = (new_type.to_s + weather.to_s).to_sym
    if try_type && !has_encounter_type?(try_type)
      try_type = (base_type.to_s + weather.to_s).to_sym
    end
    ret = find_valid_encounter_type_for_season(base_type, new_type, try_type)
    return ret if ret
    return (has_encounter_type?(new_type)) ? new_type : (has_encounter_type?(base_type)) ? base_type : nil
  end
  
  # Checks the defined encounters for the current map and returns the encounter
  # type that the given season should produce. Only returns an encounter type if
  # it has been defined for the current map.
  def find_valid_encounter_type_for_season(base_type, time_type, new_type)
    ret = nil
    try_type = nil
	if pbIsSummer
	  season= "Summer"
	elsif pbIsAutumn 
	  season= "Autumn"
	elsif pbIsWinter
	  season= "Winter"
	else
	  season= "Spring"
	end
    try_type = (new_type.to_s + season).to_sym
    if try_type && !has_encounter_type?(try_type)
      try_type = (time_type.to_s + season).to_sym
    end
    if try_type && !has_encounter_type?(try_type)
      try_type = (base_type.to_s + season).to_sym
    end
    ret = try_type if try_type && has_encounter_type?(try_type)
    return ret if ret
    return (has_encounter_type?(new_type)) ? new_type : (has_encounter_type?(time_type)) ? time_type : (has_encounter_type?(base_type)) ? base_type : nil
  end

  # Checks the defined encounters for the current map and returns the encounter
  # type that the given time should produce. Only returns an encounter type if
  # it has been defined for the current map.
  def find_valid_encounter_type_for_time(base_type, time)
    ret = nil
    if PBDayNight.isDay?(time)
      try_type = nil
      if PBDayNight.isMorning?(time)
        try_type = (base_type.to_s + "Morning").to_sym
      elsif PBDayNight.isAfternoon?(time)
        try_type = (base_type.to_s + "Afternoon").to_sym
      elsif PBDayNight.isEvening?(time)
        try_type = (base_type.to_s + "Evening").to_sym
      end
      ret = try_type if try_type && has_encounter_type?(try_type)
      if !ret
        try_type = (base_type.to_s + "Day").to_sym
        ret = try_type if has_encounter_type?(try_type)
      end
    else
      try_type = (base_type.to_s + "Night").to_sym
      ret = try_type if has_encounter_type?(try_type)
    end
    ret = find_valid_encounter_type_for_weather(base_type, try_type)
    return ret if ret
    return (has_encounter_type?(base_type)) ? base_type : nil
  end
end

#===============================================================================
# * Weather System - Rock Smash and Headbutt encounters code
#===============================================================================
def pbHeadbuttEffect(event = nil)
  if Essentials::VERSION.include?("21")
    pbSEPlay("Headbutt")
    pbWait(1.0)
  end
  event = $game_player.pbFacingEvent(true) if !event
  a = (event.x + (event.x / 24).floor + 1) * (event.y + (event.y / 24).floor + 1)
  a = (a * 2 / 5) % 10   # Even 2x as likely as odd, 0 is 1.5x as likely as odd
  b = $player.public_ID % 10   # Practically equal odds of each value
  chance = 1                 # ~50%
  if a == b                    # 10%
    chance = 8
  elsif a > b && (a - b).abs < 5   # ~30.3%
    chance = 5
  elsif a < b && (a - b).abs > 5   # ~9.7%
    chance = 5
  end
  if rand(10) >= chance
    pbMessage(_INTL("Nope. Nothing..."))
  else
    enctype = (chance == 1) ? :HeadbuttLow : :HeadbuttHigh
	enctype = $PokemonEncounters.find_valid_encounter_type_for_weather(enctype, enctype)
    if pbEncounter(enctype)
      $stats.headbutt_battles += 1
    else
      pbMessage(_INTL("Nope. Nothing..."))
    end
  end
end

def pbRockSmashRandomEncounter
  enctype = $PokemonEncounters.find_valid_encounter_type_for_weather(:RockSmash, :RockSmash)
  if $PokemonEncounters.encounter_triggered?(enctype, false, false)
    $stats.rock_smash_battles += 1
    pbEncounter(enctype)
  end
end

#===============================================================================
# * Weather System - Rods encounters code
#===============================================================================
ItemHandlers::UseInField.add(:OLDROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Can't use that here."))
    next false
  end
  enctype = $PokemonEncounters.find_valid_encounter_type_for_weather(:OldRod, :OldRod)
  encounter = $PokemonEncounters.has_encounter_type?(enctype)
  if pbFishing(encounter, 1)
    $stats.fishing_battles += 1
    pbEncounter(enctype)
  end
  next true
})

ItemHandlers::UseInField.add(:GOODROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Can't use that here."))
    next false
  end
  enctype = $PokemonEncounters.find_valid_encounter_type_for_weather(:GoodRod, :GoodRod)
  encounter = $PokemonEncounters.has_encounter_type?(enctype)
  if pbFishing(encounter, 2)
    $stats.fishing_battles += 1
    pbEncounter(enctype)
  end
  next true
})

ItemHandlers::UseInField.add(:SUPERROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Can't use that here."))
    next false
  end
  enctype = $PokemonEncounters.find_valid_encounter_type_for_weather(:SuperRod, :SuperRod)
  encounter = $PokemonEncounters.has_encounter_type?(enctype)
  if pbFishing(encounter, 3)
    $stats.fishing_battles += 1
    pbEncounter(enctype)
  end
  next true
})