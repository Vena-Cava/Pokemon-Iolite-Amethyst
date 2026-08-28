<<<<<<< Updated upstream
#===============================================================================
#
#===============================================================================
class PokegearButton < Sprite
  attr_reader :index
  attr_reader :name
  attr_reader :selected

  TEXT_BASE_COLOR = Color.new(248, 248, 248)
  TEXT_SHADOW_COLOR = Color.new(40, 40, 40)

  def initialize(command, x, y, viewport = nil)
    super(viewport)
    @image = command[0]
    @name  = command[1]
    @selected = false
    if $player.female? && pbResolveBitmap("Graphics/UI/Pokegear/icon_button_f")
      @button = AnimatedBitmap.new("Graphics/UI/Pokegear/icon_button_f")
    else
      @button = AnimatedBitmap.new("Graphics/UI/Pokegear/icon_button")
    end
    @contents = Bitmap.new(@button.width, @button.height)
    self.bitmap = @contents
    self.x = x - (@button.width / 2)
    self.y = y
    pbSetSystemFont(self.bitmap)
    refresh
  end

  def dispose
    @button.dispose
    @contents.dispose
    super
  end

  def selected=(val)
    oldsel = @selected
    @selected = val
    refresh if oldsel != val
  end

  def refresh
    self.bitmap.clear
    rect = Rect.new(0, 0, @button.width, @button.height / 2)
    rect.y = @button.height / 2 if @selected
    self.bitmap.blt(0, 0, @button.bitmap, rect)
    textpos = [
      [@name, rect.width / 2, (rect.height / 2) - 10, :center, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR]
    ]
    pbDrawTextPositions(self.bitmap, textpos)
    imagepos = [
      [sprintf("Graphics/UI/Pokegear/icon_%s", @image), 18, 10]
    ]
    pbDrawImagePositions(self.bitmap, imagepos)
=======
# The pbs_order value determines the order in which the stats are written in
# several PBS files, where base stats/IVs/EVs/EV yields are defined. Only stats
# which are yielded by the "each_main" method can have stat numbers defined in
# those places. The values of pbs_order defined below should start with 0 and
# increase without skipping any numbers.
module GameData
  class Stat
    attr_reader :id
    attr_reader :real_name
    attr_reader :real_name_brief
    attr_reader :type
    attr_reader :pbs_order

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    # These stats are defined in PBS files, and should have the :pbs_order
    # property.
    def self.each_main
      self.each { |s| yield s if [:main, :main_battle].include?(s.type) }
    end

    def self.each_main_battle
      self.each { |s| yield s if [:main_battle].include?(s.type) }
    end

    # These stats have associated stat stages in battle.
    def self.each_battle
      self.each { |s| yield s if [:main_battle, :battle].include?(s.type) }
    end

    def initialize(hash)
      @id              = hash[:id]
      @real_name       = hash[:name]       || "Unnamed"
      @real_name_brief = hash[:name_brief] || "None"
      @type            = hash[:type]       || :none
      @pbs_order       = hash[:pbs_order]  || -1
    end

    # @return [String] the translated name of this stat
    def name
      return _INTL(@real_name)
    end

    # @return [String] the translated brief name of this stat
    def name_brief
      return _INTL(@real_name_brief)
    end
>>>>>>> Stashed changes
  end
end

#===============================================================================
<<<<<<< Updated upstream
#
#===============================================================================
class PokemonPokegear_Scene
  def pbUpdate
    @commands.length.times do |i|
      @sprites["button#{i}"].selected = (i == @index)
    end
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(commands)
    @commands = commands
    @index = 0
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    if $player.female? && pbResolveBitmap("Graphics/UI/Pokegear/bg_f")
      @sprites["background"].setBitmap("Graphics/UI/Pokegear/bg_f")
    else
      @sprites["background"].setBitmap("Graphics/UI/Pokegear/bg")
    end
    @commands.length.times do |i|
      @sprites["button#{i}"] = PokegearButton.new(@commands[i], Graphics.width / 2, 0, @viewport)
      button_height = @sprites["button#{i}"].bitmap.height / 2
      @sprites["button#{i}"].y = ((Graphics.height - (@commands.length * button_height)) / 2) + (i * button_height)
    end
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
        pbPlayDecisionSE
        ret = @index
        break
      elsif Keybinds.press?(:up)
        pbPlayCursorSE if @commands.length > 1
        @index -= 1
        @index = @commands.length - 1 if @index < 0
      elsif Keybinds.press?(:down)
        pbPlayCursorSE if @commands.length > 1
        @index += 1
        @index = 0 if @index >= @commands.length
      end
    end
    return ret
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    dispose
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokegearScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    # Get all commands
    command_list = []
    commands = []
    MenuHandlers.each_available(:pokegear_menu) do |option, hash, name|
      command_list.push([hash["icon_name"] || "", name])
      commands.push(hash)
    end
    @scene.pbStartScene(command_list)
    # Main loop
    end_scene = false
    loop do
      choice = @scene.pbScene
      if choice < 0
        end_scene = true
        break
      end
      break if commands[choice]["effect"].call(@scene)
    end
    @scene.pbEndScene if end_scene
  end
end

#===============================================================================
#
#===============================================================================
MenuHandlers.add(:pokegear_menu, :map, {
  "name"      => _INTL("Map"),
  "icon_name" => "map",
  "order"     => 10,
  "effect"    => proc { |menu|
    pbFadeOutIn do
      scene = PokemonRegionMap_Scene.new(-1, false)
      screen = PokemonRegionMapScreen.new(scene)
      ret = screen.pbStartScreen
      if ret
        $game_temp.fly_destination = ret
        menu.dispose
        next 99999
      end
    end
    next $game_temp.fly_destination
  }
})

MenuHandlers.add(:pokegear_menu, :phone, {
  "name"      => _INTL("Phone"),
  "icon_name" => "phone",
  "order"     => 20,
#  "condition" => proc { next $PokemonGlobal.phone && $PokemonGlobal.phone.contacts.length > 0 },
  "effect"    => proc { |menu|
    pbFadeOutIn do
      scene = PokemonPhone_Scene.new
      screen = PokemonPhoneScreen.new(scene)
      screen.pbStartScreen
    end
    next false
  }
})

MenuHandlers.add(:pokegear_menu, :jukebox, {
  "name"      => _INTL("Jukebox"),
  "icon_name" => "jukebox",
  "order"     => 30,
  "effect"    => proc { |menu|
    pbFadeOutIn do
      scene = PokemonJukebox_Scene.new
      screen = PokemonJukeboxScreen.new(scene)
      screen.pbStartScreen
    end
    next false
  }
=======

GameData::Stat.register({
  :id         => :HP,
  :name       => _INTL("HP"),
  :name_brief => _INTL("HP"),
  :type       => :main,
  :pbs_order  => 0
})

GameData::Stat.register({
  :id         => :ATTACK,
  :name       => _INTL("Attack"),
  :name_brief => _INTL("Atk"),
  :type       => :main_battle,
  :pbs_order  => 1
})

GameData::Stat.register({
  :id         => :DEFENSE,
  :name       => _INTL("Defense"),
  :name_brief => _INTL("Def"),
  :type       => :main_battle,
  :pbs_order  => 2
})

GameData::Stat.register({
  :id         => :SPECIAL_ATTACK,
  :name       => _INTL("Special Attack"),
  :name_brief => _INTL("SpAtk"),
  :type       => :main_battle,
  :pbs_order  => 4
})

GameData::Stat.register({
  :id         => :SPECIAL_DEFENSE,
  :name       => _INTL("Special Defense"),
  :name_brief => _INTL("SpDef"),
  :type       => :main_battle,
  :pbs_order  => 5
})

GameData::Stat.register({
  :id         => :SPEED,
  :name       => _INTL("Speed"),
  :name_brief => _INTL("Spd"),
  :type       => :main_battle,
  :pbs_order  => 3
})

GameData::Stat.register({
  :id         => :ACCURACY,
  :name       => _INTL("accuracy"),
  :name_brief => _INTL("Acc"),
  :type       => :battle
})

GameData::Stat.register({
  :id         => :EVASION,
  :name       => _INTL("evasiveness"),
  :name_brief => _INTL("Eva"),
  :type       => :battle
>>>>>>> Stashed changes
})
