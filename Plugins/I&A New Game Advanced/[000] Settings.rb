module AdvancedNewGame

  #=============================================================================
  # Switch IDs
  #=============================================================================

  SWITCH_INVERSE_MODE         = 127
  SWITCH_NUZLOCKE_MODE        = 128
  SWITCH_LEVEL_CAPS           = 129
  SWITCH_DUPES_CLAUSE         = 130
  SWITCH_SHINY_CLAUSE         = 131
  SWITCH_NICKNAME_CLAUSE      = 132
  SWITCH_PROF_OAK_CHALLENGE   = 133
  SWITCH_NO_BAG_ITEMS_BATTLE  = 134
  SWITCH_NUZLOCKE_STARTED     = 135
  SWITCH_HM_CLAUSE            = 136

  #=============================================================================
  # Variable IDs
  #=============================================================================

  VARIABLE_DIFFICULTY         = 100
  VARIABLE_LEVEL_CAP          = 101
  VARIABLE_NEXT_BOSS          = 102
  VARIABLE_FAINT_RULE         = 103
  VARIABLE_POKECENTER_LIMIT   = 104 
  VARIABLE_LOSE_CONDITION     = 105
  VARIABLE_LOSE_RESULT        = 106

  #=============================================================================
  # Text
  #=============================================================================
  DIFFICULTIES = {
    easy: {
      name: "Easy",
      desc: "Lower-level trainers, weaker stats, more money, and easier AI."
    },
    normal: {
      name: "Normal",
      desc: "The game plays as originally designed."
    },
    hard: {
      name: "Hard",
      desc: "Stronger trainers, better stats, more held items, less money, and smarter AI."
    },
    ultra_hard: {
      name: "Ultra Hard",
      desc: "Experimental. Perfect teams, rare abilities, many items, very low money, and strongest AI."
    }
  }

  MODES = {
    nuzlocke: {
      name: "Nuzlocke",
      desc: "Fainted Pokémon cannot be used. Only first encounter per area can be caught."
    },
    prof_oak_challenge: {
      name: "Prof. Oak Challenge",
      desc: "You must fill in every possible Pokédex Entry before challenging each Gym."
    },
    inverse: {
      name: "Inverse",
      desc: "Type matchups are flipped. Weaknesses become resistances, and resistances become weaknesses."
    },
    level_caps: {
      name: "Level Caps",
      desc: "Your Pokémon cannot level past the next major boss's strongest Pokémon."
    },
    no_bag_items_battle: {
      name: "No Battle Items",
      desc: "Items from the Bag cannot be used during battle. Poké Balls and Held items still work."
    }
  }
  
  NUZLOCKE_OPTIONS = {
    dupes_clause: {
      name: "Dupes Clause",
      desc: "If your first encounter is a Pokémon you already own, you may try again."
    },
    shiny_clause: {
      name: "Shiny Clause",
      desc: "Shiny Pokémon do not count towards your encounters and may be caught even after your encounter is used."
    },
    nickname_clause: {
      name: "Nickname Clause",
      desc: "All caught Pokémon must be given unique nicknames."
    },
    hm_clause: {
      name: "HM Clause",
      desc: "Retired Pokémon can still use HM moves in the field. SOFTLOCK POSSIBLE IF OFF"
    },
    lose_condition: {
      name: "Lose Condition",
      desc: "Choose what counts as losing the run."
    },
    lose_result: {
      name: "Lose Result",
      desc: "Choose what happens when the run is lost."
    },
    pokecenter_limit: {
      name: "PokéCentre Limit",
      desc: "Limits how many times each town's Pokémon Centre can heal your party."
    }
  }
  
  NUZLOCKE_FAINT_RULES = {
    retired: {
      name: "Retired",
      desc: "Fainted Pokémon remain in the party, but cannot battle."
    },
    box: {
      name: "Perma-Box",
      desc: "Fainted Pokémon are sent to the Box and cannot rejoin the party. SOFTLOCK POSSIBLE"
    },
    release: {
      name: "Auto-Release",
      desc: "Fainted Pokémon are automatically released. SOFTLOCK POSSIBLE"
    }
  }
  
  POKECENTER_LIMITS = {
    infinite: {
      name: "Infinite",
      value: -1
    },
    three: {
      name: "3",
      value: 3
    },
    one: {
      name: "1",
      value: 1
    },
    zero: {
      name: "0",
      value: 0
    }
  }
  
  LOSE_CONDITIONS = {
    whiteout: {
      name: "Whiteout",
      desc: "The run is lost when you lose a battle."
    },
    full_wipe: {
      name: "Full Wipe",
      desc: "The run is lost only when all Pokémon are retired."
    }
  }

  LOSE_RESULTS = {
    reload: {
      name: "Reload",
      desc: "Return to your last saved game."
    },
    disable: {
      name: "Disable",
      desc: "Mark the save file as failed, making it unplayable."
    },
    delete: {
      name: "Delete",
      desc: "Delete the save file."
    }
  }

 #=============================================================================
 # Defaults
 #=============================================================================
  DEFAULT_MODES = {
    difficulty:          :normal,
    nuzlocke:            false,
    nuzlocke_options: {
      faint_rule:        :retired,
      dupes_clause:      true,
      shiny_clause:      true,
      nickname_clause:   false,
      hm_clause:         true,
      lose_condition: :full_wipe,
      lose_result: :disable,
      pokecenter_limit: :infinite
    },
    prof_oak_challenge:  false,
    inverse:             false,
    level_caps:          false,
    no_bag_items_battle: false
  }
end