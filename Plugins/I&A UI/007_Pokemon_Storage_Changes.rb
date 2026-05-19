#===============================================================================
# Iolite & Amethyst Pokémon Storage Screen
#===============================================================================
class PokemonBoxIcon < IconSprite
  def initialize(pokemon, viewport = nil)
    super(0, 0, viewport)
    @pokemon = pokemon
    @release_timer_start = nil
    refresh
  end

  def releasing?
    return !@release_timer_start.nil?
  end

  def release
    self.ox = self.src_rect.width / 2    # 32
    self.oy = self.src_rect.height / 2   # 32
    self.x += self.src_rect.width / 2    # 32
    self.y += self.src_rect.height / 2   # 32
    @release_timer_start = System.uptime
  end

  def refresh
    return if !@pokemon
    self.setBitmap(GameData::Species.icon_filename_from_pokemon(@pokemon))
    self.src_rect = Rect.new(0, 0, self.bitmap.height, self.bitmap.height)
  end

  def update
    super
    self.color = Color.new(0, 0, 0, 0)
    if releasing?
      time_now = System.uptime
      self.zoom_x = lerp(1.0, 0.0, 1.5, @release_timer_start, System.uptime)
      self.zoom_y = self.zoom_x
      self.opacity = lerp(255, 0, 1.5, @release_timer_start, System.uptime)
      if self.opacity == 0
        @release_timer_start = nil
        dispose
      end
    end
  end
end

#===============================================================================
# Pokémon sprite
#===============================================================================
class MosaicPokemonSprite < PokemonSprite
  attr_reader :mosaic

  def initialize(*args)
    super(*args)
    @mosaic = 0
    @inrefresh = false
    @mosaicbitmap = nil
    @mosaicbitmap2 = nil
    @oldbitmap = self.bitmap
  end

  def dispose
    super
    @mosaicbitmap&.dispose
    @mosaicbitmap = nil
    @mosaicbitmap2&.dispose
    @mosaicbitmap2 = nil
  end

  def bitmap=(value)
    super
    mosaicRefresh(value)
  end

  def mosaic=(value)
    @mosaic = value
    @mosaic = 0 if @mosaic < 0
    mosaicRefresh(@oldbitmap)
  end

  def mosaicRefresh(bitmap)
    return if @inrefresh
    @inrefresh = true
    @oldbitmap = bitmap
    if @mosaic <= 0 || !@oldbitmap
      @mosaicbitmap&.dispose
      @mosaicbitmap = nil
      @mosaicbitmap2&.dispose
      @mosaicbitmap2 = nil
      self.bitmap = @oldbitmap
    else
      newWidth  = [(@oldbitmap.width / @mosaic), 1].max
      newHeight = [(@oldbitmap.height / @mosaic), 1].max
      @mosaicbitmap2&.dispose
      @mosaicbitmap = pbDoEnsureBitmap(@mosaicbitmap, newWidth, newHeight)
      @mosaicbitmap.clear
      @mosaicbitmap2 = pbDoEnsureBitmap(@mosaicbitmap2, @oldbitmap.width, @oldbitmap.height)
      @mosaicbitmap2.clear
      @mosaicbitmap.stretch_blt(Rect.new(0, 0, newWidth, newHeight), @oldbitmap, @oldbitmap.rect)
      @mosaicbitmap2.stretch_blt(
        Rect.new((-@mosaic / 2) + 1, (-@mosaic / 2) + 1, @mosaicbitmap2.width, @mosaicbitmap2.height),
        @mosaicbitmap, Rect.new(0, 0, newWidth, newHeight)
      )
      self.bitmap = @mosaicbitmap2
    end
    @inrefresh = false
  end
end

#===============================================================================
#
#===============================================================================
class AutoMosaicPokemonSprite < MosaicPokemonSprite
  INITIAL_MOSAIC = 10   # Pixellation factor

  def mosaic=(value)
    @mosaic = value
    @mosaic = 0 if @mosaic < 0
    @start_mosaic = @mosaic if !@start_mosaic
  end

  def mosaic_duration=(val)
    @mosaic_duration = val
    @mosaic_duration = 0 if @mosaic_duration < 0
    @mosaic_timer_start = System.uptime if @mosaic_duration > 0
  end

  def update
    super
    if @mosaic_timer_start
      @start_mosaic = INITIAL_MOSAIC if !@start_mosaic || @start_mosaic == 0
      new_mosaic = lerp(@start_mosaic, 0, @mosaic_duration, @mosaic_timer_start, System.uptime).to_i
      self.mosaic = new_mosaic
      mosaicRefresh(@oldbitmap)
      if new_mosaic == 0
        @mosaic_timer_start = nil
        @start_mosaic = nil
      end
    end
  end
end

#===============================================================================
# Cursor
#===============================================================================
class PokemonBoxArrow < Sprite
  attr_accessor :quickswap

  # Time in seconds for the cursor to move down and back up to grab/drop a
  # Pokémon.
  GRAB_TIME = 0.4

  def initialize(viewport = nil)
    super(viewport)
    @holding    = false
    @updating   = false
    @quickswap  = false
    @heldpkmn   = nil
    @handsprite = ChangelingSprite.new(0, 0, viewport)
    @handsprite.addBitmap("point1", "Graphics/UI/Storage/cursor_point_1")
    @handsprite.addBitmap("point2", "Graphics/UI/Storage/cursor_point_2")
    @handsprite.addBitmap("grab", "Graphics/UI/Storage/cursor_grab")
    @handsprite.addBitmap("fist", "Graphics/UI/Storage/cursor_fist")
    @handsprite.addBitmap("point1q", "Graphics/UI/Storage/cursor_point_1_q")
    @handsprite.addBitmap("point2q", "Graphics/UI/Storage/cursor_point_2_q")
    @handsprite.addBitmap("grabq", "Graphics/UI/Storage/cursor_grab_q")
    @handsprite.addBitmap("fistq", "Graphics/UI/Storage/cursor_fist_q")
    @handsprite.changeBitmap("fist")
    @spriteX = self.x
    @spriteY = self.y
  end

  def dispose
    @handsprite.dispose
    @heldpkmn&.dispose
    super
  end

  def x=(value)
    super
    @handsprite.x = self.x
    @spriteX = x if !@updating
    heldPokemon.x = self.x if holding?
  end

  def y=(value)
    super
    @handsprite.y = self.y
    @spriteY = y if !@updating
    heldPokemon.y = self.y + 16 if holding?
  end

  def z=(value)
    super
    @handsprite.z = value
  end

  def visible=(value)
    super
    @handsprite.visible = value
    sprite = heldPokemon
    sprite.visible = value if sprite
  end

  def color=(value)
    super
    @handsprite.color = value
    sprite = heldPokemon
    sprite.color = value if sprite
  end

  def heldPokemon
    @heldpkmn = nil if @heldpkmn&.disposed?
    @holding = false if !@heldpkmn
    return @heldpkmn
  end

  def holding?
    return self.heldPokemon && @holding
  end

  def grabbing?
    return !@grabbing_timer_start.nil?
  end

  def placing?
    return !@placing_timer_start.nil?
  end

def setSprite(sprite)
  @heldpkmn = sprite
  @holding = !sprite.nil?

  if @heldpkmn
    @heldpkmn.viewport = self.viewport
    @heldpkmn.z = 1
    self.z = 2
  end
end

  def deleteSprite
    @holding = false
    if @heldpkmn
      @heldpkmn.dispose
      @heldpkmn = nil
    end
  end

  def grab(sprite)
    @grabbing_timer_start = System.uptime
    @heldpkmn = sprite
    @heldpkmn.viewport = self.viewport
    @heldpkmn.z = 1
    self.z = 2
  end

  def place
    @placing_timer_start = System.uptime
  end

  def release
    @heldpkmn&.release
  end

  def update
    @updating = true
    super
    heldpkmn = heldPokemon
    heldpkmn&.update
    @handsprite.update
    @holding = false if !heldpkmn
    if @grabbing_timer_start
      if System.uptime - @grabbing_timer_start <= GRAB_TIME / 2
        @handsprite.changeBitmap((@quickswap) ? "grabq" : "grab")
        self.y = @spriteY + lerp(0, 16, GRAB_TIME / 2, @grabbing_timer_start, System.uptime)
      else
        @holding = true
        @handsprite.changeBitmap((@quickswap) ? "fistq" : "fist")
        delta_y = lerp(16, 0, GRAB_TIME / 2, @grabbing_timer_start + (GRAB_TIME / 2), System.uptime)
        self.y = @spriteY + delta_y
        @grabbing_timer_start = nil if delta_y == 0
      end
    elsif @placing_timer_start
      if System.uptime - @placing_timer_start <= GRAB_TIME / 2
        @handsprite.changeBitmap((@quickswap) ? "fistq" : "fist")
        self.y = @spriteY + lerp(0, 16, GRAB_TIME / 2, @placing_timer_start, System.uptime)
      else
        @holding = false
        @heldpkmn = nil
        @handsprite.changeBitmap((@quickswap) ? "grabq" : "grab")
        delta_y = lerp(16, 0, GRAB_TIME / 2, @placing_timer_start + (GRAB_TIME / 2), System.uptime)
        self.y = @spriteY + delta_y
        @placing_timer_start = nil if delta_y == 0
      end
    elsif holding?
      @handsprite.changeBitmap((@quickswap) ? "fistq" : "fist")
    else   # Idling
      self.x = @spriteX
      self.y = @spriteY
      if (System.uptime / 0.5).to_i.even?   # Changes every 0.5 seconds
        @handsprite.changeBitmap((@quickswap) ? "point1q" : "point1")
      else
        @handsprite.changeBitmap((@quickswap) ? "point2q" : "point2")
      end
    end
    @updating = false
  end
end

#===============================================================================
# Box
#===============================================================================
class PokemonBoxSprite < Sprite
  attr_accessor :refreshBox
  attr_accessor :refreshSprites
  attr_reader   :scale

  def initialize(storage, boxnumber, viewport = nil)
    super(viewport)
    @storage = storage
    @boxnumber = boxnumber
    @refreshBox = true
    @refreshSprites = true
    @pokemonsprites = []
	@scale = 1.0
	self.zoom_x = @scale
	self.zoom_y = @scale
    PokemonBox::BOX_SIZE.times do |i|
      @pokemonsprites[i] = nil
      pokemon = @storage[boxnumber, i]
      @pokemonsprites[i] = PokemonBoxIcon.new(pokemon, viewport)
    end
    @contents = Bitmap.new(324, 296)
    self.bitmap = @contents
    self.x = 144
    self.y = 18
    refresh
  end
  
  def scale=(value)
    @scale = value
    self.zoom_x = value
    self.zoom_y = value
    refresh
  end

  def dispose
    if !disposed?
      PokemonBox::BOX_SIZE.times do |i|
        @pokemonsprites[i]&.dispose
        @pokemonsprites[i] = nil
      end
      @boxbitmap.dispose
      @contents.dispose
      super
    end
  end

  def x=(value)
    super
    refresh
  end

  def y=(value)
    super
    refresh
  end

  def color=(value)
    super
    if @refreshSprites
      PokemonBox::BOX_SIZE.times do |i|
        if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
          @pokemonsprites[i].color = value
        end
      end
    end
    refresh
  end
  
  def opacity=(value)
    super
    @pokemonsprites.each do |sprite|
      next if !sprite || sprite.disposed?
      sprite.opacity = value
    end
  end

  def visible=(value)
    super
    PokemonBox::BOX_SIZE.times do |i|
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].visible = value
      end
    end
    refresh
  end

  def getBoxBitmap
    if !@bg || @bg != @storage[@boxnumber].background
      curbg = @storage[@boxnumber].background
      if !curbg || (curbg.is_a?(String) && curbg.length == 0)
        @bg = @boxnumber % PokemonStorage::BASICWALLPAPERQTY
      else
        if curbg.is_a?(String) && curbg[/^box(\d+)$/]
          curbg = $~[1].to_i
          @storage[@boxnumber].background = curbg
        end
        @bg = curbg
      end
      if !@storage.isAvailableWallpaper?(@bg)
        @bg = @boxnumber % PokemonStorage::BASICWALLPAPERQTY
        @storage[@boxnumber].background = @bg
      end
      @boxbitmap&.dispose
      @boxbitmap = AnimatedBitmap.new("Graphics/UI/Storage/box_#{@bg}")
    end
  end

  def getPokemon(index)
    return @pokemonsprites[index]
  end

  def setPokemon(index, sprite)
    @pokemonsprites[index] = sprite
    @pokemonsprites[index].refresh
    refresh
  end

  def grabPokemon(index, arrow)
    sprite = @pokemonsprites[index]
    if sprite
      arrow.grab(sprite)
      @pokemonsprites[index] = nil
      refresh
    end
  end

  def deletePokemon(index)
    @pokemonsprites[index].dispose
    @pokemonsprites[index] = nil
    refresh
  end

  def refresh
    if @refreshBox
      boxname = @storage[@boxnumber].name
      getBoxBitmap
      @contents.blt(0, 0, @boxbitmap.bitmap, Rect.new(0, 0, 324, 296))
      pbSetSystemFont(@contents)
      widthval = @contents.text_size(boxname).width
      xval = 162 - (widthval / 2)
      pbDrawShadowText(@contents, xval, 14, widthval, 32,
                       boxname, Color.new(248, 248, 248), Color.new(40, 48, 48))
      @refreshBox = false
    end
	yval = self.y + (30 * @scale)
	PokemonBox::BOX_HEIGHT.times do |j|
	  xval = self.x + (10 * @scale)
	  PokemonBox::BOX_WIDTH.times do |k|
		sprite = @pokemonsprites[(j * PokemonBox::BOX_WIDTH) + k]
		if sprite && !sprite.disposed?
		  sprite.viewport = self.viewport
		  sprite.x = xval
		  sprite.y = yval
		  sprite.zoom_x = @scale
		  sprite.zoom_y = @scale
		  sprite.z = self.z + 10
		end
		xval += 48 * @scale
	  end
	  yval += 48 * @scale
	end
  end

  def update
    super
    PokemonBox::BOX_SIZE.times do |i|
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].update
      end
    end
  end
end

#===============================================================================
# Party panel
#===============================================================================
class PokemonBoxPartySprite < Sprite
  def initialize(party, viewport = nil)
    super(viewport)
    @party = party
    @boxbitmap = AnimatedBitmap.new("Graphics/UI/Storage/overlay_party")
    @pokemonsprites = []
    Settings::MAX_PARTY_SIZE.times do |i|
      @pokemonsprites[i] = nil
      pokemon = @party[i]
      @pokemonsprites[i] = PokemonBoxIcon.new(pokemon, viewport) if pokemon
    end
    @contents = Bitmap.new(172, 352)
    self.bitmap = @contents
    self.x = 0
    self.y = Graphics.height - 352
    pbSetSystemFont(self.bitmap)
    refresh
  end

  def dispose
    Settings::MAX_PARTY_SIZE.times do |i|
      @pokemonsprites[i]&.dispose
    end
    @boxbitmap.dispose
    @contents.dispose
    super
  end

  def x=(value)
    super
    refresh
  end

  def y=(value)
    super
    refresh
  end

  def color=(value)
    super
    Settings::MAX_PARTY_SIZE.times do |i|
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].color = pbSrcOver(@pokemonsprites[i].color, value)
      end
    end
  end

  def visible=(value)
    super
    Settings::MAX_PARTY_SIZE.times do |i|
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].visible = value
      end
    end
  end

  def getPokemon(index)
    return @pokemonsprites[index]
  end

def setPokemon(index, sprite)
  @pokemonsprites[index] = sprite
  refresh
end

  def grabPokemon(index, arrow)
    sprite = @pokemonsprites[index]
    if sprite
      arrow.grab(sprite)
      @pokemonsprites[index] = nil
      refresh
    end
  end

  def deletePokemon(index)
    @pokemonsprites[index].dispose
    @pokemonsprites[index] = nil
    refresh
  end

  def refresh
    @contents.clear
    @contents.blt(0, 0, @boxbitmap.bitmap, Rect.new(0, 0, 172, 352))
    xvalues = []   # [18, 90, 18, 90, 18, 90]
    yvalues = []   # [2, 18, 66, 82, 130, 146]
    Settings::MAX_PARTY_SIZE.times do |i|
	  x = 18 + (72 * (i % 2))
	  y = 2 + (16 * (i % 2)) + (80 * (i / 2))

	  if i.odd?
		x -= 32
		y += 24
	  end

	  xvalues.push(x)
	  yvalues.push(y)
	end
    @pokemonsprites.each { |sprite| sprite&.refresh }
    Settings::MAX_PARTY_SIZE.times do |j|
      sprite = @pokemonsprites[j]
      next if sprite.nil? || sprite.disposed?
      sprite.viewport = self.viewport
      sprite.x = self.x + xvalues[j]
      sprite.y = self.y + yvalues[j]
      sprite.z = 1
    end
  end

  def update
    super
    Settings::MAX_PARTY_SIZE.times do |i|
      @pokemonsprites[i].update if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
    end
  end
end

#===============================================================================
# Pokémon storage visuals
#===============================================================================
class PokemonStorageScene
  attr_reader :quickswap

  MARK_WIDTH  = 16
  MARK_HEIGHT = 16
  BOX_CENTER_X = 144
  BOX_CENTER_Y = 18
  BOX_LEFT_X   = 8
  BOX_RIGHT_X  = 514
  BOX_SIDE_Y   = 92
  BOX_SIDE_SCALE = 0.5
  BOX_SWITCH_TIME = 0.25
  SIDE_BOX_X_OFFSET = -36   # tweak this
  BOX_CENTER_OPACITY = 255
  BOX_SIDE_OPACITY   = 120

  def initialize
    @command = 1
  end
  
  def pbCreatePokemonGlow
    white = Tone.new(255, 255, 255)
    positions = [
      [592, 134],   # left
      [596, 134],   # right
      [594, 132],   # up
      [594, 136]    # down
    ]

    positions.each_with_index do |pos, i|
      key = "pokemonglow#{i + 1}"
      @sprites[key]&.dispose
      @sprites[key] = AutoMosaicPokemonSprite.new(@boxsidesviewport)
      @sprites[key].setOffset(PictureOrigin::CENTER)
      @sprites[key].x = pos[0]
      @sprites[key].y = pos[1]
      @sprites[key].z = 300
      @sprites[key].tone = white
      @sprites[key].opacity = 120
      @sprites[key].visible = false
    end

    @sprites["pokemon"].z = 301 if @sprites["pokemon"]
  end

  def pbSetPokemonGlow(pokemon)
    if !pokemon
      4.times do |i|
        glow = @sprites["pokemonglow#{i + 1}"]
        glow.visible = false if glow && !glow.disposed?
      end
      @glowPokemon = nil
      return
    end

    changed = (@glowPokemon != pokemon)
    @glowPokemon = pokemon

    4.times do |i|
      glow = @sprites["pokemonglow#{i + 1}"]
      next if !glow || glow.disposed?

      glow.visible = @sprites["pokemon"].visible

      # Only reload the sprite if this is a different Pokémon.
      glow.setPokemonBitmap(pokemon) if changed
    end
  end
    
  def pbPrevBoxNumber(box)
    return (box + @storage.maxBoxes - 1) % @storage.maxBoxes
  end

  def pbNextBoxNumber(box)
    return (box + 1) % @storage.maxBoxes
  end

  def pbCreateBoxSprite(box_number, x, y, scale, z = 0, opacity = BOX_SIDE_OPACITY)
    box = PokemonBoxSprite.new(@storage, box_number, @boxviewport)
    box.x = x
    box.y = y
    box.scale = scale
    box.z = z
    box.opacity = opacity
    return box
  end

  def pbCreateSideBoxes
    current = @storage.currentBox

    @sprites["box_left"]&.dispose
    @sprites["box_right"]&.dispose

    @sprites["box_left"] = pbCreateBoxSprite(
      pbPrevBoxNumber(current),
      BOX_LEFT_X + SIDE_BOX_X_OFFSET,
      BOX_SIDE_Y,
      BOX_SIDE_SCALE,
      0
    )

    @sprites["box_right"] = pbCreateBoxSprite(
      pbNextBoxNumber(current),
      BOX_RIGHT_X + SIDE_BOX_X_OFFSET,
      BOX_SIDE_Y,
      BOX_SIDE_SCALE,
      0
    )
  end

  def refresh_box_jump_prompts
    return if !@sprites["jumpup_prompt"] || !@sprites["jumpdown_prompt"]

    base   = Color.new(248, 248, 248)
    shadow = Color.new(40, 40, 40)

    [["jumpup_prompt", :jumpup, "<", 236], ["jumpdown_prompt", :jumpdown, ">", 392]].each do |key, action, arrow, anchor_x|
      sprite = @sprites[key]
      bitmap = sprite.bitmap
      bitmap.clear

      if Keybinds.gamepad?
        sheet = RPG::Cache.load_bitmap("Graphics/UI/", "controller_buttons")
        button = Keybinds::GAMEPAD_BUTTONS[action]

        src_rect = Rect.new(
          button * 32,
          $PokemonSystem.controller_layout * 32,
          32,
          32
        )

        if action == :jumpup
          pbDrawTextPositions(bitmap, [[arrow, 0, 8, 0, base, shadow]])
          bitmap.blt(20, 2, sheet, src_rect)
        else
          bitmap.blt(0, 2, sheet, src_rect)
          pbDrawTextPositions(bitmap, [[arrow, 38, 8, 0, base, shadow]])
        end
      else
        key_text = Keybinds.button_name(action)

        if action == :jumpup
          text = _INTL("{1} {2}", arrow, key_text)
        else
          text = _INTL("{1} {2}", key_text, arrow)
        end

        pbDrawTextPositions(bitmap, [[text, 0, 8, 0, base, shadow]])
      end

      if Keybinds.gamepad?
        width = 68
      else
        key_text = Keybinds.button_name(action)
        text = (action == :jumpup) ? _INTL("{1} {2}", arrow, key_text) : _INTL("{1} {2}", key_text, arrow)
        width = bitmap.text_size(text).width
        width += 16 if action == :jumpup
      end

      if action == :jumpup
        sprite.x = anchor_x - width   # right edge lands exactly on anchor_x
      else
        sprite.x = anchor_x           # left edge starts exactly on anchor_x
      end

      sprite.y = 26
    end
  end

  def pbStartBox(screen, command)
    @screen = screen
    @storage = screen.storage
    @bgviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @bgviewport.z = 99999
    @boxviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @boxviewport.z = 99999
    @boxsidesviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @boxsidesviewport.z = 99999
    @arrowviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @arrowviewport.z = 99999
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @selection = 0
    @last_box_column = 0
    @quickswap = false
    @show_moves = false
    @sprites = {}
    @choseFromParty = false
    @command = command
    panorama_path = (IASummary::IAVERSION == 2) ? "Graphics/UI/Storage/bg_pan_io" : "Graphics/UI/Summary/bg_pan_am"
    @sprites["panorama1"] = IconSprite.new(0, 0, @bgviewport)
    @sprites["panorama1"].setBitmap(panorama_path)
    @sprites["panorama2"] = IconSprite.new(@sprites["panorama1"].bitmap.width, 0, @bgviewport)
    @sprites["panorama2"].setBitmap(panorama_path)
    @sprites["box"] = PokemonBoxSprite.new(@storage, @storage.currentBox, @boxviewport)
    pbCreateSideBoxes
    @sprites["boxsides"] = IconSprite.new(0, 0, @boxsidesviewport)
    @sprites["boxsides"].setBitmap("Graphics/UI/Storage/overlay_main")
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @boxsidesviewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @last_input_device = Keybinds.last_device rescue nil

    @sprites["jumpup_prompt"] = BitmapSprite.new(160, 40, @boxsidesviewport)
    @sprites["jumpup_prompt"].z = 20

    @sprites["jumpdown_prompt"] = BitmapSprite.new(160, 40, @boxsidesviewport)
    @sprites["jumpdown_prompt"].z = 20

    pbSetSystemFont(@sprites["jumpup_prompt"].bitmap)
    pbSetSystemFont(@sprites["jumpdown_prompt"].bitmap)

    refresh_box_jump_prompts
    @sprites["pokemon"] = AutoMosaicPokemonSprite.new(@boxsidesviewport)
    @sprites["pokemon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemon"].x = 594
    @sprites["pokemon"].y = 134
    pbCreatePokemonGlow
    @sprites["boxparty"] = PokemonBoxPartySprite.new(@storage.party, @boxsidesviewport)
    #if command != 2   # Drop down tab only on Deposit
    #  @sprites["boxparty"].x = 182
    #  @sprites["boxparty"].y = Graphics.height
    #end
    @markingbitmap = AnimatedBitmap.new("Graphics/UI/Storage/markings")
    @sprites["markingbg"] = IconSprite.new(292, 68, @boxsidesviewport)
    @sprites["markingbg"].setBitmap("Graphics/UI/Storage/overlay_marking")
    @sprites["markingbg"].z = 10
    @sprites["markingbg"].visible = false
    @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @boxsidesviewport)
    @sprites["markingoverlay"].z = 11
    @sprites["markingoverlay"].visible = false
    pbSetSystemFont(@sprites["markingoverlay"].bitmap)
    @sprites["arrow"] = PokemonBoxArrow.new(@arrowviewport)
    @sprites["arrow"].z += 1
    if command == 2
      pbPartySetArrow(@sprites["arrow"], @selection)
      pbUpdateOverlay(@selection, @storage.party)
    else
      pbSetArrow(@sprites["arrow"], @selection)
      pbUpdateOverlay(@selection)
    end
    pbSetMosaic(@selection)
    pbSEPlay("PC access")
    pbFadeInAndShow(@sprites)
  end

  def pbCloseBox
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @markingbitmap&.dispose
    @boxviewport.dispose
    @boxsidesviewport.dispose
    @arrowviewport.dispose
  end

  def pbDisplay(message)
    msgwindow = Window_UnformattedTextPokemon.newWithSize("", 180, 0, Graphics.width - 180, 32)
    msgwindow.viewport       = @viewport
    msgwindow.visible        = true
    msgwindow.letterbyletter = false
    msgwindow.resizeHeightToFit(message, Graphics.width - 180)
    msgwindow.text = message
    pbBottomRight(msgwindow)
    loop do
      Graphics.update
      Input.update
      if Keybinds.trigger?(:back) || Keybinds.trigger?(:use)
        break
      end
      msgwindow.update
      self.update
    end
    msgwindow.dispose
    Input.update
  end

  def pbShowCommands(message, commands, index = 0)
    ret = -1
    msgwindow = Window_UnformattedTextPokemon.newWithSize("", 180, 0, Graphics.width - 180, 32)
    msgwindow.viewport       = @viewport
    msgwindow.visible        = true
    msgwindow.letterbyletter = false
    msgwindow.text           = message
    msgwindow.resizeHeightToFit(message, Graphics.width - 180)
    pbBottomRight(msgwindow)
    cmdwindow = Window_CommandPokemon.new(commands)
    cmdwindow.viewport = @viewport
    cmdwindow.visible  = true
    cmdwindow.resizeToFit(cmdwindow.commands)
    cmdwindow.height = Graphics.height - msgwindow.height if cmdwindow.height > Graphics.height - msgwindow.height
    pbBottomRight(cmdwindow)
    cmdwindow.y -= msgwindow.height
    cmdwindow.index = index
    loop do
      Graphics.update
      Input.update
      msgwindow.update
      cmdwindow.update
      if Keybinds.trigger?(:back)
        ret = -1
        break
      elsif Keybinds.trigger?(:use)
        ret = cmdwindow.index
        break
      end
      self.update
    end
    msgwindow.dispose
    cmdwindow.dispose
    Input.update
    return ret
  end

  def pbSetArrow(arrow, selection)
    case selection
    when -1, -4, -5
      arrow.x = 274
      arrow.y = -24
    when -2
      arrow.x = 238
      arrow.y = 278
    when -3   # Exit
      arrow.x = 282
      arrow.y = 278
    else
      # Moved 40px left because the box moved from x 184 to x 144.
      arrow.x = ((97 + (24 * (selection % PokemonBox::BOX_WIDTH))) * 2) - 40
      arrow.y = (8 + (24 * (selection / PokemonBox::BOX_WIDTH))) * 2
    end
  end

  def pbPartySlotFromBoxSelection(selection, entering_from_left)
    box_row = selection / PokemonBox::BOX_WIDTH

    party_row = case box_row
                when 0 then 0
                when 1, 2 then 1
                else 2
                end

    return (party_row * 2) + (entering_from_left ? 1 : 0)
  end

  def pbBoxSelectionFromPartySlot(selection, leaving_left)
    party_row = selection / 2

    box_row = case party_row
              when 0 then 0
              when 1 then 1
              else 3
              end

    box_col = leaving_left ? PokemonBox::BOX_WIDTH - 1 : 0
    return (box_row * PokemonBox::BOX_WIDTH) + box_col
  end

  def pbChangeSelection(key, selection)
    @last_box_column = selection % PokemonBox::BOX_WIDTH if selection >= 0

    case key
    when :up
      if selection == -1
        selection = -3
      elsif selection == -3
        selection = 24 + @last_box_column
      else
        selection -= PokemonBox::BOX_WIDTH
        selection = -1 if selection < 0
      end

    when :down
      if selection == -1
        selection = @last_box_column
      elsif selection == -3
        selection = -1
      elsif selection >= 24 && selection <= 29
        selection = -3
      else
        selection += PokemonBox::BOX_WIDTH
        selection = -3 if selection >= PokemonBox::BOX_SIZE
      end

    when :left
      case selection
      when 0  then selection = [:party, 1]
      when 6  then selection = [:party, 1]
      when 12 then selection = [:party, 3]
      when 18 then selection = [:party, 3]
      when 24 then selection = [:party, 5]
      else
        selection = -4 if selection == -1
        selection = PokemonBox::BOX_SIZE - 1 if selection == -3
        selection -= 1 if selection >= 0
      end

    when :right
      case selection
      when 5  then selection = [:party, 0]
      when 11 then selection = [:party, 2]
      when 17 then selection = [:party, 2]
      when 23 then selection = [:party, 4]
      when 29 then selection = [:party, 4]
      else
        selection = -5 if selection == -1
        selection = 0 if selection == -3
        selection += 1 if selection >= 0
      end
    end

    return selection
  end

  def pbPartySetArrow(arrow, selection)
    return if selection < 0
    xvalues = []
    yvalues = []

	Settings::MAX_PARTY_SIZE.times do |i|
	  x = (200 - 184) + (72 * (i % 2))
	  y = 2 + (16 * (i % 2)) + (80 * (i / 2))

	  # Move party slots 1, 3, 5 left 20px and down 16px.
	  if i.odd?
		x -= 32
		y += 24
	  end

	  xvalues.push(x)
	  yvalues.push(y)
	end

    arrow.angle = 0
    arrow.mirror = false
    arrow.ox = 0
    arrow.oy = 0
    arrow.x = xvalues[selection]
    arrow.y = yvalues[selection]
  end

  def pbPartyChangeSelection(key, selection)
    case key
    when :left
      return [:box, 5]  if selection == 0
      return 0          if selection == 1
      return [:box, 11] if selection == 2
      return 2          if selection == 3
      return [:box, 23] if selection == 4
      return 4          if selection == 5

    when :right
      return 1          if selection == 0
      return [:box, 0]  if selection == 1
      return 3          if selection == 2
      return [:box, 12] if selection == 3
      return 5          if selection == 4
      return [:box, 24] if selection == 5

    when :up
      selection -= 1
      selection = Settings::MAX_PARTY_SIZE - 1 if selection < 0

    when :down
      selection += 1
      selection = 0 if selection >= Settings::MAX_PARTY_SIZE
    end

    return selection
  end

  def pbSelectBoxInternal(_party)
    selection = @selection
    pbSetArrow(@sprites["arrow"], selection)
    pbUpdateOverlay(selection)
    pbSetMosaic(selection)
    loop do
      Graphics.update
      Input.update
      key = -1
      key = :down if Keybinds.repeat?(:down)
      key = :right if Keybinds.repeat?(:right)
      key = :left if Keybinds.repeat?(:left)
      key = :up if Keybinds.repeat?(:up)
      if key != -1
        pbPlayCursorSE
        selection = pbChangeSelection(key, selection)
		if selection.is_a?(Array) && selection[0] == :party
		  @selection = selection[1]
		  ret = pbSelectPartyInternal(@storage.party, false)

		  if ret == -2
			selection = @selection
			pbSetArrow(@sprites["arrow"], selection)
			pbUpdateOverlay(selection)
			pbSetMosaic(selection)
			next
		  elsif ret >= 0
		    return [-1, ret]
		  else
		    @choseFromParty = true
		    return nil
		  end
		end
		pbSetArrow(@sprites["arrow"], selection)
        case selection
        when -4
          nextbox = (@storage.currentBox + @storage.maxBoxes - 1) % @storage.maxBoxes
          pbSwitchBoxToLeft(nextbox)
          @storage.currentBox = nextbox
        when -5
          nextbox = (@storage.currentBox + 1) % @storage.maxBoxes
          pbSwitchBoxToRight(nextbox)
          @storage.currentBox = nextbox
        end
        selection = -1 if [-4, -5].include?(selection)
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      end
      self.update
      if Keybinds.repeat?(:jumpup)
        pbPlayCursorSE
        nextbox = (@storage.currentBox + @storage.maxBoxes - 1) % @storage.maxBoxes
        pbSwitchBoxToLeft(nextbox)
        @storage.currentBox = nextbox
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      elsif Keybinds.repeat?(:jumpdown)
        pbPlayCursorSE
        nextbox = (@storage.currentBox + 1) % @storage.maxBoxes
        pbSwitchBoxToRight(nextbox)
        @storage.currentBox = nextbox
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      elsif Keybinds.trigger?(:special)  # Swap from Data to Moves
	    pbPlayCursorSE
	    @show_moves = !@show_moves
	    pbUpdateOverlay(selection)
      elsif Keybinds.trigger?(:action) && @command == 0   # Organize only
        pbPlayDecisionSE
        pbSetQuickSwap(!@quickswap)
      elsif Keybinds.trigger?(:back)
        @selection = selection
        return nil
      elsif Keybinds.trigger?(:use)
        @selection = selection
        if selection >= 0
          return [@storage.currentBox, selection]
        elsif selection == -1   # Box name
          return [-4, -1]
        elsif selection == -2   # Party Pokémon
          return [-2, -1]
        elsif selection == -3   # Close Box
          return [-3, -1]
        end
      end
    end
  end

  def pbSelectBox(party)
    loop do
      if @choseFromParty
        ret = pbSelectPartyInternal(party, false)

        if ret == -2
          @choseFromParty = false
          selection = @selection
          pbSetArrow(@sprites["arrow"], selection)
          pbUpdateOverlay(selection)
          pbSetMosaic(selection)
          next
        elsif ret >= 0
          return [-1, ret]
        else
          return nil
        end
      end

      ret = pbSelectBoxInternal(party)

      if ret && ret[0] == -1
        @choseFromParty = true
      end

      return ret
    end
  end

  def pbSelectPartyInternal(party, depositing)
    selection = @selection
    pbPartySetArrow(@sprites["arrow"], selection)
    pbUpdateOverlay(selection, party)
    pbSetMosaic(selection)
    lastsel = 1
    loop do
      Graphics.update
      Input.update
      key = -1
      key = :down if Keybinds.repeat?(:down)
      key = :right if Keybinds.repeat?(:right)
      key = :left if Keybinds.repeat?(:left)
      key = :up if Keybinds.repeat?(:up)
      if key != -1
        pbPlayCursorSE
        newselection = pbPartyChangeSelection(key, selection)
		if newselection.is_a?(Array) && newselection[0] == :box
		  @selection = newselection[1]
		  return -2
		else
		  selection = newselection
		  pbPartySetArrow(@sprites["arrow"], selection)
		  lastsel = selection if selection > 0
		  pbUpdateOverlay(selection, party)
		  pbSetMosaic(selection)
		end
      end
      self.update
	  if Keybinds.trigger?(:special)
	    pbPlayCursorSE
	    @show_moves = !@show_moves
	    pbUpdateOverlay(selection, party)
	  elsif Keybinds.trigger?(:action) && @command == 0   # Organize only
        pbPlayDecisionSE
        pbSetQuickSwap(!@quickswap)
      elsif Keybinds.trigger?(:back)
	    @selection = selection
	    @choseFromParty = true
	    return -1
      elsif Keybinds.trigger?(:use)
        if selection >= 0 && selection < Settings::MAX_PARTY_SIZE
          @selection = selection
          return selection
		end
      end
    end
  end

  def pbSelectParty(party)
    return pbSelectPartyInternal(party, true)
  end

  def pbChangeBackground(wp)
    duration = 0.2   # Time in seconds to fade out or fade in
    @sprites["box"].refreshSprites = false
    Graphics.update
    self.update
    # Fade old background to white
    timer_start = System.uptime
    loop do
      alpha = lerp(0, 255, duration, timer_start, System.uptime)
      @sprites["box"].color = Color.new(248, 248, 248, alpha)
      Graphics.update
      self.update
      break if alpha >= 255
    end
    # Fade in new background from white
    @sprites["box"].refreshBox = true
    @storage[@storage.currentBox].background = wp
    timer_start = System.uptime
    loop do
      alpha = lerp(255, 0, duration, timer_start, System.uptime)
      @sprites["box"].color = Color.new(248, 248, 248, alpha)
      Graphics.update
      self.update
      break if alpha <= 0
    end
    @sprites["box"].refreshSprites = true
    Input.update
  end

  def pbSwitchBoxToRight(new_box_number)
    old_left   = @sprites["box_left"]
    old_center = @sprites["box"]
    old_right  = @sprites["box_right"]
    new_right = pbCreateBoxSprite(
      pbNextBoxNumber(new_box_number),
      Graphics.width + 20,
      BOX_SIDE_Y,
      BOX_SIDE_SCALE,
      0
    )
    @sprites["box_right_new"] = new_right
    timer_start = System.uptime
    loop do
      t = [(System.uptime - timer_start) / BOX_SWITCH_TIME, 1.0].min
      old_left.x   = lerp(BOX_LEFT_X + SIDE_BOX_X_OFFSET, -180, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_center.x = lerp(BOX_CENTER_X, BOX_LEFT_X + SIDE_BOX_X_OFFSET, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_center.y = lerp(BOX_CENTER_Y, BOX_SIDE_Y, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_center.scale = lerp(1.0, BOX_SIDE_SCALE, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_right.x = lerp(BOX_RIGHT_X + SIDE_BOX_X_OFFSET, BOX_CENTER_X, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_right.y = lerp(BOX_SIDE_Y, BOX_CENTER_Y, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_right.scale = lerp(BOX_SIDE_SCALE, 1.0, BOX_SWITCH_TIME, timer_start, System.uptime)
    old_center.opacity = lerp(BOX_CENTER_OPACITY, BOX_SIDE_OPACITY, BOX_SWITCH_TIME, timer_start, System.uptime)
    old_right.opacity  = lerp(BOX_SIDE_OPACITY, BOX_CENTER_OPACITY, BOX_SWITCH_TIME, timer_start, System.uptime)
    old_left.opacity   = lerp(BOX_SIDE_OPACITY, 0, BOX_SWITCH_TIME, timer_start, System.uptime)
    new_right.opacity  = lerp(0, BOX_SIDE_OPACITY, BOX_SWITCH_TIME, timer_start, System.uptime)
      new_right.x = lerp(Graphics.width + 20, BOX_RIGHT_X + SIDE_BOX_X_OFFSET, BOX_SWITCH_TIME, timer_start, System.uptime)
      self.update
      Graphics.update
      break if t >= 1.0
    end
    old_left.dispose
    @sprites.delete("box_left")
    @sprites.delete("box_right_new")
    @sprites["box_left"]          = old_center
    @sprites["box"]               = old_right
    @sprites["box_right"]         = new_right
    @sprites["box_left"].z        = 0
    @sprites["box"].z             = 5
    @sprites["box_right"].z       = 0
    @sprites["box_left"].z        = 0
    @sprites["box"].z             = 5
    @sprites["box_right"].z       = 0
    @sprites["box_left"].opacity  = BOX_SIDE_OPACITY
    @sprites["box"].opacity       = BOX_CENTER_OPACITY
    @sprites["box_right"].opacity = BOX_SIDE_OPACITY
    @sprites["box_left"].refresh
    @sprites["box"].refresh
    @sprites["box_right"].refresh
    Input.update
  end

  def pbSwitchBoxToLeft(new_box_number)
    old_left   = @sprites["box_left"]
    old_center = @sprites["box"]
    old_right  = @sprites["box_right"]
    new_left = pbCreateBoxSprite(
      pbPrevBoxNumber(new_box_number),
      -180 + SIDE_BOX_X_OFFSET,
      BOX_SIDE_Y,
      BOX_SIDE_SCALE,
      0
    )
    @sprites["box_left_new"] = new_left
    timer_start = System.uptime
    loop do
      t = [(System.uptime - timer_start) / BOX_SWITCH_TIME, 1.0].min
      old_right.x  = lerp(BOX_RIGHT_X + SIDE_BOX_X_OFFSET, Graphics.width + 20, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_center.x = lerp(BOX_CENTER_X, BOX_RIGHT_X + SIDE_BOX_X_OFFSET, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_center.y = lerp(BOX_CENTER_Y, BOX_SIDE_Y, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_center.scale = lerp(1.0, BOX_SIDE_SCALE, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_left.x = lerp(BOX_LEFT_X + SIDE_BOX_X_OFFSET, BOX_CENTER_X, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_left.y = lerp(BOX_SIDE_Y, BOX_CENTER_Y, BOX_SWITCH_TIME, timer_start, System.uptime)
      old_left.scale = lerp(BOX_SIDE_SCALE, 1.0, BOX_SWITCH_TIME, timer_start, System.uptime)
    old_center.opacity = lerp(BOX_CENTER_OPACITY, BOX_SIDE_OPACITY, BOX_SWITCH_TIME, timer_start, System.uptime)
    old_left.opacity   = lerp(BOX_SIDE_OPACITY, BOX_CENTER_OPACITY, BOX_SWITCH_TIME, timer_start, System.uptime)
    old_right.opacity  = lerp(BOX_SIDE_OPACITY, 0, BOX_SWITCH_TIME, timer_start, System.uptime)
    new_left.opacity   = lerp(0, BOX_SIDE_OPACITY, BOX_SWITCH_TIME, timer_start, System.uptime)
      new_left.x = lerp(-180 + SIDE_BOX_X_OFFSET, BOX_LEFT_X + SIDE_BOX_X_OFFSET, BOX_SWITCH_TIME, timer_start, System.uptime)
      self.update
      Graphics.update
      break if t >= 1.0
    end
    old_right.dispose
    @sprites.delete("box_right")
    @sprites.delete("box_left_new")
    @sprites["box_right"]         = old_center
    @sprites["box"]               = old_left
    @sprites["box_left"]          = new_left
    @sprites["box_left"].z        = 0
    @sprites["box"].z             = 5
    @sprites["box_right"].z       = 0
    @sprites["box_left"].z        = 0
    @sprites["box"].z             = 5
    @sprites["box_right"].z       = 0
    @sprites["box_left"].opacity  = BOX_SIDE_OPACITY
    @sprites["box"].opacity       = BOX_CENTER_OPACITY
    @sprites["box_right"].opacity = BOX_SIDE_OPACITY
    @sprites["box_left"].refresh
    @sprites["box"].refresh
    @sprites["box_right"].refresh
    Input.update
  end

  def pbJumpToBox(newbox)
    return if newbox < 0
    return if @storage.currentBox == newbox
    @sprites["box"]&.dispose
    @sprites["box_left"]&.dispose
    @sprites["box_right"]&.dispose
    @storage.currentBox = newbox
    @sprites["box"] = PokemonBoxSprite.new(@storage, newbox, @boxviewport)
    @sprites["box"].x = BOX_CENTER_X
    @sprites["box"].y = BOX_CENTER_Y
    @sprites["box"].zoom_x = 1.0
    @sprites["box"].zoom_y = 1.0
    @sprites["box"].refreshBox = true
    @sprites["box"].refresh
    pbCreateSideBoxes
    pbSetArrow(@sprites["arrow"], @selection)
    pbUpdateOverlay(@selection)
    pbSetMosaic(@selection)
  end

  def pbSetMosaic(selection)
    return if @screen.pbHeldPokemon
    return if @boxForMosaic == @storage.currentBox && @selectionForMosaic == selection
    @sprites["pokemon"].mosaic_duration = 0.25
    4.times do |i|
      glow = @sprites["pokemonglow#{i + 1}"]
      glow.mosaic_duration = 0.25 if glow && !glow.disposed?
    end
    @boxForMosaic = @storage.currentBox
    @selectionForMosaic = selection
  end

  def pbSetQuickSwap(value)
    @quickswap = value
    @sprites["arrow"].quickswap = value
  end

#  def pbShowPartyTab
#    @sprites["arrow"].visible = false
#    if !@screen.pbHeldPokemon
#      pbUpdateOverlay(-1)
#      pbSetMosaic(-1)
#    end
#    pbSEPlay("GUI storage show party panel")
#    start_y = @sprites["boxparty"].y   # Graphics.height
#    timer_start = System.uptime
#    loop do
#      @sprites["boxparty"].y = lerp(start_y, start_y - @sprites["boxparty"].height,
#                                    0.4, timer_start, System.uptime)
#      self.update
#      Graphics.update
#      break if @sprites["boxparty"].y == start_y - @sprites["boxparty"].height
#    end
#    Input.update
#    @sprites["arrow"].visible = true
#  end

#  def pbHidePartyTab
#    @sprites["arrow"].visible = false
#    if !@screen.pbHeldPokemon
#      pbUpdateOverlay(-1)
#      pbSetMosaic(-1)
#    end
#    pbSEPlay("GUI storage hide party panel")
#    start_y = @sprites["boxparty"].y   # Graphics.height - @sprites["boxparty"].height
#    timer_start = System.uptime
#    loop do
#      @sprites["boxparty"].y = lerp(start_y, start_y + @sprites["boxparty"].height,
#                                    0.4, timer_start, System.uptime)
#      self.update
#      Graphics.update
#      break if @sprites["boxparty"].y == start_y + @sprites["boxparty"].height
#    end
#    Input.update
#    @sprites["arrow"].visible = true
#  end

  def pbHold(selected)
    pbSEPlay("GUI storage pick up")

    if selected[0] == -1
      @sprites["boxparty"].grabPokemon(selected[1], @sprites["arrow"])
      @selection = selected[1]
      @choseFromParty = true
    else
      @sprites["box"].grabPokemon(selected[1], @sprites["arrow"])
      @selection = selected[1]
      @choseFromParty = false
    end

    while @sprites["arrow"].grabbing?
      Graphics.update
      Input.update
      self.update
    end
  end

  def pbSwap(selected, _heldpoke)
    pbSEPlay("GUI storage pick up")
    heldpokesprite = @sprites["arrow"].heldPokemon
    boxpokesprite = nil
    if selected[0] == -1
      boxpokesprite = @sprites["boxparty"].getPokemon(selected[1])
    else
      boxpokesprite = @sprites["box"].getPokemon(selected[1])
    end
    if selected[0] == -1
      @sprites["boxparty"].setPokemon(selected[1], heldpokesprite)
    else
      @sprites["box"].setPokemon(selected[1], heldpokesprite)
    end
    @sprites["arrow"].setSprite(boxpokesprite)
    @sprites["pokemon"].mosaic_duration = 0.25   # In seconds
    @boxForMosaic = @storage.currentBox
    @selectionForMosaic = selected[1]
  end

  def pbPlace(selected, _heldpoke)
    pbSEPlay("GUI storage put down")
    heldpokesprite = @sprites["arrow"].heldPokemon
    @sprites["arrow"].place
    while @sprites["arrow"].placing?
      Graphics.update
      Input.update
      self.update
    end
    if selected[0] == -1
      @sprites["boxparty"].setPokemon(selected[1], heldpokesprite)
    else
      @sprites["box"].setPokemon(selected[1], heldpokesprite)
    end
    @boxForMosaic = @storage.currentBox
    @selectionForMosaic = selected[1]
  end

  def pbWithdraw(selected, heldpoke, partyindex)
    pbHold(selected) if !heldpoke
    #pbShowPartyTab
    pbPartySetArrow(@sprites["arrow"], partyindex)
    pbPlace([-1, partyindex], heldpoke)
    #pbHidePartyTab
  end

  def pbStore(selected, heldpoke, destbox, firstfree)
    if heldpoke
      if destbox == @storage.currentBox
        heldpokesprite = @sprites["arrow"].heldPokemon
        @sprites["box"].setPokemon(firstfree, heldpokesprite)
        @sprites["arrow"].setSprite(nil)
      else
        @sprites["arrow"].deleteSprite
      end
    else
      sprite = @sprites["boxparty"].getPokemon(selected[1])
      if destbox == @storage.currentBox
        @sprites["box"].setPokemon(firstfree, sprite)
        @sprites["boxparty"].setPokemon(selected[1], nil)
      else
        @sprites["boxparty"].deletePokemon(selected[1])
      end
    end
  end

  def pbRelease(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    if heldpoke
      sprite = @sprites["arrow"].heldPokemon
    elsif box == -1
      sprite = @sprites["boxparty"].getPokemon(index)
    else
      sprite = @sprites["box"].getPokemon(index)
    end
    if sprite
      sprite.release
      while sprite.releasing?
        Graphics.update
        sprite.update
        self.update
      end
    end
  end

  def pbChooseBox(msg)
    commands = []
    @storage.maxBoxes.times do |i|
      box = @storage[i]
      if box
        commands.push(_INTL("{1} ({2}/{3})", box.name, box.nitems, box.length))
      end
    end
    return pbShowCommands(msg, commands, @storage.currentBox)
  end

  def pbBoxName(helptext, minchars, maxchars)
    oldsprites = pbFadeOutAndHide(@sprites)
    ret = pbEnterBoxName(helptext, minchars, maxchars)
    @storage[@storage.currentBox].name = ret if ret.length > 0
    @sprites["box"].refreshBox = true
    pbRefresh
    pbFadeInAndShow(@sprites, oldsprites)
  end

  def pbChooseItem(bag)
    ret = nil
    pbFadeOutIn do
      scene = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, bag)
      ret = screen.pbChooseItemScreen(proc { |item| GameData::Item.get(item).can_hold? })
    end
    return ret
  end

  def pbSummary(selected, heldpoke)
    oldsprites = pbFadeOutAndHide(@sprites)
    scene = PokemonSummary_Scene.new
    screen = PokemonSummaryScreen.new(scene)
    if heldpoke
      screen.pbStartScreen([heldpoke], 0)
    elsif selected[0] == -1
      @selection = screen.pbStartScreen(@storage.party, selected[1])
      pbPartySetArrow(@sprites["arrow"], @selection)
      pbUpdateOverlay(@selection, @storage.party)
    else
      @selection = screen.pbStartScreen(@storage.boxes[selected[0]], selected[1])
      pbSetArrow(@sprites["arrow"], @selection)
      pbUpdateOverlay(@selection)
    end
    pbFadeInAndShow(@sprites, oldsprites)
  end

  def pbMarkingSetArrow(arrow, selection)
    if selection >= 0
      xvalues = [162, 191, 220, 162, 191, 220, 184, 184]
      yvalues = [24, 24, 24, 49, 49, 49, 77, 109]
      arrow.angle = 0
      arrow.mirror = false
      arrow.ox = 0
      arrow.oy = 0
      arrow.x = xvalues[selection] * 2
      arrow.y = yvalues[selection] * 2
    end
  end

  def pbMarkingChangeSelection(key, selection)
    case key
    when :left
      if selection < 6
        selection -= 1
        selection += 3 if selection % 3 == 2
      end
    when :right
      if selection < 6
        selection += 1
        selection -= 3 if selection % 3 == 0
      end
    when :up
      if selection == 7
        selection = 6
      elsif selection == 6
        selection = 4
      elsif selection < 3
        selection = 7
      else
        selection -= 3
      end
    when :down
      if selection == 7
        selection = 1
      elsif selection == 6
        selection = 7
      elsif selection >= 3
        selection = 6
      else
        selection += 3
      end
    end
    return selection
  end

  def pbMark(selected, heldpoke)
    @sprites["markingbg"].visible      = true
    @sprites["markingoverlay"].visible = true
    msg = _INTL("Mark your Pokémon.")
    msgwindow = Window_UnformattedTextPokemon.newWithSize("", 180, 0, Graphics.width - 180, 32)
    msgwindow.viewport       = @viewport
    msgwindow.visible        = true
    msgwindow.letterbyletter = false
    msgwindow.text           = msg
    msgwindow.resizeHeightToFit(msg, Graphics.width - 180)
    pbBottomRight(msgwindow)
    base   = Color.new(248, 248, 248)
    shadow = Color.new(80, 80, 80)
    pokemon = heldpoke
    if heldpoke
      pokemon = heldpoke
    elsif selected[0] == -1
      pokemon = @storage.party[selected[1]]
    else
      pokemon = @storage.boxes[selected[0]][selected[1]]
    end
    markings = pokemon.markings.clone
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
    index = 0
    redraw = true
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    loop do
      # Redraw the markings and text
      if redraw
        @sprites["markingoverlay"].bitmap.clear
        (@markingbitmap.bitmap.width / MARK_WIDTH).times do |i|
          markrect.x = i * MARK_WIDTH
          markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
          @sprites["markingoverlay"].bitmap.blt(336 + (58 * (i % 3)), 106 + (50 * (i / 3)),
                                                @markingbitmap.bitmap, markrect)
        end
        textpos = [
          [_INTL("OK"), 402, 216, :center, base, shadow, :outline],
          [_INTL("Cancel"), 402, 280, :center, base, shadow, :outline]
        ]
        pbDrawTextPositions(@sprites["markingoverlay"].bitmap, textpos)
        pbMarkingSetArrow(@sprites["arrow"], index)
        redraw = false
      end
      Graphics.update
      Input.update
      key = -1
      key = :down if Keybinds.repeat?(:down)
      key = :right if Keybinds.repeat?(:right)
      key = :left if Keybinds.repeat?(:left)
      key = :up if Keybinds.repeat?(:up)
      if key != -1
        oldindex = index
        index = pbMarkingChangeSelection(key, index)
        pbPlayCursorSE if index != oldindex
        pbMarkingSetArrow(@sprites["arrow"], index)
      end
      self.update
      if Keybinds.trigger?(:back)
        pbPlayCancelSE
        break
      elsif Keybinds.trigger?(:use)
        pbPlayDecisionSE
        case index
        when 6   # OK
          pokemon.markings = markings
          break
        when 7   # Cancel
          break
        else
          markings[index] = ((markings[index] || 0) + 1) % mark_variants
          redraw = true
        end
      end
    end
    @sprites["markingbg"].visible      = false
    @sprites["markingoverlay"].visible = false
    msgwindow.dispose
  end

  def pbRefresh
    @sprites["box"].refresh
    @sprites["boxparty"].refresh
  end

  def pbHardRefresh
    oldPartyY = @sprites["boxparty"].y
    @sprites["box"].dispose
    @sprites["box"] = PokemonBoxSprite.new(@storage, @storage.currentBox, @boxviewport)
    @sprites["boxparty"].dispose
    @sprites["boxparty"] = PokemonBoxPartySprite.new(@storage.party, @boxsidesviewport)
    @sprites["boxparty"].y = oldPartyY
  end

  def drawMarkings(bitmap, x, y, _width, _height, markings)
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    (@markingbitmap.bitmap.width / MARK_WIDTH).times do |i|
      markrect.x = i * MARK_WIDTH
      markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
      bitmap.blt(x + (i * MARK_WIDTH), y, @markingbitmap.bitmap, markrect)
    end
  end
  
  def pbShortenTextToFit(bitmap, text, max_width)
    return text if bitmap.text_size(text).width <= max_width

    ellipsis = "..."
    shortened = text.clone

    while shortened.length > 0
      shortened = shortened[0...-1]
      test_text = shortened + ellipsis
      return test_text if bitmap.text_size(test_text).width <= max_width
    end

    return ellipsis
  end

  def pbMoveTypeBoxPosition(type)
    positions = {
      :NORMAL   => 0,
      :FIGHTING => 1,
      :FLYING   => 2,
      :POISON   => 3,
      :GROUND   => 4,
      :ROCK     => 5,
      :BUG      => 6,
      :GHOST    => 7,
      :STEEL    => 8,
      :QMARKS   => 9,
      :FIRE     => 10,
      :WATER    => 11,
      :GRASS    => 12,
      :ELECTRIC => 13,
      :PSYCHIC  => 14,
      :ICE      => 15,
      :DRAGON   => 16,
      :DARK     => 17,
      :FAIRY    => 18,
      :STELLAR  => 19
    }
    return positions[type] || 0
  end

  def pbMoveTypeShadowColor(type)
    case type
    when :NORMAL
      return Color.new(99, 99, 64)
    when :FIGHTING
      return Color.new(82, 21, 18)
    when :FLYING
      return Color.new(57, 49, 82)
    when :POISON
      return Color.new(57, 49, 82)
    when :GROUND
      return Color.new(82, 70, 38)
    when :ROCK
      return Color.new(82, 70, 25)
    when :GHOST
      return Color.new(60, 47, 82)
    when :STEEL
      return Color.new(73, 73, 82)
    when :QMARKS
      return Color.new(53, 82, 73)
    when :FIRE
      return Color.new(82, 44, 16)
    when :WATER
      return Color.new(36, 50, 82)
    when :GRASS
      return Color.new(49, 82, 33)
    when :ELECTRIC
      return Color.new(82, 69, 16)
    when :PSYCHIC
      return Color.new(82, 29, 45)
    when :ICE
      return Color.new(59, 82, 82)
    when :DRAGON
      return Color.new(37, 19, 82)
    when :DARK
      return Color.new(82, 64, 53)
    when :FAIRY
      return Color.new(82, 57, 60)
    when :STELLAR
      return Color.new(128, 120, 112)
    else
      return Color.new(80, 80, 80)
    end
  end

  def pbUpdateOverlay(selection, party = nil)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    buttonbase = Color.new(248, 248, 248)
    buttonshadow = Color.new(80, 80, 80)
    pbDrawTextPositions(
      overlay,
       [[_INTL("Exit"), 306, 334, :center, buttonbase, buttonshadow, :outline]]
    )
    pokemon = nil
    if @screen.pbHeldPokemon
      pokemon = @screen.pbHeldPokemon
    elsif selection >= 0
      pokemon = (party) ? party[selection] : @storage[@storage.currentBox, selection]
    end
	if !pokemon
	  @sprites["pokemon"].visible = false
	  pbSetPokemonGlow(nil)
	  return
	end
	@sprites["pokemon"].visible = true
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    nonbase   = base
    nonshadow = shadow
    pokename = pokemon.name
    textstrings = [
      [pokename, 492, 14, :left, base, shadow]
    ]
    if !pokemon.egg?
      imagepos = []
      if pokemon.male?
        textstrings.push([_INTL("♂"), 664, 14, :left, Color.new(103, 159, 224), Color.new(16, 79, 150)])
      elsif pokemon.female?
        textstrings.push([_INTL("♀"), 664, 14, :left, Color.new(255, 124, 109), Color.new(168, 53, 40)])
      end
	  if @show_moves
	    move_y = 240
	    typebitmap = AnimatedBitmap.new("Graphics/UI/Storage/types")

	    4.times do |i|
		  move = pokemon.moves[i]
		  y = move_y + (i * 36)

          if move
            move_name = pbShortenTextToFit(overlay, move.name, 182)

            type_id = move.display_type(pokemon)
            type_number = pbMoveTypeBoxPosition(type_id)
            type_rect = Rect.new(0, type_number * 34, 198, 34)

            overlay.blt(484, y - 8, typebitmap.bitmap, type_rect)

            shadow_color = pbMoveTypeShadowColor(type_id)
            textstrings.push([
              move_name, 492, y - 2, :left,
              Color.new(248, 248, 248), shadow_color
            ])
          else
            textstrings.push(["---", 492, y - 2, :left, nonbase, nonshadow])
          end
	    end

	    typebitmap.dispose
	    pbDrawImagePositions(overlay, imagepos)
	    pbDrawTextPositions(overlay, textstrings)
	    @sprites["pokemon"].setPokemonBitmap(pokemon)
		pbSetPokemonGlow(pokemon)
	    return
	  end
      imagepos.push([_INTL("Graphics/UI/Storage/overlay_lv"), 488, 246])
      textstrings.push([pokemon.level.to_s, 512, 240, :left, base, shadow])
      if pokemon.ability
	    ability_name = pbShortenTextToFit(overlay, pokemon.ability.name, 182)
		textstrings.push([ability_name, 584, 312, :center, base, shadow])
      else
        textstrings.push([_INTL("No ability"), 584, 312, :center, nonbase, nonshadow])
      end
      if pokemon.item
        textstrings.push([pokemon.item.name, 584, 348, :center, base, shadow])
      else
        textstrings.push([_INTL("No item"), 584, 348, :center, nonbase, nonshadow])
      end
      imagepos.push(["Graphics/UI/shiny", 670, 198]) if pokemon.shiny?
      typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
      pokemon.types.each_with_index do |type, i|
        type_number = GameData::Type.get(type).icon_position
        type_rect = Rect.new(0, type_number * 28, 64, 28)
        type_x = (pokemon.types.length == 1) ? 550 : 516 + (70 * i)
        overlay.blt(type_x, 272, typebitmap.bitmap, type_rect)
      end
      drawMarkings(overlay, 584, 240, 128, 20, pokemon.markings)
      pbDrawImagePositions(overlay, imagepos)
    end
    pbDrawTextPositions(overlay, textstrings)
    @sprites["pokemon"].setPokemonBitmap(pokemon)
	pbSetPokemonGlow(pokemon)
  end

  def pbUpdate
    if defined?(Keybinds)
      Keybinds.update
      if @last_input_device != Keybinds.last_device
        @last_input_device = Keybinds.last_device
        refresh_box_jump_prompts
      end
    end
    pbUpdateSpriteHash(@sprites)

    return if !IASummary::PANORAMA

    p1 = @sprites["panorama1"]
    p2 = @sprites["panorama2"]
    return if !p1 || !p2 || p1.disposed? || p2.disposed?

    speed = 2
    width = p1.bitmap.width

    p1.x -= speed
    p2.x -= speed

    p1.x = p2.x + width if p1.x <= -width
    p2.x = p1.x + width if p2.x <= -width
  end

  def update
    pbUpdate
  end
end

#===============================================================================
# Pokémon storage mechanics
#===============================================================================
class PokemonStorageScreen
  attr_reader :scene
  attr_reader :storage
  attr_accessor :heldpkmn

  def initialize(scene, storage)
    @scene = scene
    @storage = storage
    @pbHeldPokemon = nil
  end

  def pbStartScreen(command)
    $game_temp.in_storage = true
    @heldpkmn = nil
    case command
    when 0   # Organise
      @scene.pbStartBox(self, command)
      loop do
	    pbUpdate
        selected = @scene.pbSelectBox(@storage.party)
        if selected.nil?
          if pbHeldPokemon
            pbDisplay(_INTL("You're holding a Pokémon!"))
            next
          end
          next if pbConfirm(_INTL("Continue Box operations?"))
          break
        elsif selected[0] == -3   # Close box
          if pbHeldPokemon
            pbDisplay(_INTL("You're holding a Pokémon!"))
            next
          end
          if pbConfirm(_INTL("Exit from the Box?"))
            pbSEPlay("PC close")
            break
          end
          next
        elsif selected[0] == -4   # Box name
          pbBoxCommands
        else
          pokemon = @storage[selected[0], selected[1]]
          heldpoke = pbHeldPokemon
          next if !pokemon && !heldpoke
          if @scene.quickswap
            if @heldpkmn
              (pokemon) ? pbSwap(selected) : pbPlace(selected)
            else
              pbHold(selected)
            end
          else
            commands = []
            cmdMove     = -1
            cmdSummary  = -1
            cmdWithdraw = -1
            cmdItem     = -1
            cmdMark     = -1
            cmdRelease  = -1
            cmdDebug    = -1
            if heldpoke
              helptext = _INTL("{1} is selected.", heldpoke.name)
              commands[cmdMove = commands.length] = (pokemon) ? _INTL("Shift") : _INTL("Place")
            elsif pokemon
              helptext = _INTL("{1} is selected.", pokemon.name)
              commands[cmdMove = commands.length] = _INTL("Move")
            end
            commands[cmdSummary = commands.length]  = _INTL("Summary")
            commands[cmdWithdraw = commands.length] = (selected[0] == -1) ? _INTL("Store") : _INTL("Withdraw")
            commands[cmdItem = commands.length]     = _INTL("Item")
            commands[cmdMark = commands.length]     = _INTL("Mark")
            commands[cmdRelease = commands.length]  = _INTL("Release")
            commands[cmdDebug = commands.length]    = _INTL("Debug") if $DEBUG
            commands[commands.length]               = _INTL("Cancel")
            command = pbShowCommands(helptext, commands)
            if cmdMove >= 0 && command == cmdMove   # Move/Shift/Place
              if @heldpkmn
                (pokemon) ? pbSwap(selected) : pbPlace(selected)
              else
                pbHold(selected)
              end
            elsif cmdSummary >= 0 && command == cmdSummary   # Summary
              pbSummary(selected, @heldpkmn)
            elsif cmdWithdraw >= 0 && command == cmdWithdraw   # Store/Withdraw
              (selected[0] == -1) ? pbStore(selected, @heldpkmn) : pbWithdraw(selected, @heldpkmn)
            elsif cmdItem >= 0 && command == cmdItem   # Item
              pbItem(selected, @heldpkmn)
            elsif cmdMark >= 0 && command == cmdMark   # Mark
              pbMark(selected, @heldpkmn)
            elsif cmdRelease >= 0 && command == cmdRelease   # Release
              pbRelease(selected, @heldpkmn)
            elsif cmdDebug >= 0 && command == cmdDebug   # Debug
              pbPokemonDebug((@heldpkmn) ? @heldpkmn : pokemon, selected, heldpoke)
            end
          end
        end
      end
      @scene.pbCloseBox
    when 1   # Withdraw
      @scene.pbStartBox(self, command)
      loop do
        selected = @scene.pbSelectBox(@storage.party)
        if selected.nil?
          next if pbConfirm(_INTL("Continue Box operations?"))
          break
        else
          case selected[0]
          when -2   # Party Pokémon
            pbDisplay(_INTL("Which one will you take?"))
            next
          when -3   # Close box
            if pbConfirm(_INTL("Exit from the Box?"))
              pbSEPlay("PC close")
              break
            end
            next
          when -4   # Box name
            pbBoxCommands
            next
          end
          pokemon = @storage[selected[0], selected[1]]
          next if !pokemon
          command = pbShowCommands(_INTL("{1} is selected.", pokemon.name),
                                   [_INTL("Withdraw"),
                                    _INTL("Summary"),
                                    _INTL("Mark"),
                                    _INTL("Release"),
                                    _INTL("Cancel")])
          case command
          when 0 then pbWithdraw(selected, nil)
          when 1 then pbSummary(selected, nil)
          when 2 then pbMark(selected, nil)
          when 3 then pbRelease(selected, nil)
          end
        end
      end
      @scene.pbCloseBox
    when 2   # Deposit
      @scene.pbStartBox(self, command)
      loop do
        selected = @scene.pbSelectParty(@storage.party)
        if selected == -3   # Close box
          if pbConfirm(_INTL("Exit from the Box?"))
            pbSEPlay("PC close")
            break
          end
          next
        elsif selected < 0
          next if pbConfirm(_INTL("Continue Box operations?"))
          break
        else
          pokemon = @storage[-1, selected]
          next if !pokemon
          command = pbShowCommands(_INTL("{1} is selected.", pokemon.name),
                                   [_INTL("Store"),
                                    _INTL("Summary"),
                                    _INTL("Mark"),
                                    _INTL("Release"),
                                    _INTL("Cancel")])
          case command
          when 0 then pbStore([-1, selected], nil)
          when 1 then pbSummary([-1, selected], nil)
          when 2 then pbMark([-1, selected], nil)
          when 3 then pbRelease([-1, selected], nil)
          end
        end
      end
      @scene.pbCloseBox
    when 3
      @scene.pbStartBox(self, command)
      @scene.pbCloseBox
    end
    $game_temp.in_storage = false
  end

  # For debug purposes.
  def pbUpdate
    @scene.pbUpdate
  end

  # For debug purposes.
  def pbHardRefresh
    @scene.pbHardRefresh
  end

  # For debug purposes.
  def pbRefreshSingle(i)
    @scene.pbUpdateOverlay(i[1], (i[0] == -1) ? @storage.party : nil)
    @scene.pbHardRefresh
  end

  def pbDisplay(message)
    @scene.pbDisplay(message)
  end

  def pbConfirm(str)
    return pbShowCommands(str, [_INTL("Yes"), _INTL("No")]) == 0
  end

  def pbShowCommands(msg, commands, index = 0)
    return @scene.pbShowCommands(msg, commands, index)
  end

  def pbAble?(pokemon)
    pokemon && !pokemon.egg? && pokemon.hp > 0
  end

  def pbAbleCount
    count = 0
    @storage.party.each do |p|
      count += 1 if pbAble?(p)
    end
    return count
  end

  def pbHeldPokemon
    return @heldpkmn
  end

  def pbWithdraw(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    raise _INTL("Can't withdraw from party...") if box == -1
    if @storage.party_full?
      pbDisplay(_INTL("Your party's full!"))
      return false
    end
    @scene.pbWithdraw(selected, heldpoke, @storage.party.length)
    if heldpoke
      @storage.pbMoveCaughtToParty(heldpoke)
      @heldpkmn = nil
    else
      @storage.pbMove(-1, -1, box, index)
    end
    @scene.pbRefresh
    return true
  end

  def pbStore(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    raise _INTL("Can't deposit from box...") if box != -1
    if pbAbleCount <= 1 && pbAble?(@storage[box, index]) && !heldpoke
      pbPlayBuzzerSE
      pbDisplay(_INTL("That's your last Pokémon!"))
    elsif heldpoke&.mail
      pbDisplay(_INTL("Please remove the Mail."))
    elsif !heldpoke && @storage[box, index].mail
      pbDisplay(_INTL("Please remove the Mail."))
    elsif heldpoke&.cannot_store
      pbDisplay(_INTL("{1} refuses to go into storage!", heldpoke.name))
    elsif !heldpoke && @storage[box, index].cannot_store
      pbDisplay(_INTL("{1} refuses to go into storage!", @storage[box, index].name))
    else
      loop do
        destbox = @scene.pbChooseBox(_INTL("Deposit in which Box?"))
        if destbox >= 0
          firstfree = @storage.pbFirstFreePos(destbox)
          if firstfree < 0
            pbDisplay(_INTL("The Box is full."))
            next
          end
          if heldpoke || selected[0] == -1
            p = (heldpoke) ? heldpoke : @storage[-1, index]
            if Settings::HEAL_STORED_POKEMON
              old_ready_evo = p.ready_to_evolve
              p.heal
              p.ready_to_evolve = old_ready_evo
            end
          end
          @scene.pbStore(selected, heldpoke, destbox, firstfree)
          if heldpoke
            @storage.pbMoveCaughtToBox(heldpoke, destbox)
            @heldpkmn = nil
          else
            @storage.pbMove(destbox, -1, -1, index)
          end
        end
        break
      end
      @scene.pbRefresh
    end
  end

def pbHold(selected)
  box = selected[0]
  index = selected[1]

  if box == -1 && pbAble?(@storage[box, index]) && pbAbleCount <= 1
    pbPlayBuzzerSE
    pbDisplay(_INTL("That's your last Pokémon!"))
    return
  end

  @heldFromParty = (box == -1)
  @scene.pbHold(selected)
  @heldpkmn = @storage[box, index]

  if box == -1
    @storage.party[index] = nil
  else
    @storage.pbDelete(box, index)
  end

  @scene.pbRefresh
end

def pbPlace(selected)
  box = selected[0]
  index = selected[1]

  if @storage[box, index]
    raise _INTL("Position {1},{2} is not empty...", box, index)
  elsif box != -1
    if index >= @storage.maxPokemon(box)
      pbDisplay("Can't place that there.")
      return
    elsif @heldpkmn.mail
      pbDisplay("Please remove the mail.")
      return
    elsif @heldpkmn.cannot_store
      pbDisplay(_INTL("{1} refuses to go into storage!", @heldpkmn.name))
      return
    end
  end

  if Settings::HEAL_STORED_POKEMON && box >= 0
    old_ready_evo = @heldpkmn.ready_to_evolve
    @heldpkmn.heal
    @heldpkmn.ready_to_evolve = old_ready_evo
  end

  @scene.pbPlace(selected, @heldpkmn)
  @storage[box, index] = @heldpkmn

  if box == -1 || @heldFromParty
    @storage.party.compact!
    @scene.pbHardRefresh
  else
    @scene.pbRefresh
  end

  @heldpkmn = nil
  @heldFromParty = false
end

  def pbSwap(selected)
    box = selected[0]
    index = selected[1]
    if !@storage[box, index]
      raise _INTL("Position {1},{2} is empty...", box, index)
    end
    if @heldpkmn.cannot_store && box != -1
      pbPlayBuzzerSE
      pbDisplay(_INTL("{1} refuses to go into storage!", @heldpkmn.name))
      return false
    elsif box == -1 && pbAble?(@storage[box, index]) && pbAbleCount <= 1 && !pbAble?(@heldpkmn)
      pbPlayBuzzerSE
      pbDisplay(_INTL("That's your last Pokémon!"))
      return false
    end
    if box != -1 && @heldpkmn.mail
      pbDisplay("Please remove the mail.")
      return false
    end
    if Settings::HEAL_STORED_POKEMON && box >= 0
      old_ready_evo = @heldpkmn.ready_to_evolve
      @heldpkmn.heal
      @heldpkmn.ready_to_evolve = old_ready_evo
    end
    @scene.pbSwap(selected, @heldpkmn)
    tmp = @storage[box, index]
    @storage[box, index] = @heldpkmn
    @heldpkmn = tmp
    @scene.pbRefresh
    return true
  end

  def pbRelease(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    pokemon = (heldpoke) ? heldpoke : @storage[box, index]
    return if !pokemon
    if pokemon.egg?
      pbDisplay(_INTL("You can't release an Egg."))
      return false
    elsif pokemon.mail
      pbDisplay(_INTL("Please remove the mail."))
      return false
    elsif pokemon.cannot_release
      pbDisplay(_INTL("{1} refuses to leave you!", pokemon.name))
      return false
    end
    if box == -1 && pbAbleCount <= 1 && pbAble?(pokemon) && !heldpoke
      pbPlayBuzzerSE
      pbDisplay(_INTL("That's your last Pokémon!"))
      return
    end
    command = pbShowCommands(_INTL("Release this Pokémon?"), [_INTL("No"), _INTL("Yes")])
    if command == 1
      pkmnname = pokemon.name
      @scene.pbRelease(selected, heldpoke)
      if heldpoke
        @heldpkmn = nil
      else
        @storage.pbDelete(box, index)
      end
      @scene.pbRefresh
      pbDisplay(_INTL("{1} was released.", pkmnname))
      pbDisplay(_INTL("Bye-bye, {1}!", pkmnname))
      @scene.pbRefresh
    end
    return
  end

  def pbChooseMove(pkmn, helptext, index = 0)
    movenames = []
    pkmn.moves.each do |i|
      if i.total_pp <= 0
        movenames.push(_INTL("{1} (PP: ---)", i.name))
      else
        movenames.push(_INTL("{1} (PP: {2}/{3})", i.name, i.pp, i.total_pp))
      end
    end
    return @scene.pbShowCommands(helptext, movenames, index)
  end

  def pbSummary(selected, heldpoke)
    @scene.pbSummary(selected, heldpoke)
  end

  def pbMark(selected, heldpoke)
    @scene.pbMark(selected, heldpoke)
  end

  def pbItem(selected, heldpoke)
    box = selected[0]
    index = selected[1]
    pokemon = (heldpoke) ? heldpoke : @storage[box, index]
    if pokemon.egg?
      pbDisplay(_INTL("Eggs can't hold items."))
      return
    elsif pokemon.mail
      pbDisplay(_INTL("Please remove the mail."))
      return
    end
    if pokemon.item
      itemname = pokemon.item.portion_name
      if pbConfirm(_INTL("Take the {1}?", itemname))
        if $bag.add(pokemon.item)
          pbDisplay(_INTL("Took the {1}.", itemname))
          pokemon.item = nil
          @scene.pbHardRefresh
        else
          pbDisplay(_INTL("Can't store the {1}.", itemname))
        end
      end
    else
      item = scene.pbChooseItem($bag)
      if item
        itemname = GameData::Item.get(item).name
        pokemon.item = item
        $bag.remove(item)
        pbDisplay(_INTL("{1} is now being held.", itemname))
        @scene.pbHardRefresh
      end
    end
  end

  def pbBoxCommands
    commands = [
      _INTL("Jump"),
      _INTL("Wallpaper"),
      _INTL("Name"),
      _INTL("Cancel")
    ]
    command = pbShowCommands(_INTL("What do you want to do?"), commands)
    case command
    when 0
      destbox = @scene.pbChooseBox(_INTL("Jump to which Box?"))
      @scene.pbJumpToBox(destbox) if destbox >= 0
    when 1
      papers = @storage.availableWallpapers
      index = 0
      papers[1].length.times do |i|
        if papers[1][i] == @storage[@storage.currentBox].background
          index = i
          break
        end
      end
      wpaper = pbShowCommands(_INTL("Pick the wallpaper."), papers[0], index)
      @scene.pbChangeBackground(papers[1][wpaper]) if wpaper >= 0
    when 2
      @scene.pbBoxName(_INTL("Box name?"), 0, 12)
    end
  end

  def pbChoosePokemon(_party = nil)
    $game_temp.in_storage = true
    @heldpkmn = nil
    @scene.pbStartBox(self, 1)
    retval = nil
    loop do
      selected = @scene.pbSelectBox(@storage.party)
      if selected && selected[0] == -3   # Close box
        if pbConfirm(_INTL("Exit from the Box?"))
          pbSEPlay("PC close")
          break
        end
        next
      end
      if selected.nil?
        next if pbConfirm(_INTL("Continue Box operations?"))
        break
      elsif selected[0] == -4   # Box name
        pbBoxCommands
      else
        pokemon = @storage[selected[0], selected[1]]
        next if !pokemon
        commands = [
          _INTL("Select"),
          _INTL("Summary"),
          _INTL("Withdraw"),
          _INTL("Item"),
          _INTL("Mark")
        ]
        commands.push(_INTL("Cancel"))
        commands[2] = _INTL("Store") if selected[0] == -1
        helptext = _INTL("{1} is selected.", pokemon.name)
        command = pbShowCommands(helptext, commands)
        case command
        when 0   # Select
          if pokemon
            retval = selected
            break
          end
        when 1
          pbSummary(selected, nil)
        when 2   # Store/Withdraw
          if selected[0] == -1
            pbStore(selected, nil)
          else
            pbWithdraw(selected, nil)
          end
        when 3
          pbItem(selected, nil)
        when 4
          pbMark(selected, nil)
        end
      end
    end
    @scene.pbCloseBox
    $game_temp.in_storage = false
    return retval
  end
end
