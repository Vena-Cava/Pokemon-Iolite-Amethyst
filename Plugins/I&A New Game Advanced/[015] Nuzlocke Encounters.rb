#===============================================================================
# Nuzlocke - Encounter Tracking
#===============================================================================

module AdvancedNewGame
  def self.nuzlocke_encounters
    $PokemonGlobal.instance_variable_get(:@advanced_new_game_nuzlocke_encounters) || {}
  end

  def self.set_nuzlocke_encounters(value)
    $PokemonGlobal.instance_variable_set(:@advanced_new_game_nuzlocke_encounters, value)
  end

  def self.nuzlocke_area_key
    # Uses the map's displayed name, so multiple floors of the same cave count
    # as one area if they share a name.
    return pbGetMapNameFromId($game_map.map_id)
  end

  def self.encounter_record_for_area(area = nil)
    area ||= nuzlocke_area_key
    return nuzlocke_encounters[area]
  end

  def self.area_encounter_used?(area = nil)
    return !encounter_record_for_area(area).nil?
  end

  def self.record_first_encounter(pkmn_or_species)
    return if !nuzlocke? || !nuzlocke_started?

    area = nuzlocke_area_key
    return if area_encounter_used?(area)

    species = pkmn_or_species
    species = pkmn_or_species.species if pkmn_or_species.respond_to?(:species)
    species = species[0] if species.is_a?(Array)

    #-----------------------------------------------------------------------------
    # Dupes Clause
    #-----------------------------------------------------------------------------
    if dupes_clause? && owned_evolution_family?(species)
      echoln "NUZLOCKE DUPE ENCOUNTER: #{species}" if $DEBUG
      return
    end
    
    if nuzlocke_option?(:shiny_clause) &&
       pkmn_or_species.respond_to?(:shiny?) &&
       pkmn_or_species.shiny?
      echoln "NUZLOCKE SHINY BONUS ENCOUNTER: #{species}" if $DEBUG
      return
    end

    data = nuzlocke_encounters

    data[area] = {
      species: species,
      caught: false,
      failed: false
    }

    set_nuzlocke_encounters(data)

    echoln "NUZLOCKE FIRST ENCOUNTER: #{area} - #{species}" if $DEBUG
  end

  def self.encounter_species_for_area(area = nil)
    record = encounter_record_for_area(area)
    return nil if !record
    return record[:species]
  end

  def self.can_catch_nuzlocke_encounter?(pkmn)
    return true if !encounter_rules_active?
    return true if !pkmn
    
      

    # Shiny Clause overrides everything.
    return true if nuzlocke_option?(:shiny_clause) && pkmn.shiny?
    echoln "NUZLOCKE CATCH CHECK" if $DEBUG
    echoln "Area: #{nuzlocke_area_key}" if $DEBUG
    echoln "Record: #{encounter_record_for_area.inspect}" if $DEBUG
    echoln "Trying to catch: #{pkmn.species}" if $DEBUG

    record = encounter_record_for_area
    return true if !record

    return false if record[:caught]
    return false if record[:failed]

    return pkmn.species == record[:species]
  end

  def self.mark_area_encounter_caught
    area = nuzlocke_area_key
    data = nuzlocke_encounters
    return if !data[area]

    data[area][:caught] = true
    set_nuzlocke_encounters(data)
  end

  def self.mark_area_encounter_failed
    area = nuzlocke_area_key
    data = nuzlocke_encounters
    return if !data[area]

    data[area][:failed] = true
    set_nuzlocke_encounters(data)
  end
  
  def self.current_battle_catch_allowed?(battle)
    return true if !encounter_rules_active?

    battler = battle.battlers.find { |b| b && b.opposes?(0) && !b.fainted? }
    pkmn = battler&.pokemon
    return true if !pkmn

    return can_catch_nuzlocke_encounter?(pkmn)
  end
  
  def self.dupes_clause?
    return nuzlocke_option?(:dupes_clause)
  end

  def self.owned_evolution_family?(species)
    family = evolution_family_names(species)

    $player.party.each do |pkmn|
      next if !pkmn || pkmn.egg?
      return true if family.include?(pkmn.speciesName.downcase)
    end

    $PokemonStorage.maxBoxes.times do |box|
      $PokemonStorage[box].each do |pkmn|
        next if !pkmn || pkmn.egg?
        return true if family.include?(pkmn.speciesName.downcase)
      end
    end

    return false
  end

  def self.dupes_encounter?(pkmn_or_species)
    return false if !encounter_rules_active?
    return false if !dupes_clause?

    species = pkmn_or_species
    species = species.species if species.respond_to?(:species)
    species = species[0] if species.is_a?(Array)

    return owned_evolution_family?(species)
  end
  
  def self.force_record_encounter(pkmn_or_species)
    return if !nuzlocke? || !nuzlocke_started?

    area = nuzlocke_area_key
    return if area_encounter_used?(area)

    species = pkmn_or_species
    species = pkmn_or_species.species if pkmn_or_species.respond_to?(:species)
    species = species[0] if species.is_a?(Array)

    data = nuzlocke_encounters

    data[area] = {
      species: species,
      caught: false,
      failed: false
    }

    set_nuzlocke_encounters(data)

    echoln "NUZLOCKE FORCED ENCOUNTER: #{area} - #{species}" if $DEBUG
  end
end

#===============================================================================
# Record first wild encounter for each area
#===============================================================================

class << WildBattle
  alias advanced_new_game_nuzlocke_start start

  def start(*args, **kwargs)
    if AdvancedNewGame.encounter_rules_active?
      first_pokemon = args[0]

      if first_pokemon && !AdvancedNewGame.dupes_encounter?(first_pokemon)
        AdvancedNewGame.record_first_encounter(first_pokemon)
      end
    end

    return advanced_new_game_nuzlocke_start(*args, **kwargs)
  end
end


#===============================================================================
# Prevent catching non-first encounters
#===============================================================================

class Battle
  alias advanced_new_game_nuzlocke_pbThrowPokeBall pbThrowPokeBall

  def pbThrowPokeBall(idxBattler, ball, catch_rate = nil, showPlayer = false)
    battler = @battlers[idxBattler]
    pkmn = battler&.pokemon

    old_caught_count = @caughtPokemon.length rescue 0

    advanced_new_game_nuzlocke_pbThrowPokeBall(
      idxBattler,
      ball,
      catch_rate,
      showPlayer
    )

    new_caught_count = @caughtPokemon.length rescue 0

    if AdvancedNewGame.encounter_rules_active? && pkmn
      shiny_clause_catch = AdvancedNewGame.nuzlocke_option?(:shiny_clause) && pkmn.shiny?

      if new_caught_count > old_caught_count
        if !shiny_clause_catch
          AdvancedNewGame.force_record_encounter(pkmn) if !AdvancedNewGame.area_encounter_used?
          AdvancedNewGame.mark_area_encounter_caught
        end

        echoln "NUZLOCKE ENCOUNTER CAUGHT" if $DEBUG
      else
        if AdvancedNewGame.encounter_species_for_area == pkmn.species
          AdvancedNewGame.mark_area_encounter_failed
          echoln "NUZLOCKE ENCOUNTER FAILED" if $DEBUG
        end
      end
    end
  end
end