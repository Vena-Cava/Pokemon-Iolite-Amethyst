module AdvancedNewGame
  MAX_SAVE_SLOTS = 99
  
  def self.save_directory
    return File.directory?(System.data_directory) ? System.data_directory : "."
  end

  def self.save_slot_path(slot)
    return sprintf("%s/Game_%03d.rxdata", save_directory, slot)
  end

  def self.save_slot_backup_path(slot)
    return save_slot_path(slot) + ".bak"
  end

  def self.save_slot_exists?(slot)
    return File.file?(save_slot_path(slot))
  end
  
  def self.save_slot_names
    return @save_slot_names ||= {}
  end

  def self.save_slot_name(slot)
    return save_slot_names[slot] || _INTL("Slot {1}", slot)
  end

  def self.rename_save_slot(slot, name)
    name = name.strip rescue ""
    name = _INTL("Slot {1}", slot) if name.empty?
    save_slot_names[slot] = name
  end
  
  def self.save_slot_copy_locked?(metadata)
    return false if $DEBUG && Input.press?(Input::CTRL)
    return false if !metadata

    settings = metadata[:advanced_new_game_settings]
    return false if !settings

    return true if settings[:nuzlocke]
    return true if settings[:difficulty] == :ultra_hard
    return true if settings[:prof_oak_challenge]

    return false
  end
  
  def self.can_open_failed_save?
    return $DEBUG && Input.press?(Input::CTRL)
  end

  def self.current_save_slot
    return @current_save_slot || 1
  end

  def self.current_save_slot=(slot)
    @current_save_slot = slot
  end

  def self.delete_save_slot(slot)
    path = save_slot_path(slot)
    backup = save_slot_backup_path(slot)

    File.delete(path) if File.file?(path)
    File.delete(backup) if File.file?(backup)
    save_slot_names.delete(slot)

    File.open(save_slot_names_path, "wb") do |f|
      Marshal.dump(save_slot_names, f)
    end
  end 

  def self.slot_range
    return 1..MAX_SAVE_SLOTS
  end
  
  def self.save_slot_names_path
    return sprintf("%s/SaveSlotNames.rxdata", save_directory)
  end

  def self.load_save_slot_names
    if File.file?(save_slot_names_path)
      @save_slot_names = File.open(save_slot_names_path, "rb") { |f| Marshal.load(f) }
    else
      @save_slot_names = {}
    end
  end

  def self.save_slot_names
    load_save_slot_names if !@save_slot_names
    return @save_slot_names
  end

  def self.save_slot_name(slot)
    return save_slot_names[slot] || _INTL("Slot {1}", slot)
  end

  def self.rename_save_slot(slot, name)
    name = name.strip rescue ""
    name = _INTL("Slot {1}", slot) if name.empty?

    save_slot_names[slot] = name

    File.open(save_slot_names_path, "wb") do |f|
      Marshal.dump(save_slot_names, f)
    end
  end

  def self.load_slot_metadata(slot)
    return nil if !save_slot_exists?(slot)

    begin
      save_data = SaveData.read_from_file(save_slot_path(slot))
      stars = save_data[:advanced_new_game_stars] || 0
      trainer = save_data[:player]
      stats   = save_data[:stats]
      map_id  = save_data[:map_factory]&.map&.map_id rescue nil
      party   = trainer&.party || []
      charset = trainer&.character_ID rescue nil
      gender  = trainer&.gender rescue nil
      character_ID = trainer&.character_ID rescue nil
      advanced_settings = save_data[:advanced_new_game] rescue nil
      pokemon_global = save_data[:pokemon_global] rescue nil
      retired_count = save_data[:advanced_new_game_retired_count] || 0
      slot_names = pokemon_global&.instance_variable_get(:@advanced_new_game_save_slot_names) || {}
      slot_name = AdvancedNewGame.save_slot_name(slot)
      run_state = save_data[:advanced_new_game_run_state] || :active

      return {
        slot: slot,
        player_name: trainer&.name || "Player",
        play_time: stats&.play_time || 0,
        badges: trainer&.badge_count || 0,
        map_id: map_id,
        party: party,
        charset: charset,
        gender: gender,
        character_ID: character_ID,
        advanced_new_game_settings: advanced_settings,
        stars: stars,
        slot_name: slot_name,
        run_state: run_state,
        retired_count: retired_count
      }
    rescue
      return {
        slot: slot,
        corrupted: true
      }
    end
  end
  
  def self.auto_reload_path
    return sprintf("%s/AutoReloadSlot.rxdata", save_directory)
  end

  def self.queue_auto_reload_slot(slot)
    File.open(auto_reload_path, "wb") { |f| Marshal.dump(slot, f) }
  end

  def self.consume_auto_reload_slot
    return nil if !File.file?(auto_reload_path)

    slot = File.open(auto_reload_path, "rb") { |f| Marshal.load(f) }
    File.delete(auto_reload_path) if File.file?(auto_reload_path)

    return slot
  rescue
    File.delete(auto_reload_path) if File.file?(auto_reload_path)
    return nil
  end
end

module SaveData
  class << self
    alias advanced_new_game_original_exists? exists?
    alias advanced_new_game_original_delete_file delete_file

    def exists?
      return File.file?(AdvancedNewGame.save_slot_path(AdvancedNewGame.current_save_slot))
    end

    def delete_file
      AdvancedNewGame.delete_save_slot(AdvancedNewGame.current_save_slot)
    end
  end
end

module Game
  class << self
    alias advanced_new_game_original_save save

    def save(save_file = nil, safe: false)
      save_file = AdvancedNewGame.save_slot_path(AdvancedNewGame.current_save_slot) if !save_file

      if $PokemonGlobal && $game_switches && $game_variables
        settings = {
          difficulty: $game_variables[AdvancedNewGame::VARIABLE_DIFFICULTY],
          nuzlocke: $game_switches[AdvancedNewGame::SWITCH_NUZLOCKE_MODE],
          prof_oak_challenge: $game_switches[AdvancedNewGame::SWITCH_PROF_OAK_CHALLENGE],
          inverse: $game_switches[AdvancedNewGame::SWITCH_INVERSE_MODE],
          level_caps: $game_switches[AdvancedNewGame::SWITCH_LEVEL_CAPS],
          no_bag_items_battle: $game_switches[AdvancedNewGame::SWITCH_NO_BAG_ITEMS_BATTLE],
          nuzlocke_options: {
            faint_rule: $game_variables[AdvancedNewGame::VARIABLE_FAINT_RULE],
            dupes_clause: $game_switches[AdvancedNewGame::SWITCH_DUPES_CLAUSE],
            shiny_clause: $game_switches[AdvancedNewGame::SWITCH_SHINY_CLAUSE],
            nickname_clause: $game_switches[AdvancedNewGame::SWITCH_NICKNAME_CLAUSE],
            hm_clause: $game_switches[AdvancedNewGame::SWITCH_HM_CLAUSE],
            lose_condition: $game_variables[AdvancedNewGame::VARIABLE_LOSE_CONDITION],
            lose_result: $game_variables[AdvancedNewGame::VARIABLE_LOSE_RESULT],
            pokecenter_limit: $game_variables[AdvancedNewGame::VARIABLE_POKECENTER_LIMIT]
          }
        }

        echoln settings.inspect if $DEBUG
        $PokemonGlobal.instance_variable_set(:@advanced_new_game_settings, settings)
        
        $PokemonGlobal.instance_variable_set(
          :@advanced_new_game_save_slot_names,
          AdvancedNewGame.save_slot_names
        )
      end

      return advanced_new_game_original_save(save_file, safe: safe)
    end
  end
end

SaveData.register(:advanced_new_game_stars) do
  save_value {
    next $PokemonGlobal&.instance_variable_get(:@advanced_new_game_stars) || 0
  }

  load_value { |value|
    $PokemonGlobal.instance_variable_set(:@advanced_new_game_stars, value || 0)
  }

  new_game_value {
    next 0
  }
end

SaveData.register(:advanced_new_game_retired_count) do
  save_value {
    next $PokemonGlobal&.instance_variable_get(:@advanced_new_game_retired_count) || 0
  }

  load_value { |value|
    $PokemonGlobal.instance_variable_set(:@advanced_new_game_retired_count, value || 0)
  }

  new_game_value {
    next 0
  }
end 

#===============================================================================
# Debug - Change Current Save Slot
#===============================================================================

MenuHandlers.add(:debug_menu, :advanced_new_game_change_save_slot, {
  "name"        => _INTL("Change Current Save Slot"),
  "parent"      => :main,
  "description" => _INTL("Choose which save slot the game saves to."),
  "effect"      => proc {
    commands = []

    AdvancedNewGame.slot_range.each do |slot|
      label = _INTL("Slot {1}", slot)
      label += _INTL(" (Current)") if slot == AdvancedNewGame.current_save_slot
      label += AdvancedNewGame.save_slot_exists?(slot) ? _INTL(" - Used") : _INTL(" - Empty")
      commands.push(label)
    end

    choice = pbMessage(
      _INTL("Choose a save slot."),
      commands,
      AdvancedNewGame.current_save_slot - 1
    )

    if choice >= 0
      AdvancedNewGame.current_save_slot = choice + 1
      pbMessage(_INTL("Current save slot is now Slot {1}.", choice + 1))
    end

    next false
  }
})

#===============================================================================
# Debug - Change the number of Stars the player has.
#===============================================================================
MenuHandlers.add(:debug_menu, :advanced_new_game_set_stars, {
  "name"        => _INTL("Set Save Stars"),
  "parent"      => :main,
  "description" => _INTL("Sets the number of stars for the current save."),
  "effect"      => proc {
    current = $PokemonGlobal.instance_variable_get(:@advanced_new_game_stars) || 0
    params = ChooseNumberParams.new
    params.setRange(0, 99)
    params.setDefaultValue(current)

    value = pbMessageChooseNumber(
      _INTL("Set number of Stars."),
      params
    )

    $PokemonGlobal.instance_variable_set(:@advanced_new_game_stars, value)
    pbMessage(_INTL("Star count set to {1}.", value))

    next false
  }
})

SaveData.register(:advanced_new_game_run_state) do
  save_value {
    next $PokemonGlobal&.instance_variable_get(:@advanced_new_game_run_state) || :active
  }

  load_value { |value|
    $PokemonGlobal.instance_variable_set(:@advanced_new_game_run_state, value || :active)
  }

  new_game_value {
    next :active
  }
end