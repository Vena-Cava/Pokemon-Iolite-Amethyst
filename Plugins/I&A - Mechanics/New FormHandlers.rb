#===============================================================================
# Puffono
#===============================================================================
MultipleForms.register(:PUFFONO, {
  "getFormOnLeavingBattle" => proc { |pkmn, battle, usedInBattle, endBattle|
    next 0 if pkmn.fainted? || endBattle
  }
})

#===============================================================================
# Ursaluna
#===============================================================================
MultipleForms.register(:URSARING, {
  "getForm" => proc { |pkmn|
    next 1 if moonphase == 0		# Bloodmoon
    next 0                          # Hisui
  }
})


#===============================================================================
# Regional forms
# This code is for determining the form of a Pokémon in an egg created at the
# Day Care, where that Pokémon's species has regional forms. The regional form
# chosen depends on the region in which the egg was produced (not where it
# hatches).
#===============================================================================

# The code in this proc assumes that the appropriate regional form for a Pokémon
# is equal to the region's number. This may not be true in your game.
# Note that this proc only produces a non-zero form number if the species has a
# defined form with that number, which means it can be used for both Alolan and
# Galarian forms separately (and for Meowth which has both).
MultipleForms.register(:PETILIL, {
  "getFormOnEggCreation" => proc { |pkmn|
    if $game_map
      map_pos = $game_map.metadata&.town_map_position
      next map_pos[0] if map_pos &&
                         GameData::Species.get_species_form(pkmn.species, map_pos[0]).form == 2
    end
    next 0
  }
})

MultipleForms.copy(:DIGLETT,:DEINO,:ZWEILOUS,:HYDREIGON)



