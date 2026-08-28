<<<<<<< Updated upstream
#===============================================================================
# Pokédex Regional Dexes list menu screen
# * For choosing which region list to view. Only appears when there is more
#   than one accessible region list to choose from, and if
#   Settings::USE_CURRENT_REGION_DEX is false.
#===============================================================================
class Window_DexesList < Window_CommandPokemon
  def initialize(commands, commands2, width)
    @commands2 = commands2
    super(commands, width)
    @selarrow = AnimatedBitmap.new("Graphics/UI/sel_arrow_white")
    self.baseColor   = Color.new(248, 248, 248)
    self.shadowColor = Color.black
    self.windowskin  = nil
  end

  def drawItem(index, count, rect)
    super(index, count, rect)
    if index >= 0 && index < @commands2.length
      pbDrawShadowText(self.contents, rect.x + 254, rect.y + (self.contents.text_offset_y || 0),
                       64, rect.height, @commands2[index][0].to_s, self.baseColor, self.shadowColor, 1)
      pbDrawShadowText(self.contents, rect.x + 350, rect.y + (self.contents.text_offset_y || 0),
                       64, rect.height, @commands2[index][1].to_s, self.baseColor, self.shadowColor, 1)
      allseen = (@commands2[index][0] >= @commands2[index][2])
      allown  = (@commands2[index][1] >= @commands2[index][2])
      pbDrawImagePositions(
        self.contents,
        [["Graphics/UI/Pokedex/icon_menuseenown", rect.x + 236, rect.y + 6, (allseen) ? 24 : 0, 0, 24, 24],
         ["Graphics/UI/Pokedex/icon_menuseenown", rect.x + 332, rect.y + 6, (allown) ? 24 : 0, 24, 24, 24]]
      )
=======
# If a Pokémon's gender ratio is none of :AlwaysMale, :AlwaysFemale or
# :Genderless, then it will choose a random number between 0 and 255 inclusive,
# and compare it to the @female_chance. If the random number is lower than this
# chance, it will be female; otherwise, it will be male.
module GameData
  class GenderRatio
    attr_reader :id
    attr_reader :real_name
    attr_reader :female_chance

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id            = hash[:id]
      @real_name     = hash[:name] || "Unnamed"
      @female_chance = hash[:female_chance]
    end

    # @return [String] the translated name of this gender ratio
    def name
      return _INTL(@real_name)
    end

    # @return [Boolean] whether a Pokémon with this gender ratio can only ever
    #   be a single gender
    def single_gendered?
      return @female_chance.nil?
>>>>>>> Stashed changes
    end
  end
end

#===============================================================================
<<<<<<< Updated upstream
#
#===============================================================================
class PokemonPokedexMenu_Scene
  SEEN_OBTAINED_TEXT_BASE   = Color.new(248, 248, 248)
  SEEN_OBTAINED_TEXT_SHADOW = Color.new(192, 32, 40)

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(commands, commands2)
    @commands = commands
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_menu"))
    text_tag = shadowc3tag(SEEN_OBTAINED_TEXT_BASE, SEEN_OBTAINED_TEXT_SHADOW)
    @sprites["headings"] = Window_AdvancedTextPokemon.newWithSize(
      text_tag + _INTL("SEEN") + "<r>" + _INTL("OBTAINED") + "</c3>", 286, 136, 208, 64, @viewport
    )
    @sprites["headings"].windowskin = nil
    @sprites["commands"] = Window_DexesList.new(commands, commands2, Graphics.width - 84)
    @sprites["commands"].x      = 40
    @sprites["commands"].y      = 192
    @sprites["commands"].height = 192
    @sprites["commands"].viewport = @viewport
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbScene
    ret = -1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Keybinds.press?(:back)
        pbPlayCloseMenuSE
        break
      elsif Keybinds.press?(:use)
        ret = @sprites["commands"].index
        (ret == @commands.length - 1) ? pbPlayCloseMenuSE : pbSEPlay("GUI pokedex open")
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokedexMenuScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    commands  = []
    commands2 = []
    dexnames = Settings.pokedex_names
    $player.pokedex.accessible_dexes.each do |dex|
      if dexnames[dex].nil?
        commands.push(_INTL("Pokédex"))
      elsif dexnames[dex].is_a?(Array)
        commands.push(dexnames[dex][0])
      else
        commands.push(dexnames[dex])
      end
      commands2.push([$player.pokedex.seen_count(dex),
                      $player.pokedex.owned_count(dex),
                      pbGetRegionalDexLength(dex)])
    end
    commands.push(_INTL("Exit"))
    @scene.pbStartScene(commands, commands2)
    loop do
      cmd = @scene.pbScene
      break if cmd < 0 || cmd >= commands2.length   # Cancel/Exit
      $PokemonGlobal.pokedexDex = $player.pokedex.accessible_dexes[cmd]
      pbFadeOutIn do
        scene = PokemonPokedex_Scene.new
        screen = PokemonPokedexScreen.new(scene)
        screen.pbStartScreen
      end
    end
    @scene.pbEndScene
  end
end
=======

GameData::GenderRatio.register({
  :id            => :AlwaysMale,
  :name          => _INTL("Always Male")
})

GameData::GenderRatio.register({
  :id            => :AlwaysFemale,
  :name          => _INTL("Always Female")
})

GameData::GenderRatio.register({
  :id            => :Genderless,
  :name          => _INTL("Genderless")
})

GameData::GenderRatio.register({
  :id            => :FemaleOneEighth,
  :name          => _INTL("Female One Eighth"),
  :female_chance => 32
})

GameData::GenderRatio.register({
  :id            => :Female25Percent,
  :name          => _INTL("Female 25 Percent"),
  :female_chance => 64
})

GameData::GenderRatio.register({
  :id            => :Female50Percent,
  :name          => _INTL("Female 50 Percent"),
  :female_chance => 128
})

GameData::GenderRatio.register({
  :id            => :Female75Percent,
  :name          => _INTL("Female 75 Percent"),
  :female_chance => 192
})

GameData::GenderRatio.register({
  :id            => :FemaleSevenEighths,
  :name          => _INTL("Female Seven Eighths"),
  :female_chance => 224
})
>>>>>>> Stashed changes
