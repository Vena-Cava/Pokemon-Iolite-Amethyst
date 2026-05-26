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
    echoln "#{pkmn.name} was marked as Retired." if $DEBUG

    case nuzlocke_faint_rule
    when :box
      box_retired_pokemon(pkmn)
    when :release
      release_retired_pokemon(pkmn)
    end
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