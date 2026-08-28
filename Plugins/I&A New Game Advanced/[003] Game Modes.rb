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
  
  def self.valid_advanced_settings?(settings)
    if settings[:nuzlocke] && settings[:prof_oak_challenge]
      pbMessage(_INTL(
        "Nuzlocke Mode and Prof. Oak's Challenge are mutually exclusive and cannot be used together."
      ))
      return false
    end
    
    if settings[:level_caps] && settings[:prof_oak_challenge]
      pbMessage(_INTL(
        "Level Caps Mode and Prof. Oak's Challenge are mutually exclusive and cannot be used together."
      ))
      return false
    end

    return true
  end
  
  def self.last_advanced_settings
    return @last_advanced_settings || DEFAULT_MODES.clone
  end

  def self.last_advanced_settings=(settings)
    @last_advanced_settings = Marshal.load(Marshal.dump(settings))
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
    retired: 0,
    box: 0,
    release: 1
  }

  LOSE_CONDITION_VALUES = {
    whiteout: 0,
    full_wipe: 1
  }

  LOSE_RESULT_VALUES = {
    centre: 0,
    reload: 1,
    disable: 2,
    delete: 3
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
    $game_switches[SWITCH_PROF_OAK_CHALLENGE]= enabled?(:prof_oak_challenge)
    $game_switches[SWITCH_NUZLOCKE_MODE]     = enabled?(:nuzlocke)
    $game_switches[SWITCH_LEVEL_CAPS]        = enabled?(:level_caps)
    $game_switches[SWITCH_NO_BAG_ITEMS_BATTLE] = enabled?(:no_bag_items_battle)

    $game_switches[SWITCH_DUPES_CLAUSE]      = nuzlocke_option?(:dupes_clause)
    $game_switches[SWITCH_SHINY_CLAUSE]      = nuzlocke_option?(:shiny_clause)
    $game_switches[SWITCH_NICKNAME_CLAUSE]   = nuzlocke_option?(:nickname_clause)
    $game_switches[SWITCH_HM_CLAUSE]         = nuzlocke_option?(:hm_clause)
    options = current[:nuzlocke_options] || {}

    $game_variables[VARIABLE_LOSE_CONDITION] =
      LOSE_CONDITION_VALUES[options[:lose_condition] || :whiteout] || 0

    $game_variables[VARIABLE_LOSE_RESULT] =
      LOSE_RESULT_VALUES[options[:lose_result] || :disable] || 2

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