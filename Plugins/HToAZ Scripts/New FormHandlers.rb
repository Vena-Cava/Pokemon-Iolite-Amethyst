#===============================================================================
# Ursaluna
#===============================================================================
MultipleForms.register(:URSALUNA, {
  "getFormOnCreation" => proc { |pkmn|
    next 1 if PBDayNight.isNight? && moonphase == 0		# Bloodmoon
    next 0 if PBDayNight.isNight? && moonphase == 4		# Hisui
  }
})

#===============================================================================
# Ogerpon
#===============================================================================
MultipleForms.register(:OGERPON, {
  "getForm" => proc { |pkmn|
    next 2 if pkmn.hasItem?(:HEARTHFLAMEMASK)
	next 4 if pkmn.hasItem?(:CORNERSTONEMASK)
	next 6 if pkmn.hasItem?(:WELLSPRINGMASK)
    next 0
  },
  "getFormOnEnteringBattle" => proc { |pkmn, wild|
    next pkmn.form + 1
	pbMessage(_INTL("{1} put on its mask!", pkmn.name))
  },
  "changePokemonOnStartingBattle" => proc { |pkmn, battle|
    if GameData::Move.exists?(:IVYCUDGELF) && pkmn.hasItem?(:HEARTHFLAMEMASK)
      pkmn.moves.each { |move| move.id = :IVYCUDGELF if move.id == :IVYCUDGEL }
	elsif GameData::Move.exists?(:IVYCUDGELR) && pkmn.hasItem?(:CORNERSTONEMASK)
      pkmn.moves.each { |move| move.id = :IVYCUDGELF if move.id == :IVYCUDGEL }
	elsif GameData::Move.exists?(:IVYCUDGELW) && pkmn.hasItem?(:WELLSPRINGMASK)
      pkmn.moves.each { |move| move.id = :IVYCUDGELF if move.id == :IVYCUDGEL }
    end
  },
  "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
	next pkmn.form - 1 if pkmn.fainted? || endBattle
  },
  "changePokemonOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
    if endBattle
      pkmn.moves.each { |move| move.id = :IVYCUDGEL if move.id == :IVYCUDGELF || move.id == :IVYCUDGELR || move.id == :IVYCUDGELW }
    end
  }
})


