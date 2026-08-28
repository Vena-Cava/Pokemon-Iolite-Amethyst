<<<<<<< Updated upstream
#===============================================================================
#
#===============================================================================
class PokemonJukebox_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(commands)
    @commands = commands
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap(_INTL("Graphics/UI/jukebox_bg"))
    @sprites["header"] = Window_UnformattedTextPokemon.newWithSize(
      _INTL("Jukebox"), 2, -18, 128, 64, @viewport
    )
    @sprites["header"].baseColor   = Color.new(248, 248, 248)
    @sprites["header"].shadowColor = Color.black
    @sprites["header"].windowskin  = nil
    @sprites["commands"] = Window_CommandPokemon.newWithSize(
      @commands, 94, 92, 324, 224, @viewport
    )
    @sprites["commands"].windowskin = nil
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbScene
    ret = -1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Keybinds.press?(:back)
        break
      elsif Keybinds.press?(:use)
        ret = @sprites["commands"].index
        break
      end
    end
    return ret
  end

  def pbSetCommands(newcommands, newindex)
    @sprites["commands"].commands = (!newcommands) ? @commands : newcommands
    @sprites["commands"].index    = newindex
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
=======
module GameData
  class TerrainTag
    attr_reader :id
    attr_reader :id_number
    attr_reader :real_name
    attr_reader :can_surf
    attr_reader :waterfall   # The main part only, not the crest
    attr_reader :waterfall_crest
    attr_reader :can_fish
    attr_reader :can_dive
    attr_reader :deep_bush
    attr_reader :shows_grass_rustle
    attr_reader :land_wild_encounters
    attr_reader :double_wild_encounters
    attr_reader :battle_environment
    attr_reader :ledge
    attr_reader :ice
    attr_reader :bridge
    attr_reader :shows_reflections
    attr_reader :must_walk
    attr_reader :must_walk_or_run
    attr_reader :ignore_passability

    DATA = {}

    extend ClassMethods
    include InstanceMethods

    # @param other [Symbol, self, String, Integer]
    # @return [self]
    def self.try_get(other)
      return self.get(:None) if other.nil?
      validate other => [Symbol, self, String, Integer]
      return other if other.is_a?(self)
      other = other.to_sym if other.is_a?(String)
      return (self::DATA.has_key?(other)) ? self::DATA[other] : self.get(:None)
    end

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id                     = hash[:id]
      @id_number              = hash[:id_number]
      @real_name              = hash[:id].to_s                || "Unnamed"
      @can_surf               = hash[:can_surf]               || false
      @waterfall              = hash[:waterfall]              || false
      @waterfall_crest        = hash[:waterfall_crest]        || false
      @can_fish               = hash[:can_fish]               || false
      @can_dive               = hash[:can_dive]               || false
      @deep_bush              = hash[:deep_bush]              || false
      @shows_grass_rustle     = hash[:shows_grass_rustle]     || false
      @land_wild_encounters   = hash[:land_wild_encounters]   || false
      @double_wild_encounters = hash[:double_wild_encounters] || false
      @battle_environment     = hash[:battle_environment]
      @ledge                  = hash[:ledge]                  || false
      @ice                    = hash[:ice]                    || false
      @bridge                 = hash[:bridge]                 || false
      @shows_reflections      = hash[:shows_reflections]      || false
      @must_walk              = hash[:must_walk]              || false
      @must_walk_or_run       = hash[:must_walk_or_run]       || false
      @ignore_passability     = hash[:ignore_passability]     || false
    end

    alias name real_name

    def can_surf_freely
      return @can_surf && !@waterfall && !@waterfall_crest
    end
>>>>>>> Stashed changes
  end
end

#===============================================================================
<<<<<<< Updated upstream
#
#===============================================================================
class PokemonJukeboxScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    commands = []
    cmdMarch   = -1
    cmdLullaby = -1
    cmdOak     = -1
    cmdCustom  = -1
    cmdTurnOff = -1
    commands[cmdMarch = commands.length]   = _INTL("Play: Pokémon March")
    commands[cmdLullaby = commands.length] = _INTL("Play: Pokémon Lullaby")
    commands[cmdOak = commands.length]     = _INTL("Play: Oak")
    commands[cmdCustom = commands.length]  = _INTL("Play: Custom...")
    commands[cmdTurnOff = commands.length] = _INTL("Stop")
    commands[commands.length]              = _INTL("Exit")
    @scene.pbStartScene(commands)
    loop do
      cmd = @scene.pbScene
      if cmd < 0
        pbPlayCloseMenuSE
        break
      elsif cmdMarch >= 0 && cmd == cmdMarch
        pbPlayDecisionSE
        pbBGMPlay("Radio - March", 100, 100)
        if $PokemonMap
          $PokemonMap.lower_encounter_rate = false
          $PokemonMap.higher_encounter_rate = true
        end
      elsif cmdLullaby >= 0 && cmd == cmdLullaby
        pbPlayDecisionSE
        pbBGMPlay("Radio - Lullaby", 100, 100)
        if $PokemonMap
          $PokemonMap.lower_encounter_rate = true
          $PokemonMap.higher_encounter_rate = false
        end
      elsif cmdOak >= 0 && cmd == cmdOak
        pbPlayDecisionSE
        pbBGMPlay("Radio - Oak", 100, 100)
        if $PokemonMap
          $PokemonMap.lower_encounter_rate = false
          $PokemonMap.higher_encounter_rate = false
        end
      elsif cmdCustom >= 0 && cmd == cmdCustom
        pbPlayDecisionSE
        files = []
        Dir.chdir("Audio/BGM/") do
          Dir.glob("*.ogg") { |f| files.push(f) }
          Dir.glob("*.wav") { |f| files.push(f) }
          Dir.glob("*.mid") { |f| files.push(f) }
          Dir.glob("*.midi") { |f| files.push(f) }
        end
        files.map! { |f| File.basename(f, ".*") }
        files.uniq!
        files.sort! { |a, b| a.downcase <=> b.downcase }
        @scene.pbSetCommands(files, 0)
        loop do
          cmd2 = @scene.pbScene
          if cmd2 < 0
            pbPlayCancelSE
            break
          end
          pbPlayDecisionSE
          $game_system.setDefaultBGM(files[cmd2])
          if $PokemonMap
            $PokemonMap.lower_encounter_rate = false
            $PokemonMap.higher_encounter_rate = false
          end
        end
        @scene.pbSetCommands(nil, cmdCustom)
      elsif cmdTurnOff >= 0 && cmd == cmdTurnOff
        pbPlayDecisionSE
        $game_system.setDefaultBGM(nil)
        pbBGMPlay(pbResolveAudioFile($game_map.bgm_name, $game_map.bgm.volume, $game_map.bgm.pitch))
        if $PokemonMap
          $PokemonMap.lower_encounter_rate = false
          $PokemonMap.higher_encounter_rate = false
        end
      else   # Exit
        pbPlayCloseMenuSE
        break
      end
    end
    @scene.pbEndScene
  end
end
=======

GameData::TerrainTag.register({
  :id                     => :None,
  :id_number              => 0
})

GameData::TerrainTag.register({
  :id                     => :Ledge,
  :id_number              => 1,
  :ledge                  => true
})

GameData::TerrainTag.register({
  :id                     => :Grass,
  :id_number              => 2,
  :shows_grass_rustle     => true,
  :land_wild_encounters   => true
})

GameData::TerrainTag.register({
  :id                     => :Sand,
  :id_number              => 3,
  :battle_environment     => :Sand
})

GameData::TerrainTag.register({
  :id                     => :Rock,
  :id_number              => 4,
  :battle_environment     => :Rock
})

GameData::TerrainTag.register({
  :id                     => :DeepWater,
  :id_number              => 5,
  :can_surf               => true,
  :can_fish               => true,
  :can_dive               => true,
  :battle_environment     => :MovingWater
})

GameData::TerrainTag.register({
  :id                     => :StillWater,
  :id_number              => 6,
  :can_surf               => true,
  :can_fish               => true,
  :battle_environment     => :StillWater,
  :shows_reflections      => true
})

GameData::TerrainTag.register({
  :id                     => :Water,
  :id_number              => 7,
  :can_surf               => true,
  :can_fish               => true,
  :battle_environment     => :MovingWater
})

GameData::TerrainTag.register({
  :id                     => :Waterfall,
  :id_number              => 8,
  :can_surf               => true,
  :waterfall              => true
})

GameData::TerrainTag.register({
  :id                     => :WaterfallCrest,
  :id_number              => 9,
  :can_surf               => true,
  :can_fish               => true,
  :waterfall_crest        => true
})

GameData::TerrainTag.register({
  :id                     => :TallGrass,
  :id_number              => 10,
  :deep_bush              => true,
  :land_wild_encounters   => true,
  :double_wild_encounters => true,
  :battle_environment     => :TallGrass,
  :must_walk              => true
})

GameData::TerrainTag.register({
  :id                     => :UnderwaterGrass,
  :id_number              => 11,
  :land_wild_encounters   => true
})

GameData::TerrainTag.register({
  :id                     => :Ice,
  :id_number              => 12,
  :battle_environment     => :Ice,
  :ice                    => true,
  :must_walk_or_run       => true
})

GameData::TerrainTag.register({
  :id                     => :Neutral,
  :id_number              => 13,
  :ignore_passability     => true
})

# NOTE: This is referenced by ID in the :pick_up_soot proc added to
#       EventHandlers. It adds soot to the Soot Sack if the player walks over
#       one of these tiles.
GameData::TerrainTag.register({
  :id                     => :SootGrass,
  :id_number              => 14,
  :shows_grass_rustle     => true,
  :land_wild_encounters   => true,
  :battle_environment     => :Grass
})

GameData::TerrainTag.register({
  :id                     => :Bridge,
  :id_number              => 15,
  :bridge                 => true
})

GameData::TerrainTag.register({
  :id                     => :Puddle,
  :id_number              => 16,
  :battle_environment     => :Puddle,
  :shows_reflections      => true
})

GameData::TerrainTag.register({
  :id                     => :NoEffect,
  :id_number              => 17
})
>>>>>>> Stashed changes
