#===============================================================================
# Command menu (Fight/Pokémon/Bag/Run)
#===============================================================================
class Battle::Scene::CommandMenu < Battle::Scene::MenuBase
  # If true, displays graphics from Graphics/UI/Battle/overlay_command.png
  #     and Graphics/UI/Battle/cursor_command.png.
  # If false, just displays text and the command window over the graphic
  #     Graphics/UI/Battle/overlay_message.png. You will need to edit def
  #     pbShowWindow to make the graphic appear while the command menu is being
  #     displayed.
  USE_GRAPHICS = true
  # Lists of which button graphics to use in different situations/types of battle.
  MODES = [
    [0, 2, 1, 3],   # 0 = Regular battle
    [0, 2, 1, 9],   # 1 = Regular battle with "Cancel" instead of "Run"
    [0, 2, 1, 4],   # 2 = Regular battle with "Call" instead of "Run"
    [5, 7, 6, 3],   # 3 = Safari Zone
    [0, 8, 1, 3],   # 4 = Bug-Catching Contest
	[0, 2, 1, 5]    # 5 = Raid battle
  ]

  def initialize(viewport, z)
    super(viewport)
    self.x = 0
    self.y = Graphics.height - 96
    # Create message box (shows "What will X do?")
    @msgBox = Window_UnformattedTextPokemon.newWithSize(
      "", self.x + 16, self.y + 2, 220, Graphics.height - self.y, viewport
    )
    @msgBox.baseColor   = TEXT_BASE_COLOR
    @msgBox.shadowColor = TEXT_SHADOW_COLOR
    @msgBox.windowskin  = nil
    addSprite("msgBox", @msgBox)
    if USE_GRAPHICS
      # Create background graphic
      background = IconSprite.new(self.x, self.y, viewport)
	  if IASummary::IAVERSION == 1 # Is Pokémon Amethyst
        background.setBitmap("Graphics/UI/Battle/overlay_command_am")
	  elsif IASummary::IAVERSION == 2 # Is Pokémon Iolite
	    background.setBitmap("Graphics/UI/Battle/overlay_command_io")
	  end
      addSprite("background", background)
      # Create bitmaps
      @buttonBitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Battle/cursor_command"))
      # Create action buttons
      @buttons = Array.new(4) do |i|   # 4 command options, therefore 4 buttons
        button = Sprite.new(viewport)
        button.bitmap = @buttonBitmap.bitmap
        button.x = self.x + Graphics.width - 338
        button.x += (i.even? ? 0 : (@buttonBitmap.width / 2) - 4)
        button.y = self.y + 6
        button.y += (((i / 2) == 0) ? 0 : BUTTON_HEIGHT - 4)
        button.src_rect.width  = @buttonBitmap.width / 2
        button.src_rect.height = BUTTON_HEIGHT
        addSprite("button_#{i}", button)
        next button
      end
    else
      # Create command window (shows Fight/Bag/Pokémon/Run)
      @cmdWindow = Window_CommandPokemon.newWithSize(
        [], self.x + Graphics.width - 240, self.y, 240, Graphics.height - self.y, viewport
      )
      @cmdWindow.columns       = 2
      @cmdWindow.columnSpacing = 4
      @cmdWindow.ignore_input  = true
      addSprite("cmdWindow", @cmdWindow)
    end
    self.z = z
    refresh
  end

  def dispose
    super
    @buttonBitmap&.dispose
  end

  def z=(value)
    super
    @msgBox.z    += 1
    @cmdWindow.z += 1 if @cmdWindow
  end

  def setTexts(value)
    @msgBox.text = value[0]
    return if USE_GRAPHICS
    commands = []
    (1..4).each { |i| commands.push(value[i]) if value[i] }
    @cmdWindow.commands = commands
  end

  def refreshButtons
    return if !USE_GRAPHICS
    return if MODES[@mode].nil? || @buttons.nil?
    @buttons.each_with_index do |button, i|
      next if button.nil?
      button.src_rect.x = (i == @index) ? @buttonBitmap.width / 2 : 0
      button.src_rect.y = MODES[@mode][i] * BUTTON_HEIGHT
      button.z          = self.z + ((i == @index) ? 3 : 2)
    end
  end

  def refresh
    @msgBox.refresh
    @cmdWindow&.refresh
    refreshButtons
  end
end