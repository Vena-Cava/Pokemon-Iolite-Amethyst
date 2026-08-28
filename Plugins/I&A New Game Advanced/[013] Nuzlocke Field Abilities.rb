#===============================================================================
# Nuzlocke - Retired Pokémon Field Ability & Move Blocking
#===============================================================================

module AdvancedNewGame
  def self.ignore_retired_field_abilities?
    return @ignore_retired_field_abilities == true
  end

  def self.retired?(pkmn)
    return false if !pkmn
    return false if !nuzlocke?
    return pkmn.nuzlocke_retired?
  end

  def self.without_retired_field_abilities
    old_value = @ignore_retired_field_abilities
    @ignore_retired_field_abilities = true
    ret = yield
    @ignore_retired_field_abilities = old_value
    return ret
  end
  
  def self.can_use_field_move?(pkmn)
    return false if retired?(pkmn)
    return true
  end
end

class Pokemon
  alias advanced_new_game_field_ability_id ability_id
  alias advanced_new_game_field_hasAbility? hasAbility?

  def ability_id
    if AdvancedNewGame.ignore_retired_field_abilities? &&
       AdvancedNewGame.nuzlocke? &&
       nuzlocke_retired?
      return nil
    end

    return advanced_new_game_field_ability_id
  end

  def hasAbility?(*args)
    if AdvancedNewGame.ignore_retired_field_abilities? &&
       AdvancedNewGame.nuzlocke? &&
       nuzlocke_retired?
      return false
    end

    return advanced_new_game_field_hasAbility?(*args)
  end
end

#===============================================================================
# Fishing abilities
# Sticky Hold / Suction Cups
#===============================================================================

alias advanced_new_game_nuzlocke_pbFishing pbFishing

def pbFishing(*args)
  return AdvancedNewGame.without_retired_field_abilities do
    advanced_new_game_nuzlocke_pbFishing(*args)
  end
end

#===============================================================================
# Wild encounter field abilities
# Stench, White Smoke, Quick Feet, Snow Cloak, Sand Veil,
# Intimidate, Keen Eye, Static, Magnet Pull, Compound Eyes,
# Cute Charm, Synchronize, etc.
#===============================================================================

class PokemonEncounters
  alias advanced_new_game_nuzlocke_encounter_triggered? encounter_triggered?
  alias advanced_new_game_nuzlocke_allow_encounter? allow_encounter?
  alias advanced_new_game_nuzlocke_have_double_wild_battle? have_double_wild_battle?
  alias advanced_new_game_nuzlocke_choose_wild_pokemon choose_wild_pokemon

  def encounter_triggered?(*args)
    return AdvancedNewGame.without_retired_field_abilities do
      advanced_new_game_nuzlocke_encounter_triggered?(*args)
    end
  end

  def allow_encounter?(*args)
    return AdvancedNewGame.without_retired_field_abilities do
      advanced_new_game_nuzlocke_allow_encounter?(*args)
    end
  end

  def have_double_wild_battle?(*args)
    return AdvancedNewGame.without_retired_field_abilities do
      advanced_new_game_nuzlocke_have_double_wild_battle?(*args)
    end
  end

  def choose_wild_pokemon(*args)
    return AdvancedNewGame.without_retired_field_abilities do
      advanced_new_game_nuzlocke_choose_wild_pokemon(*args)
    end
  end
end

#===============================================================================
# Wild Pokémon generation effects
# Compound Eyes, Super Luck, Cute Charm, Synchronize
#===============================================================================

alias advanced_new_game_nuzlocke_pbGenerateWildPokemon pbGenerateWildPokemon

def pbGenerateWildPokemon(*args)
  return AdvancedNewGame.without_retired_field_abilities do
    advanced_new_game_nuzlocke_pbGenerateWildPokemon(*args)
  end
end