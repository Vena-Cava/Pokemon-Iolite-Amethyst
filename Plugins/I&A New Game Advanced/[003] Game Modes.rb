module AdvancedNewGame
  def self.current
    $advanced_new_game ||= DEFAULT_MODES.clone
  end

  def self.enabled?(mode)
    current[mode] == true
  end

  def self.difficulty
    current[:difficulty] || :normal
  end

  def self.start_default_game
    $advanced_new_game = DEFAULT_MODES.clone
    $advanced_new_game_pending = $advanced_new_game
  end

  def self.start_advanced_game
    settings = pbAdvancedNewGameMenu
    return if !settings
    $advanced_new_game = settings
    $advanced_new_game_pending = settings
  end

  def self.difficulty_name(symbol = nil)
    symbol ||= difficulty
    return DIFFICULTIES[symbol][:name]
  end

  def self.difficulty_desc(symbol = nil)
    symbol ||= difficulty
    return DIFFICULTIES[symbol][:desc]
  end

  def self.mode_name(mode)
    return MODES[mode][:name]
  end

  def self.mode_desc(mode)
    return MODES[mode][:desc]
  end

  def self.nuzlocke_option?(option)
    return false if !nuzlocke?
    current[:nuzlocke_options] ||= DEFAULT_MODES[:nuzlocke_options].clone
    return current[:nuzlocke_options][option] == true
  end
  
  def self.nuzlocke_faint_rule
    return current[:nuzlocke_options][:faint_rule] || :box
  end

  def self.nuzlocke_faint_rule_name
    rule = nuzlocke_faint_rule
    return NUZLOCKE_FAINT_RULES[rule][:name]
  end
  
  DIFFICULTY_VALUES = {
    easy: 0,
    normal: 1,
    hard: 2,
    ultra_hard: 3
  }

  FAINT_RULE_VALUES = {
    box: 0,
    release: 1
  }
  
  def self.no_bag_items_battle?
    enabled?(:no_bag_items_battle)
  end

  def self.nuzlocke_pokecenter_limit
    current[:nuzlocke_options] ||= DEFAULT_MODES[:nuzlocke_options].clone
    return current[:nuzlocke_options][:pokecenter_limit] || :infinite
  end

  def self.nuzlocke_pokecenter_limit_value
    key = nuzlocke_pokecenter_limit
    return POKECENTER_LIMITS[key][:value] || -1
  end

  def self.apply_game_settings
    return if !$game_switches || !$game_variables

    $game_switches[SWITCH_INVERSE_MODE]      = enabled?(:inverse)
    $game_switches[SWITCH_NUZLOCKE_MODE]     = enabled?(:nuzlocke)
    $game_switches[SWITCH_LEVEL_CAPS]        = enabled?(:level_caps)
    $game_switches[SWITCH_NO_BAG_ITEMS_BATTLE] = enabled?(:no_bag_items_battle)

    $game_switches[SWITCH_DUPES_CLAUSE]      = nuzlocke_option?(:dupes_clause)
    $game_switches[SWITCH_SHINY_CLAUSE]      = nuzlocke_option?(:shiny_clause)
    $game_switches[SWITCH_NICKNAME_CLAUSE]   = nuzlocke_option?(:nickname_clause)
    $game_switches[SWITCH_WIPE_DELETES_SAVE] = nuzlocke_option?(:wipe_deletes_save)

    $game_variables[VARIABLE_DIFFICULTY] = DIFFICULTY_VALUES[difficulty] || 1
    $game_variables[VARIABLE_FAINT_RULE] = FAINT_RULE_VALUES[nuzlocke_faint_rule] || 0
    $game_variables[VARIABLE_POKECENTER_LIMIT] = nuzlocke_pokecenter_limit_value

    if enabled?(:level_caps)
      $game_variables[VARIABLE_NEXT_BOSS] ||= 0
      if enabled?(:level_caps)
        cap = AdvancedNewGame::BOSS_LEVEL_CAPS[:none] || 100
        $game_variables[VARIABLE_LEVEL_CAP] = cap
      else
        $game_variables[VARIABLE_LEVEL_CAP] = 100
      end
    else
      $game_variables[VARIABLE_LEVEL_CAP] = 100
    end
    echoln "Advanced New Game settings applied." if $DEBUG
  end
end