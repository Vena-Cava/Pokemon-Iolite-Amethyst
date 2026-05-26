module AdvancedNewGame
  MAX_SAVE_SLOTS = 3
  
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
  
  def self.save_slot_copy_locked?(metadata)
    return false if $DEBUG && Input.press?(Input::CTRL)
    return false if !metadata

    settings = metadata[:advanced_new_game_settings]
    return false if !settings

    return true if settings[:nuzlocke]
    return true if settings[:difficulty] == :ultra_hard || settings[:difficulty] == 3

    return false
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
  end 

  def self.slot_range
    return 1..MAX_SAVE_SLOTS
  end

  def self.load_slot_metadata(slot)
    return nil if !save_slot_exists?(slot)

    begin
      save_data = SaveData.read_from_file(save_slot_path(slot))
      trainer = save_data[:player]
      stats   = save_data[:stats]
      map_id  = save_data[:map_factory]&.map&.map_id rescue nil
      party   = trainer&.party || []
      charset = trainer&.character_ID rescue nil
      gender  = trainer&.gender rescue nil
      character_ID = trainer&.character_ID rescue nil
      pokemon_global = save_data[:pokemon_global] rescue nil
      advanced_settings = pokemon_global&.instance_variable_get(:@advanced_new_game_settings) rescue nil

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
        advanced_new_game_settings: advanced_settings
      }
    rescue
      return {
        slot: slot,
        corrupted: true
      }
    end
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
          inverse: $game_switches[AdvancedNewGame::SWITCH_INVERSE_MODE],
          level_caps: $game_switches[AdvancedNewGame::SWITCH_LEVEL_CAPS],
          no_bag_items_battle: $game_switches[AdvancedNewGame::SWITCH_NO_BAG_ITEMS_BATTLE],
          nuzlocke_options: {
            faint_rule: $game_variables[AdvancedNewGame::VARIABLE_FAINT_RULE],
            dupes_clause: $game_switches[AdvancedNewGame::SWITCH_DUPES_CLAUSE],
            shiny_clause: $game_switches[AdvancedNewGame::SWITCH_SHINY_CLAUSE],
            nickname_clause: $game_switches[AdvancedNewGame::SWITCH_NICKNAME_CLAUSE],
            wipe_deletes_save: $game_switches[AdvancedNewGame::SWITCH_WIPE_DELETES_SAVE],
            pokecenter_limit: $game_variables[AdvancedNewGame::VARIABLE_POKECENTER_LIMIT]
          }
        }

        $PokemonGlobal.instance_variable_set(:@advanced_new_game_settings, settings)
      end

      return advanced_new_game_original_save(save_file, safe: safe)
    end
  end
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