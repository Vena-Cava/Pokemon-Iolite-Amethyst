#===============================================================================
# Nuzlocke - Retired Pokémon
#===============================================================================

class Pokemon
  attr_accessor :nuzlocke_retired

  def nuzlocke_retired?
    return @nuzlocke_retired == true
  end
end

module AdvancedNewGame
  def self.nuzlocke?
    enabled?(:nuzlocke)
  end

  def self.retire_pokemon(pkmn)
    return if !nuzlocke? || !nuzlocke_started?
    return if !pkmn
    return if pkmn.nuzlocke_retired?

    pkmn.nuzlocke_retired = true
    increment_retired_count
    echoln "#{pkmn.name} was marked as Retired." if $DEBUG

    case nuzlocke_faint_rule
    when :box
      box_retired_pokemon(pkmn)
    when :release
      release_retired_pokemon(pkmn)
    end
  end

  def self.manually_retire_pokemon(pkmn)
    return false if !pkmn
    return false if pkmn.egg?
    return false if pkmn.nuzlocke_retired?

    return false if !pbConfirmMessage(_INTL("Retire {1}?", pkmn.name))
    return false if !pbConfirmMessage(_INTL("This cannot be undone. Retire this Pokémon?"))

    retire_pokemon(pkmn)
    pbMessage(_INTL("{1} was marked as Retired.", pkmn.name))
    return true
  end

  def self.pokemon_usable?(pkmn)
    return false if !pkmn
    return false if pkmn.nuzlocke_retired?
    return true
  end
  
  
  def self.pokemon_can_affect_field?(pkmn)
    return false if nuzlocke? && pkmn&.nuzlocke_retired?
    return true
  end
  
  def self.encounter_rules_active?
    return nuzlocke? && nuzlocke_started?
  end
  
  def self.nuzlocke_started?
    return false if !$game_switches
    return $game_switches[SWITCH_NUZLOCKE_STARTED]
  end

  def self.start_nuzlocke_rules
    return if !nuzlocke?
    $game_switches[SWITCH_NUZLOCKE_STARTED] = true
    pbMessage(_INTL("Nuzlocke rules are now active!"))
  end
  
  def self.retired_count
    return $PokemonGlobal&.instance_variable_get(:@advanced_new_game_retired_count) || 0
  end

  def self.increment_retired_count
    $PokemonGlobal.instance_variable_set(:@advanced_new_game_retired_count, retired_count + 1)
  end
  
  def self.nickname_already_used?(name)
    return false if !$player
    return false if !name

    check = name.strip.downcase
    return false if check.empty?

    # Party
    $player.party.each do |pkmn|
      next if !pkmn
      next if pkmn.egg?
      return true if pkmn.name.strip.downcase == check
    end

    # Storage
    $PokemonStorage.maxBoxes.times do |box|
      $PokemonStorage[box].each do |pkmn|
        next if !pkmn
        next if pkmn.egg?
        return true if pkmn.name.strip.downcase == check
      end
    end

    return false
  end
  
  def self.evolution_family_names(species)
    blocked = []
    queue = [species]
    checked = []

    while queue.length > 0
      current = queue.shift
      next if checked.include?(current)
      checked.push(current)

      data = GameData::Species.get(current)
      blocked.push(data.name.downcase)

      # Forward evolutions
      data.get_evolutions.each do |evo|
        queue.push(evo[0])
      end

      # Pre-evolutions / related family members
      GameData::Species.each do |other|
        other.get_evolutions.each do |evo|
          queue.push(other.species) if evo[0] == current
        end
      end
    end

    return blocked.uniq
  end
  
  def self.box_retired_pokemon(pkmn)
    return if !$player || !$PokemonStorage

    # Do not box if this is the player's only usable Pokémon.
    usable_count = $player.party.count { |p| p && !p.nuzlocke_retired? && p.able? }
    return if usable_count <= 0

    if $player.party.include?(pkmn)
      $player.party.delete(pkmn)

      if $PokemonStorage.pbStoreCaught(pkmn)
        pbMessage(_INTL("{1} was sent to a Retired Box.", pkmn.name))
      else
        pbMessage(_INTL("{1} is Retired, but there was no room in the Boxes.", pkmn.name))
        $player.party.push(pkmn)
      end
    end
  end

  def self.release_retired_pokemon(pkmn)
    return if !$player

    # Do not release if this is the player's only usable Pokémon.
    usable_count = $player.party.count { |p| p && !p.nuzlocke_retired? && p.able? }
    return if usable_count <= 0

    if $player.party.include?(pkmn)
      $player.party.delete(pkmn)
      pbMessage(_INTL("{1} was retired from your team.", pkmn.name))
    end
  end
  
  def self.nickname_clause?
    return nuzlocke_option?(:nickname_clause)
  end
  
#===============================================================================
# Nuzlocke - Delete Save File if Battle Lost
#===============================================================================
  
  def self.lose_condition
    value = $game_variables[VARIABLE_LOSE_CONDITION] rescue nil

    case value
    when 0 then return :whiteout
    when 1 then return :full_wipe
    when :whiteout, :full_wipe then return value
    end

    return :whiteout
  end

  def self.lose_result
    value = $game_variables[VARIABLE_LOSE_RESULT] rescue nil

    case value
    when 0 then return :centre
    when 1 then return :reload
    when 2 then return :disable
    when 3 then return :delete
    when :centre, :reload, :disable, :delete then return value
    end

    return :disable
  end

  def self.usable_nuzlocke_pokemon_count
    count = 0

    $player.party.each do |pkmn|
      next if !pkmn || pkmn.egg?
      next if pkmn.nuzlocke_retired?
      count += 1
    end

    $PokemonStorage.maxBoxes.times do |box|
      $PokemonStorage[box].each do |pkmn|
        next if !pkmn || pkmn.egg?
        next if pkmn.nuzlocke_retired?
        count += 1
      end
    end

    return count
  end

  def self.nuzlocke_run_lost_after_battle?
    return false if !nuzlocke?
    return false if !nuzlocke_started?

    case lose_condition
    when :whiteout
      return true
    when :full_wipe
      return usable_nuzlocke_pokemon_count <= 0
    end

    return false
  end
  
  def self.loss_intro_message
    case lose_condition
    when :whiteout
      return _INTL("You lost the battle.")
    when :full_wipe
      return _INTL("All of your Pokémon have been retired.")
    end
    return _INTL("Your challenge has ended.")
  end

  def self.loss_end_message
    case lose_condition
    when :whiteout
      return _INTL("Your run has ended in a Whiteout.")
    when :full_wipe
      return _INTL("Your run has ended in a Full Wipe.")
    end
    return _INTL("Your run has ended.")
  end
  
  def self.party_has_usable_nuzlocke_pokemon?
    return false if !$player

    $player.party.each do |pkmn|
      next if !pkmn || pkmn.egg?
      next if pkmn.respond_to?(:nuzlocke_retired?) && pkmn.nuzlocke_retired?
      return true
    end

    return false
  end

  def self.force_pc_rebuild_after_whiteout
    if $PokemonGlobal.pokecenterMapId && $PokemonGlobal.pokecenterMapId >= 0
      map_id = $PokemonGlobal.pokecenterMapId
      x      = $PokemonGlobal.pokecenterX
      y      = $PokemonGlobal.pokecenterY
      dir    = $PokemonGlobal.pokecenterDirection
    else
      home = GameData::PlayerMetadata.get($player.character_ID)&.home
      home = GameData::Metadata.get.home if !home

      map_id = home[0]
      x      = home[1]
      y      = home[2]
      dir    = home[3]
    end

    $player.heal_party
    pbCancelVehicles
    Followers.clear
    $game_switches[Settings::STARTING_OVER_SWITCH] = true

    $game_temp.player_new_map_id    = map_id
    $game_temp.player_new_x         = x
    $game_temp.player_new_y         = y
    $game_temp.player_new_direction = dir
    $game_temp.player_transferring  = true

    $scene.transfer_player if $scene.is_a?(Scene_Map)
    $game_map.refresh

    pbMessage(_INTL("You still have usable Pokémon in storage."))
    pbMessage(_INTL("Withdraw at least one Pokémon to continue."))

    loop do
      scene = PokemonStorageScene.new
      screen = PokemonStorageScreen.new(scene, $PokemonStorage)
      screen.pbStartScreen(0)

      break if party_has_usable_nuzlocke_pokemon?

      pbMessage(_INTL("You need at least one non-retired Pokémon in your party."))
    end
  end
  
  def self.handle_nuzlocke_loss
    echoln "HANDLE LOSS CALLED" if $DEBUG
    echoln "HANDLE RESULT = #{lose_result.inspect}" if $DEBUG
    return if !nuzlocke_run_lost_after_battle?

    case lose_result
    when :centre
      return

    when :reload
      pbMessage(loss_intro_message)
      pbMessage(_INTL("Reloading your last save."))

      AdvancedNewGame.instance_variable_set(
        :@advanced_new_game_auto_reload_slot,
        current_save_slot
      )

      $game_temp.instance_variable_set(
        :@advanced_new_game_return_to_title,
        true
      )

      return

      when :disable
        pbMessage(loss_end_message)
        pbMessage(_INTL("This save file has been marked as failed."))

        $PokemonGlobal.instance_variable_set(
          :@advanced_new_game_run_state,
          :failed
        )

        echoln "DISABLE: marking run failed" if $DEBUG
        Game.save

        $game_temp.instance_variable_set(
          :@advanced_new_game_return_to_title,
          true
        )

        return

    when :delete
      slot = current_save_slot

      pbMessage(loss_end_message)
      pbMessage(_INTL("Deleting Save Slot {1}.", slot))
      pbMessage(_INTL("Don't turn off the power.") + "\\wtnp[0]")

      delete_save_slot(slot)

      pbMessage(_INTL("Save Slot {1} was deleted.", slot))

      $game_temp.instance_variable_set(:@advanced_new_game_return_to_title, true)
      return
    end
  end

  def self.nuzlocke_loss_rules_active?
    return nuzlocke? && nuzlocke_started?
  end
end

#===============================================================================
# Mark player's fainted Pokémon as Retired
#===============================================================================

class Battle::Battler
  alias advanced_new_game_nuzlocke_pbFaint pbFaint

  def pbFaint(showMessage = true)
    advanced_new_game_nuzlocke_pbFaint(showMessage)

    return if !AdvancedNewGame.nuzlocke?
    return if !pbOwnedByPlayer?
    return if !@pokemon
    return if @battle.wildBattle? && !@battle.internalBattle

    AdvancedNewGame.retire_pokemon(@pokemon)
  end
end

#===============================================================================
# Debug - Toggle Retired Status
#===============================================================================

MenuHandlers.add(:pokemon_debug_menu, :toggle_retired_status, {
  "name"   => _INTL("Toggle Retired Status"),
  "parent" => :main,
  "effect" => proc { |pkmn, _scene|
    pkmn.nuzlocke_retired = !pkmn.nuzlocke_retired?

    if pkmn.nuzlocke_retired?
      pbMessage(_INTL("{1} is now Retired.", pkmn.name))
    else
      pbMessage(_INTL("{1} is no longer Retired.", pkmn.name))
    end

    next false
  }
})

#===============================================================================
# Debug - Toggle Nuzlocke Rules Started
#===============================================================================

MenuHandlers.add(:debug_menu, :advanced_new_game_toggle_nuzlocke_started, {
  "name"        => _INTL("Toggle Nuzlocke Started"),
  "parent"      => :main,
  "description" => _INTL("Turns active Nuzlocke rules on/off."),
  "effect"      => proc {
    if !$game_switches
      pbMessage(_INTL("Game switches are not available."))
      next false
    end

    $game_switches[AdvancedNewGame::SWITCH_NUZLOCKE_STARTED] =
      !$game_switches[AdvancedNewGame::SWITCH_NUZLOCKE_STARTED]

    if $game_switches[AdvancedNewGame::SWITCH_NUZLOCKE_STARTED]
      pbMessage(_INTL("Nuzlocke rules are now active."))
    else
      pbMessage(_INTL("Nuzlocke rules are now inactive."))
    end

    next false
  }
})

#===============================================================================
# Nuzlocke - Prevent Retired Pokémon from battling
#===============================================================================

class Battle
  alias advanced_new_game_nuzlocke_pbCanChooseNonActive? pbCanChooseNonActive?

  def pbCanChooseNonActive?(idxBattler)
    ret = advanced_new_game_nuzlocke_pbCanChooseNonActive?(idxBattler)
    return ret if !ret

    party_index = @battlers[idxBattler].pokemonIndex
    pkmn = pbParty(idxBattler)[party_index] rescue nil

    if pkmn && pkmn.nuzlocke_retired?
      return false
    end

    return ret
  end
  
#  alias advanced_new_game_nuzlocke_pbEndOfBattle pbEndOfBattle

#  def pbEndOfBattle
#    if @decision == 2 || @decision == 5
#      AdvancedNewGame.handle_nuzlocke_loss
#    end

#    return advanced_new_game_nuzlocke_pbEndOfBattle
#  end
end

class Pokemon
  alias advanced_new_game_nuzlocke_able? able?

  def able?
    return false if AdvancedNewGame.nuzlocke? && nuzlocke_retired?
    return advanced_new_game_nuzlocke_able?
  end
end

#===============================================================================
# Nuzlocke - Prevent Retired Pokémon from rejoining the party
#===============================================================================

class PokemonStorageScreen
  alias advanced_new_game_nuzlocke_pbAble? pbAble?
  alias advanced_new_game_nuzlocke_pbWithdraw pbWithdraw
  alias advanced_new_game_nuzlocke_pbPlace pbPlace
  alias advanced_new_game_nuzlocke_pbSwap pbSwap

  def pbAble?(pokemon)
    return false if pokemon && pokemon.nuzlocke_retired?
    return advanced_new_game_nuzlocke_pbAble?(pokemon)
  end

  def pbWithdraw(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    pokemon = heldpoke || @storage[box, index]

    if AdvancedNewGame.nuzlocke? &&
       pokemon &&
       pokemon.nuzlocke_retired?
      pbPlayBuzzerSE
      pbDisplay(_INTL("{1} is Retired and cannot rejoin your party.", pokemon.name))
      return false
    end

    return advanced_new_game_nuzlocke_pbWithdraw(selected, heldpoke)
  end

  def pbPlace(selected)
    box = selected[0]

    if box == -1 &&
       AdvancedNewGame.nuzlocke? &&
       @heldpkmn &&
       @heldpkmn.nuzlocke_retired?
      pbPlayBuzzerSE
      pbDisplay(_INTL("{1} is Retired and cannot rejoin your party.", @heldpkmn.name))
      return false
    end

    return advanced_new_game_nuzlocke_pbPlace(selected)
  end

  def pbSwap(selected)
    box = selected[0]

    if box == -1 &&
       AdvancedNewGame.nuzlocke? &&
       @heldpkmn &&
       @heldpkmn.nuzlocke_retired?
      pbPlayBuzzerSE
      pbDisplay(_INTL("{1} is Retired and cannot rejoin your party.", @heldpkmn.name))
      return false
    end

    return advanced_new_game_nuzlocke_pbSwap(selected)
  end
end

#===============================================================================
# Skip whiteout when Wipe Deletes Save triggers
#===============================================================================

alias advanced_new_game_nuzlocke_pbStartOver pbStartOver

def pbStartOver(*args)
  echoln "PBSTARTOVER NUZLOCKE = #{AdvancedNewGame.nuzlocke?.inspect}" if $DEBUG
  echoln "PBSTARTOVER STARTED = #{AdvancedNewGame.nuzlocke_started?.inspect}" if $DEBUG
  echoln "PBSTARTOVER CONDITION = #{AdvancedNewGame.lose_condition.inspect}" if $DEBUG
  echoln "PBSTARTOVER RESULT = #{AdvancedNewGame.lose_result.inspect}" if $DEBUG

  if AdvancedNewGame.nuzlocke? && AdvancedNewGame.nuzlocke_started?
    condition = AdvancedNewGame.lose_condition

    if condition == :full_wipe
      if AdvancedNewGame.usable_nuzlocke_pokemon_count <= 0
        AdvancedNewGame.handle_nuzlocke_loss
      else
        AdvancedNewGame.force_pc_rebuild_after_whiteout
        return
      end
    else
      # Treat anything else as Whiteout.
      AdvancedNewGame.handle_nuzlocke_loss
    end

    if $game_temp.instance_variable_get(:@advanced_new_game_return_to_title)
      $game_temp.instance_variable_set(:@advanced_new_game_return_to_title, false)
      Graphics.freeze
      $scene = pbCallTitle
      return
    end
  end

  advanced_new_game_nuzlocke_pbStartOver(*args)
end