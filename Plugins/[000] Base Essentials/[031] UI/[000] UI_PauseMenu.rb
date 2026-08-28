<<<<<<< Updated upstream
#===============================================================================
#
#===============================================================================
class PokemonPauseMenu_Scene
  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].visible = false
    @sprites["cmdwindow"].viewport = @viewport
    @sprites["infowindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
    @sprites["helpwindow"].visible = false
    @infostate = false
    @helpstate = false
    pbSEPlay("GUI menu open")
  end

  def pbShowInfo(text)
    @sprites["infowindow"].resizeToFit(text, Graphics.height)
    @sprites["infowindow"].text    = text
    @sprites["infowindow"].visible = true
    @infostate = true
  end

  def pbShowHelp(text)
    @sprites["helpwindow"].resizeToFit(text, Graphics.height)
    @sprites["helpwindow"].text    = text
    @sprites["helpwindow"].visible = true
    pbBottomLeft(@sprites["helpwindow"])
    @helpstate = true
  end

  def pbShowMenu
    @sprites["cmdwindow"].visible = true
    @sprites["infowindow"].visible = @infostate
    @sprites["helpwindow"].visible = @helpstate
  end

  def pbHideMenu
    @sprites["cmdwindow"].visible = false
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"].visible = false
  end

  def pbShowCommands(commands)
    ret = -1
    cmdwindow = @sprites["cmdwindow"]
    cmdwindow.commands = commands
    cmdwindow.index    = $game_temp.menu_last_choice
    cmdwindow.resizeToFit(commands)
    cmdwindow.x        = Graphics.width - cmdwindow.width
    cmdwindow.y        = 0
    cmdwindow.visible  = true
    loop do
      cmdwindow.update
      Graphics.update
      Input.update
      pbUpdateSceneMap
      if Keybinds.press?(:back) || Keybinds.press?(:action)
        ret = -1
        break
      elsif Keybinds.press?(:use)
        ret = cmdwindow.index
        $game_temp.menu_last_choice = ret
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbRefresh; end
end

#===============================================================================
#
#===============================================================================
class PokemonPauseMenu
  def initialize(scene)
    @scene = scene
  end

  def pbShowMenu
    @scene.pbRefresh
    @scene.pbShowMenu
  end

  def pbShowInfo; end

  def pbStartPokemonMenu
    if !$player
      if $DEBUG
        pbMessage(_INTL("The player trainer was not defined, so the pause menu can't be displayed."))
        pbMessage(_INTL("Please see the documentation to learn how to set up the trainer player."))
      end
      return
    end
    @scene.pbStartScene
    # Show extra info window if relevant
    pbShowInfo
    # Get all commands
    command_list = []
    commands = []
    MenuHandlers.each_available(:pause_menu) do |option, hash, name|
      command_list.push(name)
      commands.push(hash)
    end
    # Main loop
    end_scene = false
    loop do
      choice = @scene.pbShowCommands(command_list)
      if choice < 0
        pbPlayCloseMenuSE
        end_scene = true
        break
      end
      break if commands[choice]["effect"].call(@scene)
    end
    @scene.pbEndScene if end_scene
=======
module GameData
  class GrowthRate
    attr_reader :id
    attr_reader :real_name
    attr_reader :exp_values
    attr_reader :exp_formula

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    # Calculates the maximum level a Pokémon can attain. This can vary during a
    # game, and here is where you would make it do so. Note that this method is
    # called by the Compiler, which happens before anything (e.g. Game Switches/
    # Variables, the player's data) is loaded, so code in this method should
    # check whether the needed variables exist before using them; if they don't,
    # this method should return the maximum possible level ever.
    # @return [Integer] the maximum level attainable by a Pokémon
    def self.max_level
      return Settings::MAXIMUM_LEVEL
    end

    def initialize(hash)
      @id          = hash[:id]
      @real_name   = hash[:name] || "Unnamed"
      @exp_values  = hash[:exp_values]
      @exp_formula = hash[:exp_formula]
    end

    # @return [String] the translated name of this growth rate
    def name
      return _INTL(@real_name)
    end

    # @param level [Integer] a level number
    # @return [Integer] the minimum Exp needed to be at the given level
    def minimum_exp_for_level(level)
      return ArgumentError.new("Level #{level} is invalid.") if !level || level <= 0
      level = [level, GrowthRate.max_level].min
      return @exp_values[level] if level < @exp_values.length
      raise "No Exp formula is defined for growth rate #{name}" if !@exp_formula
      return @exp_formula.call(level)
    end

    # @return [Integer] the maximum Exp a Pokémon with this growth rate can have
    def maximum_exp
      return minimum_exp_for_level(GrowthRate.max_level)
    end

    # @param exp1 [Integer] an Exp amount
    # @param exp2 [Integer] an Exp amount
    # @return [Integer] the sum of the two given Exp amounts
    def add_exp(exp1, exp2)
      return (exp1 + exp2).clamp(0, maximum_exp)
    end

    # @param exp [Integer] an Exp amount
    # @return [Integer] the level of a Pokémon that has the given Exp amount
    def level_from_exp(exp)
      return ArgumentError.new("Exp amount #{level} is invalid.") if !exp || exp < 0
      max = GrowthRate.max_level
      return max if exp >= maximum_exp
      (1..max).each do |level|
        return level - 1 if exp < minimum_exp_for_level(level)
      end
      return max
    end
>>>>>>> Stashed changes
  end
end

#===============================================================================
<<<<<<< Updated upstream
# Pause menu commands.
#===============================================================================
MenuHandlers.add(:pause_menu, :pokedex, {
  "name"      => _INTL("Pokédex"),
  "order"     => 10,
  "condition" => proc { next $player.has_pokedex && $player.pokedex.accessible_dexes.length > 0 },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    if Settings::USE_CURRENT_REGION_DEX
      pbFadeOutIn do
        scene = PokemonPokedex_Scene.new
        screen = PokemonPokedexScreen.new(scene)
        screen.pbStartScreen
        menu.pbRefresh
      end
    elsif $player.pokedex.accessible_dexes.length == 1
      $PokemonGlobal.pokedexDex = $player.pokedex.accessible_dexes[0]
      pbFadeOutIn do
        scene = PokemonPokedex_Scene.new
        screen = PokemonPokedexScreen.new(scene)
        screen.pbStartScreen
        menu.pbRefresh
      end
    else
      pbFadeOutIn do
        scene = PokemonPokedexMenu_Scene.new
        screen = PokemonPokedexMenuScreen.new(scene)
        screen.pbStartScreen
        menu.pbRefresh
      end
    end
    next false
  }
})

MenuHandlers.add(:pause_menu, :party, {
  "name"      => _INTL("Pokémon"),
  "order"     => 20,
  "condition" => proc { next $player.party_count > 0 },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    hidden_move = nil
    pbFadeOutIn do
      sscene = PokemonParty_Scene.new
      sscreen = PokemonPartyScreen.new(sscene, $player.party)
      hidden_move = sscreen.pbPokemonScreen
      (hidden_move) ? menu.pbEndScene : menu.pbRefresh
    end
    next false if !hidden_move
    $game_temp.in_menu = false
    pbUseHiddenMove(hidden_move[0], hidden_move[1])
    next true
  }
})

MenuHandlers.add(:pause_menu, :bag, {
  "name"      => _INTL("Bag"),
  "order"     => 30,
  "condition" => proc { next !pbInBugContest? },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    item = nil
    pbFadeOutIn do
      scene = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, $bag)
      item = screen.pbStartScreen
      (item) ? menu.pbEndScene : menu.pbRefresh
    end
    next false if !item
    $game_temp.in_menu = false
    pbUseKeyItemInField(item)
    next true
  }
})

MenuHandlers.add(:pause_menu, :pokegear, {
  "name"      => _INTL("Pokégear"),
  "order"     => 40,
  "condition" => proc { next $player.has_pokegear },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn do
      scene = PokemonPokegear_Scene.new
      screen = PokemonPokegearScreen.new(scene)
      screen.pbStartScreen
      ($game_temp.fly_destination) ? menu.pbEndScene : menu.pbRefresh
    end
    next pbFlyToNewLocation
  }
})

MenuHandlers.add(:pause_menu, :town_map, {
  "name"      => _INTL("Town Map"),
  "order"     => 40,
  "condition" => proc { next !$player.has_pokegear && $bag.has?(:TOWNMAP) },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn do
      scene = PokemonRegionMap_Scene.new(-1, false)
      screen = PokemonRegionMapScreen.new(scene)
      ret = screen.pbStartScreen
      $game_temp.fly_destination = ret if ret
      ($game_temp.fly_destination) ? menu.pbEndScene : menu.pbRefresh
    end
    next pbFlyToNewLocation
  }
})

MenuHandlers.add(:pause_menu, :trainer_card, {
  "name"      => proc { next $player.name },
  "order"     => 50,
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn do
      scene = PokemonTrainerCard_Scene.new
      screen = PokemonTrainerCardScreen.new(scene)
      screen.pbStartScreen
      menu.pbRefresh
    end
    next false
  }
})

MenuHandlers.add(:pause_menu, :save, {
  "name"      => _INTL("Save"),
  "order"     => 60,
  "condition" => proc {
    next $game_system && !$game_system.save_disabled && !pbInSafari? && !pbInBugContest?
  },
  "effect"    => proc { |menu|
    menu.pbHideMenu
    scene = PokemonSave_Scene.new
    screen = PokemonSaveScreen.new(scene)
    if screen.pbSaveScreen
      menu.pbEndScene
      next true
    end
    menu.pbRefresh
    menu.pbShowMenu
    next false
  }
})

MenuHandlers.add(:pause_menu, :options, {
  "name"      => _INTL("Options"),
  "order"     => 70,
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn do
      scene = PokemonOption_Scene.new
      screen = PokemonOptionScreen.new(scene)
      screen.pbStartScreen
      pbUpdateSceneMap
      menu.pbRefresh
    end
    next false
  }
})

MenuHandlers.add(:pause_menu, :debug, {
  "name"      => _INTL("Debug"),
  "order"     => 80,
  "condition" => proc { next $DEBUG },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn do
      pbDebugMenu
      menu.pbRefresh
    end
    next false
  }
})

MenuHandlers.add(:pause_menu, :quit_game, {
  "name"      => _INTL("Quit Game"),
  "order"     => 90,
  "effect"    => proc { |menu|
    menu.pbHideMenu
    if pbConfirmMessage(_INTL("Are you sure you want to quit the game?"))
      scene = PokemonSave_Scene.new
      screen = PokemonSaveScreen.new(scene)
      screen.pbSaveScreen
      menu.pbEndScene
      $scene = nil
      next true
    end
    menu.pbRefresh
    menu.pbShowMenu
    next false
  }
=======

GameData::GrowthRate.register({
  :id          => :Medium,   # Also known as Medium Fast
  :name        => _INTL("Medium"),
  :exp_values  => [-1,
                   0,      8,      27,     64,     125,    216,    343,    512,    729,    1000,
                   1331,   1728,   2197,   2744,   3375,   4096,   4913,   5832,   6859,   8000,
                   9261,   10648,  12167,  13824,  15625,  17576,  19683,  21952,  24389,  27000,
                   29791,  32768,  35937,  39304,  42875,  46656,  50653,  54872,  59319,  64000,
                   68921,  74088,  79507,  85184,  91125,  97336,  103823, 110592, 117649, 125000,
                   132651, 140608, 148877, 157464, 166375, 175616, 185193, 195112, 205379, 216000,
                   226981, 238328, 250047, 262144, 274625, 287496, 300763, 314432, 328509, 343000,
                   357911, 373248, 389017, 405224, 421875, 438976, 456533, 474552, 493039, 512000,
                   531441, 551368, 571787, 592704, 614125, 636056, 658503, 681472, 704969, 729000,
                   753571, 778688, 804357, 830584, 857375, 884736, 912673, 941192, 970299, 1000000],
  :exp_formula => proc { |level| next level**3 }
})

# Erratic (600000):
#   For levels 0-50:   n**3 * (100 - n) / 50
#   For levels 51-68:  n**3 * (150 - n) / 100
#   For levels 69-98:  n**3 * ((1911 - (10 * level)) / 3).floor / 500
#   For levels 99-100: n**3 * (160 - n) / 100
GameData::GrowthRate.register({
  :id          => :Erratic,
  :name        => _INTL("Erratic"),
  :exp_values  => [-1,
                   0,      15,      52,    122,    237,    406,    637,    942,    1326,   1800,
                   2369,   3041,   3822,   4719,   5737,   6881,   8155,   9564,   11111,  12800,
                   14632,  16610,  18737,  21012,  23437,  26012,  28737,  31610,  34632,  37800,
                   41111,  44564,  48155,  51881,  55737,  59719,  63822,  68041,  72369,  76800,
                   81326,  85942,  90637,  95406,  100237, 105122, 110052, 115015, 120001, 125000,
                   131324, 137795, 144410, 151165, 158056, 165079, 172229, 179503, 186894, 194400,
                   202013, 209728, 217540, 225443, 233431, 241496, 249633, 257834, 267406, 276458,
                   286328, 296358, 305767, 316074, 326531, 336255, 346965, 357812, 367807, 378880,
                   390077, 400293, 411686, 423190, 433572, 445239, 457001, 467489, 479378, 491346,
                   501878, 513934, 526049, 536557, 548720, 560922, 571333, 583539, 591882, 600000],
  :exp_formula => proc { |level| next ((level**4) + ((level**3) * 2000)) / 3500 }
})

# Fluctuating (1640000):
#   For levels 0-15  : n**3 * (24 + ((n + 1) / 3)) / 50
#   For levels 16-35:  n**3 * (14 + n) / 50
#   For levels 36-100: n**3 * (32 + (n / 2)) / 50
GameData::GrowthRate.register({
  :id          => :Fluctuating,
  :name        => _INTL("Fluctuating"),
  :exp_values  => [-1,
                   0,       4,       13,      32,      65,      112,     178,     276,     393,     540,
                   745,     967,     1230,    1591,    1957,    2457,    3046,    3732,    4526,    5440,
                   6482,    7666,    9003,    10506,   12187,   14060,   16140,   18439,   20974,   23760,
                   26811,   30146,   33780,   37731,   42017,   46656,   50653,   55969,   60505,   66560,
                   71677,   78533,   84277,   91998,   98415,   107069,  114205,  123863,  131766,  142500,
                   151222,  163105,  172697,  185807,  196322,  210739,  222231,  238036,  250562,  267840,
                   281456,  300293,  315059,  335544,  351520,  373744,  390991,  415050,  433631,  459620,
                   479600,  507617,  529063,  559209,  582187,  614566,  639146,  673863,  700115,  737280,
                   765275,  804997,  834809,  877201,  908905,  954084,  987754,  1035837, 1071552, 1122660,
                   1160499, 1214753, 1254796, 1312322, 1354652, 1415577, 1460276, 1524731, 1571884, 1640000],
  :exp_formula => proc { |level|
    next ((level**3) + ((level / 2) + 32)) * 4 / (100 + level)
  }
})

GameData::GrowthRate.register({
  :id          => :Parabolic,   # Also known as Medium Slow
  :name        => _INTL("Parabolic"),
  :exp_values  => [-1,
                   0,      9,      57,     96,     135,    179,    236,    314,    419,     560,
                   742,    973,    1261,   1612,   2035,   2535,   3120,   3798,   4575,    5460,
                   6458,   7577,   8825,   10208,  11735,  13411,  15244,  17242,  19411,   21760,
                   24294,  27021,  29949,  33084,  36435,  40007,  43808,  47846,  52127,   56660,
                   61450,  66505,  71833,  77440,  83335,  89523,  96012,  102810, 109923,  117360,
                   125126, 133229, 141677, 150476, 159635, 169159, 179056, 189334, 199999,  211060,
                   222522, 234393, 246681, 259392, 272535, 286115, 300140, 314618, 329555,  344960,
                   360838, 377197, 394045, 411388, 429235, 447591, 466464, 485862, 505791,  526260,
                   547274, 568841, 590969, 613664, 636935, 660787, 685228, 710266, 735907,  762160,
                   789030, 816525, 844653, 873420, 902835, 932903, 963632, 995030, 1027103, 1059860],
  :exp_formula => proc { |level| next ((level**3) * 6 / 5) - (15 * (level**2)) + (100 * level) - 140 }
})

GameData::GrowthRate.register({
  :id          => :Fast,
  :name        => _INTL("Fast"),
  :exp_values  => [-1,
                   0,      6,      21,     51,     100,    172,    274,    409,    583,    800,
                   1064,   1382,   1757,   2195,   2700,   3276,   3930,   4665,   5487,   6400,
                   7408,   8518,   9733,   11059,  12500,  14060,  15746,  17561,  19511,  21600,
                   23832,  26214,  28749,  31443,  34300,  37324,  40522,  43897,  47455,  51200,
                   55136,  59270,  63605,  68147,  72900,  77868,  83058,  88473,  94119,  100000,
                   106120, 112486, 119101, 125971, 133100, 140492, 148154, 156089, 164303, 172800,
                   181584, 190662, 200037, 209715, 219700, 229996, 240610, 251545, 262807, 274400,
                   286328, 298598, 311213, 324179, 337500, 351180, 365226, 379641, 394431, 409600,
                   425152, 441094, 457429, 474163, 491300, 508844, 526802, 545177, 563975, 583200,
                   602856, 622950, 643485, 664467, 685900, 707788, 730138, 752953, 776239, 800000],
  :exp_formula => proc { |level| (level**3) * 4 / 5 }
})

GameData::GrowthRate.register({
  :id          => :Slow,
  :name        => _INTL("Slow"),
  :exp_values  => [-1,
                   0,      10,     33,      80,      156,     270,     428,     640,     911,     1250,
                   1663,   2160,   2746,    3430,    4218,    5120,    6141,    7290,    8573,    10000,
                   11576,  13310,  15208,   17280,   19531,   21970,   24603,   27440,   30486,   33750,
                   37238,  40960,  44921,   49130,   53593,   58320,   63316,   68590,   74148,   80000,
                   86151,  92610,  99383,   106480,  113906,  121670,  129778,  138240,  147061,  156250,
                   165813, 175760, 186096,  196830,  207968,  219520,  231491,  243890,  256723,  270000,
                   283726, 297910, 312558,  327680,  343281,  359370,  375953,  393040,  410636,  428750,
                   447388, 466560, 486271,  506530,  527343,  548720,  570666,  593190,  616298,  640000,
                   664301, 689210, 714733,  740880,  767656,  795070,  823128,  851840,  881211,  911250,
                   941963, 973360, 1005446, 1038230, 1071718, 1105920, 1140841, 1176490, 1212873, 1250000],
  :exp_formula => proc { |level| (level**3) * 5 / 4 }
>>>>>>> Stashed changes
})
