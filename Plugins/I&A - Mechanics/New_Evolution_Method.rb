#===============================================================================
# New Evolution methods
#===============================================================================
GameData::Evolution.register({
  :id            => :AtkGreaterSpAtk,		# Monotaur
  :parameter     => Integer,
  :level_up_proc => proc { |pkmn, parameter|
    next pkmn.level >= parameter && pkmn.attack > pkmn.spatk
  }
})

GameData::Evolution.register({
  :id            => :AtkSpAtkEqual,			# Maxitaur
  :parameter     => Integer,
  :level_up_proc => proc { |pkmn, parameter|
    next pkmn.level >= parameter && pkmn.attack == pkmn.spatk
  }
})

GameData::Evolution.register({
  :id            => :SpAtkGreaterAtk,		# Manataur
  :parameter     => Integer,
  :level_up_proc => proc { |pkmn, parameter|
    next pkmn.level >= parameter && pkmn.attack < pkmn.spatk
  }
})

GameData::Evolution.register({
  :id            => :ItemFullMoon,			# Ursaluna
  :parameter     => :Item,
  :use_item_proc => proc { |pkmn, parameter, item|
    next item == parameter && PBDayNight.isNight? && moonphase == 4
  }
})

GameData::Evolution.register({
  :id            => :ItemNewMoon,			# Bloodmoon Ursaluna
  :parameter     => :Item,
  :use_item_proc => proc { |pkmn, parameter, item|
    next item == parameter && PBDayNight.isNight? && moonphase == 0
  }
})

GameData::Evolution.register({
  :id            => :ItemMidday,			# Solarctic
  :parameter     => :Item,
  :use_item_proc => proc { |pkmn, parameter, item|
    next item == parameter && PBDayNight.isMidday?
  }
})