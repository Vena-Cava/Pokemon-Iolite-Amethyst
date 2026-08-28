<<<<<<< Updated upstream
#===============================================================================
#
#===============================================================================
class Window_CharacterEntry < Window_DrawableCommand
  XSIZE = 13
  YSIZE = 4

  def initialize(charset, viewport = nil)
    @viewport = viewport
    @charset = charset
    @othercharset = ""
    super(0, 96, 480, 192)
    colors = getDefaultTextColors(self.windowskin)
    self.baseColor = colors[0]
    self.shadowColor = colors[1]
    self.columns = XSIZE
    refresh
  end

  def setOtherCharset(value)
    @othercharset = value.clone
    refresh
  end

  def setCharset(value)
    @charset = value.clone
    refresh
  end

  def character
    if self.index < 0 || self.index >= @charset.length
      return ""
    else
      return @charset[self.index]
    end
  end

  def command
    return -1 if self.index == @charset.length
    return -2 if self.index == @charset.length + 1
    return -3 if self.index == @charset.length + 2
    return self.index
  end

  def itemCount
    return @charset.length + 3
  end

  def drawItem(index, _count, rect)
    rect = drawCursor(index, rect)
    if index == @charset.length # -1
      pbDrawShadowText(self.contents, rect.x, rect.y, rect.width, rect.height, "[ ]",
                       self.baseColor, self.shadowColor)
    elsif index == @charset.length + 1 # -2
      pbDrawShadowText(self.contents, rect.x, rect.y, rect.width, rect.height, @othercharset,
                       self.baseColor, self.shadowColor)
    elsif index == @charset.length + 2 # -3
      pbDrawShadowText(self.contents, rect.x, rect.y, rect.width, rect.height, _INTL("OK"),
                       self.baseColor, self.shadowColor)
    else
      pbDrawShadowText(self.contents, rect.x, rect.y, rect.width, rect.height, @charset[index],
                       self.baseColor, self.shadowColor)
=======
# NOTE: If adding a new target, you will need to add code in several places to
#       make them work properly:
#         - def pbFindTargets
#         - def pbMoveCanTarget?
#         - def pbCreateTargetTexts
#         - def pbFirstTarget
#         - def pbTargetsMultiple?
module GameData
  class Target
    attr_reader :id
    attr_reader :real_name
    attr_reader :num_targets        # 0, 1 or 2 (meaning 2+)
    attr_reader :targets_foe        # Is able to target one or more foes
    attr_reader :targets_all        # Crafty Shield can't protect from these moves
    attr_reader :affects_foe_side   # Pressure also affects these moves
    attr_reader :long_range         # Hits non-adjacent targets

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id               = hash[:id]
      @real_name        = hash[:name]             || "Unnamed"
      @num_targets      = hash[:num_targets]      || 0
      @targets_foe      = hash[:targets_foe]      || false
      @targets_all      = hash[:targets_all]      || false
      @affects_foe_side = hash[:affects_foe_side] || false
      @long_range       = hash[:long_range]       || false
    end

    # @return [String] the translated name of this target
    def name
      return _INTL(@real_name)
    end

    def can_choose_distant_target?
      return @num_targets == 1 && @long_range
    end

    def can_target_one_foe?
      return @num_targets == 1 && @targets_foe
>>>>>>> Stashed changes
    end
  end
end

#===============================================================================
<<<<<<< Updated upstream
# Text entry screen - free typing.
#===============================================================================
class PokemonEntryScene
  @@Characters = [
    [("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz").scan(/./), "[*]"],
    [("0123456789   !@\#$%^&*()   ~`-_+={}[]   :;'\"<>,.?/   ").scan(/./), "[A]"]
  ]
  USEKEYBOARD = true

  def pbStartScene(helptext, minlength, maxlength, initialText, subject = 0, pokemon = nil)
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    if USEKEYBOARD
      @sprites["entry"] = Window_TextEntry_Keyboard.new(
        initialText, 0, 0, 400 - 112, 96, helptext, true
      )
      Input.text_input = true
    else
      @sprites["entry"] = Window_TextEntry.new(initialText, 0, 0, 400, 96, helptext, true)
    end
    @sprites["entry"].x = (Graphics.width / 2) - (@sprites["entry"].width / 2) + 32
    @sprites["entry"].viewport = @viewport
    @sprites["entry"].visible = true
    @minlength = minlength
    @maxlength = maxlength
    @symtype = 0
    @sprites["entry"].maxlength = maxlength
    if !USEKEYBOARD
      @sprites["entry2"] = Window_CharacterEntry.new(@@Characters[@symtype][0])
      @sprites["entry2"].setOtherCharset(@@Characters[@symtype][1])
      @sprites["entry2"].viewport = @viewport
      @sprites["entry2"].visible = true
      @sprites["entry2"].x = (Graphics.width / 2) - (@sprites["entry2"].width / 2)
    end
    if minlength == 0
      @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize(
        _INTL("Enter text using the keyboard. Press\nEnter to confirm, or Esc to cancel."),
        32, Graphics.height - 96, Graphics.width - 64, 96, @viewport
      )
    else
      @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize(
        _INTL("Enter text using the keyboard.\nPress Enter to confirm."),
        32, Graphics.height - 96, Graphics.width - 64, 96, @viewport
      )
    end
    @sprites["helpwindow"].letterbyletter = false
    @sprites["helpwindow"].viewport = @viewport
    @sprites["helpwindow"].visible = USEKEYBOARD
    @sprites["helpwindow"].baseColor = Color.new(16, 24, 32)
    @sprites["helpwindow"].shadowColor = Color.new(168, 184, 184)
    addBackgroundPlane(@sprites, "background", "Naming/bg_2", @viewport)
    case subject
    when 1   # Player
      meta = GameData::PlayerMetadata.get($player.character_ID)
      if meta
        @sprites["shadow"] = IconSprite.new(0, 0, @viewport)
        @sprites["shadow"].setBitmap("Graphics/UI/Naming/icon_shadow")
        @sprites["shadow"].x = 66
        @sprites["shadow"].y = 64
        filename = pbGetPlayerCharset(meta.walk_charset, nil, true)
        @sprites["subject"] = TrainerWalkingCharSprite.new(filename, @viewport)
        charwidth = @sprites["subject"].bitmap.width
        charheight = @sprites["subject"].bitmap.height
        @sprites["subject"].x = 88 - (charwidth / 8)
        @sprites["subject"].y = 76 - (charheight / 4)
      end
    when 2   # Pokémon
      if pokemon
        @sprites["shadow"] = IconSprite.new(0, 0, @viewport)
        @sprites["shadow"].setBitmap("Graphics/UI/Naming/icon_shadow")
        @sprites["shadow"].x = 66
        @sprites["shadow"].y = 64
        @sprites["subject"] = PokemonIconSprite.new(pokemon, @viewport)
        @sprites["subject"].setOffset(PictureOrigin::CENTER)
        @sprites["subject"].x = 88
        @sprites["subject"].y = 54
        @sprites["gender"] = BitmapSprite.new(32, 32, @viewport)
        @sprites["gender"].x = 430
        @sprites["gender"].y = 54
        @sprites["gender"].bitmap.clear
        pbSetSystemFont(@sprites["gender"].bitmap)
        textpos = []
        if pokemon.male?
          textpos.push([_INTL("♂"), 0, 6, :left, Color.new(0, 128, 248), Color.new(168, 184, 184)])
        elsif pokemon.female?
          textpos.push([_INTL("♀"), 0, 6, :left, Color.new(248, 24, 24), Color.new(168, 184, 184)])
        end
        pbDrawTextPositions(@sprites["gender"].bitmap, textpos)
      end
    when 3   # NPC
      @sprites["shadow"] = IconSprite.new(0, 0, @viewport)
      @sprites["shadow"].setBitmap("Graphics/UI/Naming/icon_shadow")
      @sprites["shadow"].x = 66
      @sprites["shadow"].y = 64
      @sprites["subject"] = TrainerWalkingCharSprite.new(pokemon.to_s, @viewport)
      charwidth = @sprites["subject"].bitmap.width
      charheight = @sprites["subject"].bitmap.height
      @sprites["subject"].x = 88 - (charwidth / 8)
      @sprites["subject"].y = 76 - (charheight / 4)
    when 4   # Storage box
      @sprites["subject"] = TrainerWalkingCharSprite.new(nil, @viewport)
      @sprites["subject"].altcharset = "Graphics/UI/Naming/icon_storage"
      @sprites["subject"].anim_duration = 0.4
      charwidth = @sprites["subject"].bitmap.width
      charheight = @sprites["subject"].bitmap.height
      @sprites["subject"].x = 88 - (charwidth / 8)
      @sprites["subject"].y = 52 - (charheight / 2)
    end
    pbFadeInAndShow(@sprites)
  end

  def pbEntry1
    ret = ""
    loop do
      Graphics.update
      Input.update
      if Input.triggerex?(:ESCAPE) && @minlength == 0
        ret = ""
        break
      elsif Input.triggerex?(:RETURN) && @sprites["entry"].text.length >= @minlength
        ret = @sprites["entry"].text
        break
      end
      @sprites["helpwindow"].update
      @sprites["entry"].update
      @sprites["subject"]&.update
    end
    Input.update
    return ret
  end

  def pbEntry2
    ret = ""
    loop do
      Graphics.update
      Input.update
      @sprites["helpwindow"].update
      @sprites["entry"].update
      @sprites["entry2"].update
      @sprites["subject"]&.update
      if Keybinds.press?(:use)
        index = @sprites["entry2"].command
        if index == -3 # Confirm text
          ret = @sprites["entry"].text
          if ret.length < @minlength || ret.length > @maxlength
            pbPlayBuzzerSE
          else
            pbPlayDecisionSE
            break
          end
        elsif index == -1   # Insert a space
          if @sprites["entry"].insert(" ")
            pbPlayDecisionSE
          else
            pbPlayBuzzerSE
          end
        elsif index == -2   # Change character set
          pbPlayDecisionSE
          @symtype += 1
          @symtype = 0 if @symtype >= @@Characters.length
          @sprites["entry2"].setCharset(@@Characters[@symtype][0])
          @sprites["entry2"].setOtherCharset(@@Characters[@symtype][1])
        else   # Insert given character
          if @sprites["entry"].insert(@sprites["entry2"].character)
            pbPlayDecisionSE
          else
            pbPlayBuzzerSE
          end
        end
        next
      end
    end
    Input.update
    return ret
  end

  def pbEntry
    return USEKEYBOARD ? pbEntry1 : pbEntry2
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    Input.text_input = false if USEKEYBOARD
  end
end

#===============================================================================
# Text entry screen - arrows to select letter.
#===============================================================================
class PokemonEntryScene2
  @@Characters = [
    [("ABCDEFGHIJ ,." + "KLMNOPQRST '-" + "UVWXYZ     ♂♀" + "             " + "0123456789   ").scan(/./), _INTL("UPPER")],
    [("abcdefghij ,." + "klmnopqrst '-" + "uvwxyz     ♂♀" + "             " + "0123456789   ").scan(/./), _INTL("lower")],
    [("ÀÁÂÄÃàáâäã Ææ" + "ÈÉÊË èéêë  Çç" + "ÌÍÎÏ ìíîï  Œœ" + "ÒÓÔÖÕòóôöõ Ññ" + "ÙÚÛÜ ùúûü  Ýý").scan(/./), _INTL("accents")],
    [(",.:;…•!?¡¿ ♂♀" + "“”‘’﴾﴿*~_^ ΡΚ" + "@\#&%+-×÷/= ΠΜ" + "◎○□△♠♥♦♣★✨  $" + "♈♌♒♐♩♪♫☽☾    ").scan(/./), _INTL("other")]
  ]
  ROWS    = 13
  COLUMNS = 5
  MODE1   = -6
  MODE2   = -5
  MODE3   = -4
  MODE4   = -3
  BACK    = -2
  OK      = -1

  class NameEntryCursor
    def initialize(viewport)
      @sprite = Sprite.new(viewport)
      @cursortype = 0
      @cursor1 = AnimatedBitmap.new("Graphics/UI/Naming/cursor_1")
      @cursor2 = AnimatedBitmap.new("Graphics/UI/Naming/cursor_2")
      @cursor3 = AnimatedBitmap.new("Graphics/UI/Naming/cursor_3")
      @cursorPos = 0
      updateInternal
    end

    def setCursorPos(value)
      @cursorPos = value
    end

    def updateCursorPos
      value = @cursorPos
      case value
      when PokemonEntryScene2::MODE1   # Upper case
        @sprite.x = 44
        @sprite.y = 120
        @cursortype = 1
      when PokemonEntryScene2::MODE2   # Lower case
        @sprite.x = 106
        @sprite.y = 120
        @cursortype = 1
      when PokemonEntryScene2::MODE3   # Accents
        @sprite.x = 168
        @sprite.y = 120
        @cursortype = 1
      when PokemonEntryScene2::MODE4   # Other symbols
        @sprite.x = 230
        @sprite.y = 120
        @cursortype = 1
      when PokemonEntryScene2::BACK   # Back
        @sprite.x = 314
        @sprite.y = 120
        @cursortype = 2
      when PokemonEntryScene2::OK   # OK
        @sprite.x = 394
        @sprite.y = 120
        @cursortype = 2
      else
        if value >= 0
          @sprite.x = 52 + (32 * (value % PokemonEntryScene2::ROWS))
          @sprite.y = 180 + (38 * (value / PokemonEntryScene2::ROWS))
          @cursortype = 0
        end
      end
    end

    def visible=(value)
      @sprite.visible = value
    end

    def visible
      @sprite.visible
    end

    def color=(value)
      @sprite.color = value
    end

    def color
      @sprite.color
    end

    def disposed?
      @sprite.disposed?
    end

    def updateInternal
      @cursor1.update
      @cursor2.update
      @cursor3.update
      updateCursorPos
      case @cursortype
      when 0 then @sprite.bitmap = @cursor1.bitmap
      when 1 then @sprite.bitmap = @cursor2.bitmap
      when 2 then @sprite.bitmap = @cursor3.bitmap
      end
    end

    def update
      updateInternal
    end

    def dispose
      @cursor1.dispose
      @cursor2.dispose
      @cursor3.dispose
      @sprite.dispose
    end
  end

  def pbStartScene(helptext, minlength, maxlength, initialText, subject = 0, pokemon = nil)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @helptext = helptext
    @helper = CharacterEntryHelper.new(initialText)
    # Create bitmaps
    @bitmaps = []
    @@Characters.length.times do |i|
      @bitmaps[i] = AnimatedBitmap.new(sprintf("Graphics/UI/Naming/overlay_tab_%d", i + 1))
      b = @bitmaps[i].bitmap.clone
      pbSetSystemFont(b)
      textPos = []
      COLUMNS.times do |y|
        ROWS.times do |x|
          pos = (y * ROWS) + x
          textPos.push([@@Characters[i][0][pos], 44 + (x * 32), 24 + (y * 38), :center,
                        Color.new(16, 24, 32), Color.new(160, 160, 160)])
        end
      end
      pbDrawTextPositions(b, textPos)
      @bitmaps[@@Characters.length + i] = b
    end
    underline_bitmap = Bitmap.new(24, 6)
    underline_bitmap.fill_rect(2, 2, 22, 4, Color.new(168, 184, 184))
    underline_bitmap.fill_rect(0, 0, 22, 4, Color.new(16, 24, 32))
    @bitmaps.push(underline_bitmap)
    # Create sprites
    @sprites = {}
    @sprites["bg"] = IconSprite.new(0, 0, @viewport)
    @sprites["bg"].setBitmap("Graphics/UI/Naming/bg")
    case subject
    when 1   # Player
      meta = GameData::PlayerMetadata.get($player.character_ID)
      if meta
        @sprites["shadow"] = IconSprite.new(0, 0, @viewport)
        @sprites["shadow"].setBitmap("Graphics/UI/Naming/icon_shadow")
        @sprites["shadow"].x = 66
        @sprites["shadow"].y = 64
        filename = pbGetPlayerCharset(meta.walk_charset, nil, true)
        @sprites["subject"] = TrainerWalkingCharSprite.new(filename, @viewport)
        charwidth = @sprites["subject"].bitmap.width
        charheight = @sprites["subject"].bitmap.height
        @sprites["subject"].x = 88 - (charwidth / 8)
        @sprites["subject"].y = 76 - (charheight / 4)
      end
    when 2   # Pokémon
      if pokemon
        @sprites["shadow"] = IconSprite.new(0, 0, @viewport)
        @sprites["shadow"].setBitmap("Graphics/UI/Naming/icon_shadow")
        @sprites["shadow"].x = 66
        @sprites["shadow"].y = 64
        @sprites["subject"] = PokemonIconSprite.new(pokemon, @viewport)
        @sprites["subject"].setOffset(PictureOrigin::CENTER)
        @sprites["subject"].x = 88
        @sprites["subject"].y = 54
        @sprites["gender"] = BitmapSprite.new(32, 32, @viewport)
        @sprites["gender"].x = 430
        @sprites["gender"].y = 54
        @sprites["gender"].bitmap.clear
        pbSetSystemFont(@sprites["gender"].bitmap)
        textpos = []
        if pokemon.male?
          textpos.push([_INTL("♂"), 0, 6, :left, Color.new(0, 128, 248), Color.new(168, 184, 184)])
        elsif pokemon.female?
          textpos.push([_INTL("♀"), 0, 6, :left, Color.new(248, 24, 24), Color.new(168, 184, 184)])
        end
        pbDrawTextPositions(@sprites["gender"].bitmap, textpos)
      end
    when 3   # NPC
      @sprites["shadow"] = IconSprite.new(0, 0, @viewport)
      @sprites["shadow"].setBitmap("Graphics/UI/Naming/icon_shadow")
      @sprites["shadow"].x = 66
      @sprites["shadow"].y = 64
      @sprites["subject"] = TrainerWalkingCharSprite.new(pokemon.to_s, @viewport)
      charwidth = @sprites["subject"].bitmap.width
      charheight = @sprites["subject"].bitmap.height
      @sprites["subject"].x = 88 - (charwidth / 8)
      @sprites["subject"].y = 76 - (charheight / 4)
    when 4   # Storage box
      @sprites["subject"] = TrainerWalkingCharSprite.new(nil, @viewport)
      @sprites["subject"].altcharset = "Graphics/UI/Naming/icon_storage"
      @sprites["subject"].anim_duration = 0.4
      charwidth = @sprites["subject"].bitmap.width
      charheight = @sprites["subject"].bitmap.height
      @sprites["subject"].x = 88 - (charwidth / 8)
      @sprites["subject"].y = 52 - (charheight / 2)
    end
    @sprites["bgoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbDoUpdateOverlay
    @blanks = []
    @mode = 0
    @minlength = minlength
    @maxlength = maxlength
    @maxlength.times do |i|
      @sprites["blank#{i}"] = Sprite.new(@viewport)
      @sprites["blank#{i}"].x = 160 + (24 * i)
      @sprites["blank#{i}"].bitmap = @bitmaps[@bitmaps.length - 1]
      @blanks[i] = 0
    end
    @sprites["bottomtab"] = Sprite.new(@viewport)   # Current tab
    @sprites["bottomtab"].x = 22
    @sprites["bottomtab"].y = 162
    @sprites["bottomtab"].bitmap = @bitmaps[@@Characters.length]
    @sprites["toptab"] = Sprite.new(@viewport)   # Next tab
    @sprites["toptab"].x = 22 - 504
    @sprites["toptab"].y = 162
    @sprites["toptab"].bitmap = @bitmaps[@@Characters.length + 1]
    @sprites["controls"] = IconSprite.new(0, 0, @viewport)
    @sprites["controls"].x = 16
    @sprites["controls"].y = 96
    @sprites["controls"].setBitmap(_INTL("Graphics/UI/Naming/overlay_controls"))
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbDoUpdateOverlay2
    @sprites["cursor"] = NameEntryCursor.new(@viewport)
    @cursorpos = 0
    @refreshOverlay = true
    @sprites["cursor"].setCursorPos(@cursorpos)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbUpdateOverlay
    @refreshOverlay = true
  end

  def pbDoUpdateOverlay2
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    modeIcon = [[_INTL("Graphics/UI/Naming/icon_mode"), 44 + (@mode * 62), 120, @mode * 60, 0, 60, 44]]
    pbDrawImagePositions(overlay, modeIcon)
  end

  def pbDoUpdateOverlay
    return if !@refreshOverlay
    @refreshOverlay = false
    bgoverlay = @sprites["bgoverlay"].bitmap
    bgoverlay.clear
    pbSetSystemFont(bgoverlay)
    textPositions = [
      [@helptext, 160, 18, :left, Color.new(16, 24, 32), Color.new(168, 184, 184)]
    ]
    chars = @helper.textChars
    x = 172
    chars.each do |ch|
      textPositions.push([ch, x, 54, :center, Color.new(16, 24, 32), Color.new(168, 184, 184)])
      x += 24
    end
    pbDrawTextPositions(bgoverlay, textPositions)
  end

  def pbChangeTab(newtab = @mode + 1)
    pbSEPlay("GUI naming tab swap start")
    @sprites["cursor"].visible = false
    @sprites["toptab"].bitmap = @bitmaps[(newtab % @@Characters.length) + @@Characters.length]
    # Move bottom (old) tab down off the screen, and move top (new) tab right
    # onto the screen
    timer_start = System.uptime
    loop do
      @sprites["bottomtab"].y = lerp(162, 414, 0.5, timer_start, System.uptime)
      @sprites["toptab"].x = lerp(22 - 504, 22, 0.5, timer_start, System.uptime)
      Graphics.update
      Input.update
      pbUpdate
      break if @sprites["toptab"].x >= 22 && @sprites["bottomtab"].y >= 414
    end
    # Swap top and bottom tab around
    @sprites["toptab"].x, @sprites["bottomtab"].x = @sprites["bottomtab"].x, @sprites["toptab"].x
    @sprites["toptab"].y, @sprites["bottomtab"].y = @sprites["bottomtab"].y, @sprites["toptab"].y
    @sprites["toptab"].bitmap, @sprites["bottomtab"].bitmap = @sprites["bottomtab"].bitmap, @sprites["toptab"].bitmap
    Graphics.update
    Input.update
    pbUpdate
    # Set the current mode
    @mode = newtab % @@Characters.length
    # Set the top tab up to be the next tab
    newtab = @bitmaps[((@mode + 1) % @@Characters.length) + @@Characters.length]
    @sprites["cursor"].visible = true
    @sprites["toptab"].bitmap = newtab
    @sprites["toptab"].x = 22 - 504
    @sprites["toptab"].y = 162
    pbSEPlay("GUI naming tab swap end")
    pbDoUpdateOverlay2
  end

  def pbUpdate
    @@Characters.length.times do |i|
      @bitmaps[i].update
    end
    # Update which inputted text's character's underline is lowered to indicate
    # which character is selected
    cursorpos = @helper.cursor.clamp(0, @maxlength - 1)
    @maxlength.times do |i|
      @blanks[i] = (i == cursorpos) ? 1 : 0
      @sprites["blank#{i}"].y = [78, 82][@blanks[i]]
    end
    pbDoUpdateOverlay
    pbUpdateSpriteHash(@sprites)
  end

  def pbColumnEmpty?(m)
    return false if m >= ROWS - 1
    chset = @@Characters[@mode][0]
    COLUMNS.times do |i|
      return false if chset[(i * ROWS) + m] != " "
    end
    return true
  end

  def wrapmod(x, y)
    result = x % y
    result += y if result < 0
    return result
  end

  def pbMoveCursor
    oldcursor = @cursorpos
    cursordiv = @cursorpos / ROWS   # The row the cursor is in
    cursormod = @cursorpos % ROWS   # The column the cursor is in
    cursororigin = @cursorpos - cursormod
    if Keybinds.repeat?(:left)
      if @cursorpos < 0   # Controls
        @cursorpos -= 1
        @cursorpos = OK if @cursorpos < MODE1
      else
        loop do
          cursormod = wrapmod(cursormod - 1, ROWS)
          @cursorpos = cursororigin + cursormod
          break unless pbColumnEmpty?(cursormod)
        end
      end
    elsif Keybinds.repeat?(:right)
      if @cursorpos < 0   # Controls
        @cursorpos += 1
        @cursorpos = MODE1 if @cursorpos > OK
      else
        loop do
          cursormod = wrapmod(cursormod + 1, ROWS)
          @cursorpos = cursororigin + cursormod
          break unless pbColumnEmpty?(cursormod)
        end
      end
    elsif Keybinds.repeat?(:up)
      if @cursorpos < 0         # Controls
        case @cursorpos
        when MODE1 then @cursorpos = ROWS * (COLUMNS - 1)
        when MODE2 then @cursorpos = (ROWS * (COLUMNS - 1)) + 2
        when MODE3 then @cursorpos = (ROWS * (COLUMNS - 1)) + 4
        when MODE4 then @cursorpos = (ROWS * (COLUMNS - 1)) + 6
        when BACK  then @cursorpos = (ROWS * (COLUMNS - 1)) + 9
        when OK    then @cursorpos = (ROWS * (COLUMNS - 1)) + 11
        end
      elsif @cursorpos < ROWS   # Top row of letters
        case @cursorpos
        when 0, 1     then @cursorpos = MODE1
        when 2, 3     then @cursorpos = MODE2
        when 4, 5     then @cursorpos = MODE3
        when 6, 7     then @cursorpos = MODE4
        when 8, 9, 10 then @cursorpos = BACK
        when 11, 12   then @cursorpos = OK
        end
      else
        cursordiv = wrapmod(cursordiv - 1, COLUMNS)
        @cursorpos = (cursordiv * ROWS) + cursormod
      end
    elsif Keybinds.repeat?(:down)
      if @cursorpos < 0                      # Controls
        case @cursorpos
        when MODE1 then @cursorpos = 0
        when MODE2 then @cursorpos = 2
        when MODE3 then @cursorpos = 4
        when MODE4 then @cursorpos = 6
        when BACK  then @cursorpos = 9
        when OK    then @cursorpos = 11
        end
      elsif @cursorpos >= ROWS * (COLUMNS - 1)   # Bottom row of letters
        case cursormod
        when 0, 1     then @cursorpos = MODE1
        when 2, 3     then @cursorpos = MODE2
        when 4, 5     then @cursorpos = MODE3
        when 6, 7     then @cursorpos = MODE4
        when 8, 9, 10 then @cursorpos = BACK
        else               @cursorpos = OK
        end
      else
        cursordiv = wrapmod(cursordiv + 1, COLUMNS)
        @cursorpos = (cursordiv * ROWS) + cursormod
      end
    end
    if @cursorpos != oldcursor   # Cursor position changed
      @sprites["cursor"].setCursorPos(@cursorpos)
      pbPlayCursorSE
      return true
    end
    return false
  end

  def pbEntry
    ret = ""
    loop do
      Graphics.update
      Input.update
      pbUpdate
      next if pbMoveCursor
      if Keybinds.trigger?(:special)
        pbChangeTab
      elsif Keybinds.trigger?(:action)
        @cursorpos = OK
        @sprites["cursor"].setCursorPos(@cursorpos)
      elsif Keybinds.trigger?(:back) || Input.triggerex?(:BACKSPACE)
        @helper.delete
        pbPlayCancelSE
        pbUpdateOverlay
      elsif Keybinds.trigger?(:use)
        case @cursorpos
        when BACK   # Backspace
          @helper.delete
          pbPlayCancelSE
          pbUpdateOverlay
        when OK     # Done
          pbSEPlay("GUI naming confirm")
          if @helper.length >= @minlength
            ret = @helper.text
            break
          end
        when MODE1
          pbChangeTab(0) if @mode != 0
        when MODE2
          pbChangeTab(1) if @mode != 1
        when MODE3
          pbChangeTab(2) if @mode != 2
        when MODE4
          pbChangeTab(3) if @mode != 3
        else
          cursormod = @cursorpos % ROWS
          cursordiv = @cursorpos / ROWS
          charpos = (cursordiv * ROWS) + cursormod
          chset = @@Characters[@mode][0]
          @helper.delete if @helper.length >= @maxlength
          @helper.insert(chset[charpos])
          pbPlayCursorSE
          if @helper.length >= @maxlength
            @cursorpos = OK
            @sprites["cursor"].setCursorPos(@cursorpos)
          end
          pbUpdateOverlay
          # Auto-switch to lowercase letters after the first uppercase letter is selected
          pbChangeTab(1) if @mode == 0 && @helper.cursor == 1
        end
      end
    end
    Input.update
    return ret
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    @bitmaps.each do |bitmap|
      bitmap&.dispose
    end
    @bitmaps.clear
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonEntry
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(helptext, minlength, maxlength, initialText, mode = -1, pokemon = nil)
    @scene.pbStartScene(helptext, minlength, maxlength, initialText, mode, pokemon)
    ret = @scene.pbEntry
    @scene.pbEndScene
    return ret
  end
end

#===============================================================================
#
#===============================================================================
def pbEnterText(helptext, minlength, maxlength, initialText = "", mode = 0, pokemon = nil, nofadeout = false)
  ret = ""
  if ($PokemonSystem.textinput == 1 rescue false)   # Keyboard
    pbFadeOutIn(99999, nofadeout) do
      sscene = PokemonEntryScene.new
      sscreen = PokemonEntry.new(sscene)
      ret = sscreen.pbStartScreen(helptext, minlength, maxlength, initialText, mode, pokemon)
    end
  else   # Cursor
    pbFadeOutIn(99999, nofadeout) do
      sscene = PokemonEntryScene2.new
      sscreen = PokemonEntry.new(sscene)
      ret = sscreen.pbStartScreen(helptext, minlength, maxlength, initialText, mode, pokemon)
    end
  end
  return ret
end

def pbEnterPlayerName(helptext, minlength, maxlength, initialText = "", nofadeout = false)
  return pbEnterText(helptext, minlength, maxlength, initialText, 1, nil, nofadeout)
end

def pbEnterPokemonName(helptext, minlength, maxlength, initialText = "", pokemon = nil, nofadeout = false)
  return pbEnterText(helptext, minlength, maxlength, initialText, 2, pokemon, nofadeout)
end

def pbEnterNPCName(helptext, minlength, maxlength, initialText = "", id = 0, nofadeout = false)
  return pbEnterText(helptext, minlength, maxlength, initialText, 3, id, nofadeout)
end

def pbEnterBoxName(helptext, minlength, maxlength, initialText = "", nofadeout = false)
  return pbEnterText(helptext, minlength, maxlength, initialText, 4, nil, nofadeout)
end
=======

# Bide, Counter, Metal Burst, Mirror Coat (calculate a target)
GameData::Target.register({
  :id               => :None,
  :name             => _INTL("None")
})

GameData::Target.register({
  :id               => :User,
  :name             => _INTL("User")
})

# Aromatic Mist, Helping Hand, Hold Hands
GameData::Target.register({
  :id               => :NearAlly,
  :name             => _INTL("Near Ally"),
  :num_targets      => 1
})

# Acupressure
GameData::Target.register({
  :id               => :UserOrNearAlly,
  :name             => _INTL("User or Near Ally"),
  :num_targets      => 1
})

# Coaching
GameData::Target.register({
  :id               => :AllAllies,
  :name             => _INTL("All Allies"),
  :num_targets      => 2,
  :targets_all      => true,
  :long_range       => true
})

# Aromatherapy, Gear Up, Heal Bell, Life Dew, Magnetic Flux, Howl (in Gen 8+)
GameData::Target.register({
  :id               => :UserAndAllies,
  :name             => _INTL("User and Allies"),
  :num_targets      => 2,
  :long_range       => true
})

# Me First
GameData::Target.register({
  :id               => :NearFoe,
  :name             => _INTL("Near Foe"),
  :num_targets      => 1,
  :targets_foe      => true
})

# Petal Dance, Outrage, Struggle, Thrash, Uproar
GameData::Target.register({
  :id               => :RandomNearFoe,
  :name             => _INTL("Random Near Foe"),
  :num_targets      => 1,
  :targets_foe      => true
})

GameData::Target.register({
  :id               => :AllNearFoes,
  :name             => _INTL("All Near Foes"),
  :num_targets      => 2,
  :targets_foe      => true
})

# For throwing a Poké Ball
GameData::Target.register({
  :id               => :Foe,
  :name             => _INTL("Foe"),
  :num_targets      => 1,
  :targets_foe      => true,
  :long_range       => true
})

# Unused
GameData::Target.register({
  :id               => :AllFoes,
  :name             => _INTL("All Foes"),
  :num_targets      => 2,
  :targets_foe      => true,
  :long_range       => true
})

GameData::Target.register({
  :id               => :NearOther,
  :name             => _INTL("Near Other"),
  :num_targets      => 1,
  :targets_foe      => true
})

GameData::Target.register({
  :id               => :AllNearOthers,
  :name             => _INTL("All Near Others"),
  :num_targets      => 2,
  :targets_foe      => true
})

# Most Flying-type moves, pulse moves (hits non-near targets)
GameData::Target.register({
  :id               => :Other,
  :name             => _INTL("Other"),
  :num_targets      => 1,
  :targets_foe      => true,
  :long_range       => true
})

# Flower Shield, Perish Song, Rototiller, Teatime
GameData::Target.register({
  :id               => :AllBattlers,
  :name             => _INTL("All Battlers"),
  :num_targets      => 2,
  :targets_foe      => true,
  :targets_all      => true,
  :long_range       => true
})

GameData::Target.register({
  :id               => :UserSide,
  :name             => _INTL("User Side")
})

# Entry hazards
GameData::Target.register({
  :id               => :FoeSide,
  :name             => _INTL("Foe Side"),
  :affects_foe_side => true
})

GameData::Target.register({
  :id               => :BothSides,
  :name             => _INTL("Both Sides"),
  :affects_foe_side => true
})
>>>>>>> Stashed changes
