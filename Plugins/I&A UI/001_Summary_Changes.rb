#===============================================================================
#
#===============================================================================

class Sprite
  def create_outline(color, thickness = 2)
    return false if !self.bitmap
    # creates temp outline bmp
    alpha = 1
    bmp = Bitmap.new(self.bitmap.width + (thickness * 2), self.bitmap.height + (thickness * 2))
    clone = self.bitmap.clone
    clone_2 = self.bitmap.clone
    clone_cl = Bitmap.new(self.bitmap.width, self.bitmap.height)
    # get pixels from bitmap
    pixels = clone_2.raw_data.unpack('I*')
    for i in 0...pixels.length
      # get RGBA values from 24 bit INT
      b  =  pixels[i] & 255
      g  = (pixels[i] >> 8) & 255
      r  = (pixels[i] >> 16) & 255
      pa = (pixels[i] >> 24) & 255
      # proceed only if alpha > 0
      if pa > 0
        # calculate new RGB values
        r = alpha * color.red + (1 - alpha) * r
        g = alpha * color.green + (1 - alpha) * g
        b = alpha * color.blue + (1 - alpha) * b
        # convert RGBA to 24 bit INT
        pixels[i] = pa.to_i << 24 | b.to_i << 16 | g.to_i << 8 | r.to_i
      end
    end
    # pack data
    clone_cl.raw_data = pixels.pack('I*')
    [[thickness, 0], [thickness, thickness], [0, thickness],
     [-thickness, thickness], [-thickness, 0], [-thickness, -thickness],
     [0, -thickness], [thickness, -thickness]].each do |x, y|
      bmp.blt(x + thickness, y + thickness, clone_cl, Rect.new(0, 0, clone_cl.width, clone_cl.height))
    end
    bmp.blt(thickness, thickness, clone, Rect.new(0, 0, clone.width, clone.height))
    self.bitmap&.dispose
    self.bitmap = bmp.clone
    # disposes temp outline bitmap
    bmp.dispose
    clone.dispose
    clone_2.dispose
    clone_cl.dispose
  end
end

class MoveSelectionSprite < Sprite
  attr_reader :preselected
  attr_reader :index

  def initialize(viewport = nil, fifthmove = false)
    super(viewport)
	@movesel = AnimatedBitmap.new("Graphics/UI/Summary/cursor_move")
	@frame = 0
	@index = 0
	@fifthmove = fifthmove
	@preselected = false
	@updating = false
    refresh
  end

  def dispose
	@movesel.dispose
    super
  end

  def index=(value)
	@index = value
    refresh
  end

  def preselected=(value)
	@preselected = value
    refresh
  end

  def refresh
    w = @movesel.width
    h = @movesel.height / 2
    self.x = 410
    self.y = 100 + (self.index * 68)
    self.y -= 76 if @fifthmove
    self.y += 22 if @fifthmove && self.index == Pokemon::MAX_MOVES   # Add a gap
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0, h, w, h)
    else
      self.src_rect.set(0, 0, w, h)
    end
  end

  def update
	@updating = true
    super
	@movesel.update
	@updating = false
    refresh
  end
end

#===============================================================================
#
#===============================================================================
class RibbonSelectionSprite < MoveSelectionSprite
  def initialize(viewport = nil)
    super(viewport)
	@movesel = AnimatedBitmap.new("Graphics/UI/Summary/cursor_ribbon")
	@frame = 0
	@index = 0
	@preselected = false
	@updating = false
	@spriteVisible = true
    refresh
  end

  def visible=(value)
    super
	@spriteVisible = value if !@updating
  end

  def refresh
    w = @movesel.width
    h = @movesel.height / 2
    self.x = 228 + ((self.index % 4) * 68)
    self.y = 76 + ((self.index / 4).floor * 68)
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0, h, w, h)
    else
      self.src_rect.set(0, 0, w, h)
    end
  end

  def update
	@updating = true
    super
    self.visible = @spriteVisible && @index >= 0 && @index < 12
	@movesel.update
	@updating = false
    refresh
  end
end

#===============================================================================
#
#===============================================================================
class PokemonSummary_Scene
  MARK_WIDTH  = 16
  MARK_HEIGHT = 16

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
	@sprites["panorama"].x  = 0 if @sprites["panorama"].x == - 56
	@sprites["panorama"].x -= 2 if IASummary::PANORAMA == true
	@sprites["panorama"].setBitmap("Graphics/UI/Summary/bg_pan_io") if IASummary::IAVERSION == 2
  end

  def pbStartScene(party, partyindex, inbattle = false)
	@viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
	@viewport.z = 99999
	@party      = party
	@partyindex = partyindex
	@pokemon    = @party[@partyindex]
	@inbattle   = inbattle
	@White		= Tone.new(255,255,255)
	@page = 1
	@typebitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
	@markingbitmap = AnimatedBitmap.new("Graphics/UI/Summary/markings")
	@sprites = {}
	@sprites["panorama"] = IconSprite.new(0, 0, @viewport)
	@sprites["panorama"].setBitmap("Graphics/UI/Summary/bg_pan_am")
	@sprites["background"] = IconSprite.new(0, 0, @viewport)
	white = Tone.new(255, 255, 255)
    @sprites["pokemonglow1"] = PokemonSprite.new(@viewport)
	@sprites["pokemonglow1"].x = 294
	@sprites["pokemonglow1"].y = 186
    @sprites["pokemonglow1"].z = 300
    @sprites["pokemonglow1"].setPokemonBitmap(@pokemon)
    @sprites["pokemonglow1"].tone = white
	@sprites["pokemonglow1"].opacity = 120
    @sprites["pokemonglow2"] = PokemonSprite.new(@viewport)
	@sprites["pokemonglow2"].x = 298
	@sprites["pokemonglow2"].y = 186
    @sprites["pokemonglow2"].z = 300
    @sprites["pokemonglow2"].setPokemonBitmap(@pokemon)
    @sprites["pokemonglow2"].tone = white
	@sprites["pokemonglow2"].opacity = 120
    @sprites["pokemonglow3"] = PokemonSprite.new(@viewport)
	@sprites["pokemonglow3"].x = 296
	@sprites["pokemonglow3"].y = 184
    @sprites["pokemonglow3"].z = 300
    @sprites["pokemonglow3"].setPokemonBitmap(@pokemon)
    @sprites["pokemonglow3"].tone = white
	@sprites["pokemonglow3"].opacity = 120
    @sprites["pokemonglow4"] = PokemonSprite.new(@viewport)
	@sprites["pokemonglow4"].x = 296
	@sprites["pokemonglow4"].y = 188
    @sprites["pokemonglow4"].z = 300
    @sprites["pokemonglow4"].setPokemonBitmap(@pokemon)
    @sprites["pokemonglow4"].tone = white
	@sprites["pokemonglow4"].opacity = 120
	@sprites["pokemon"] = PokemonSprite.new(@viewport)
	@sprites["pokemon"].setOffset(PictureOrigin::CENTER)
	@sprites["pokemon"].x = 296
	@sprites["pokemon"].y = 186
    @sprites["pokemon"].z = 301
	@sprites["pokemon"].setPokemonBitmap(@pokemon)
	@sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
	@sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
	@sprites["pokeicon"].x       = 46
	@sprites["pokeicon"].y       = 92
	@sprites["pokeicon"].visible = false
	@sprites["itemicon"] = ItemIconSprite.new(242, 320, @pokemon.item_id, @viewport)
	@sprites["itemicon"].blankzero = true
	@sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
	@sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
	@sprites["movepresel"].visible     = false
	@sprites["movepresel"].preselected = true
	@sprites["movesel"] = MoveSelectionSprite.new(@viewport)
	@sprites["movesel"].visible = false
	@sprites["ribbonpresel"] = RibbonSelectionSprite.new(@viewport)
	@sprites["ribbonpresel"].visible     = false
	@sprites["ribbonpresel"].preselected = true
	@sprites["ribbonsel"] = RibbonSelectionSprite.new(@viewport)
	@sprites["ribbonsel"].visible = false
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/UI/up_arrow", 8, 28, 40, 2, @viewport)
    @sprites["uparrow"].x = 350
    @sprites["uparrow"].y = 56
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/UI/down_arrow", 8, 28, 40, 2, @viewport)
    @sprites["downarrow"].x = 350
    @sprites["downarrow"].y = 260
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
	@sprites["markingbg"] = IconSprite.new(260, 88, @viewport)
	@sprites["markingbg"].setBitmap("Graphics/UI/Summary/overlay_marking")
	@sprites["markingbg"].visible = false
	@sprites["markingoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
	@sprites["markingoverlay"].visible = false
    pbSetSystemFont(@sprites["markingoverlay"].bitmap)
	@sprites["markingsel"] = IconSprite.new(0, 0, @viewport)
	@sprites["markingsel"].setBitmap("Graphics/UI/Summary/cursor_marking")
	@sprites["markingsel"].src_rect.height = @sprites["markingsel"].bitmap.height / 2
	@sprites["markingsel"].visible = false
	@sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
	@sprites["messagebox"].viewport       = @viewport
	@sprites["messagebox"].visible        = false
	@sprites["messagebox"].letterbyletter = true
    pbBottomLeftLines(@sprites["messagebox"], 2)
	@nationalDexList = [:NONE]
    GameData::Species.each_species { |s| @nationalDexList.push(s.species) }
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartForgetScene(party, partyindex, move_to_learn)
	@viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
	@viewport.z = 99999
	@party      = party
	@partyindex = partyindex
	@pokemon    = @party[@partyindex]
	@page = 4
	@typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
	@sprites = {}
	@sprites["panorama"] = IconSprite.new(0, 0, @viewport)
	@sprites["panorama"].setBitmap("Graphics/UI/Summary/bg_pan_am")
	@sprites["background"] = IconSprite.new(0, 0, @viewport)
	@sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
	@sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
	@sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
	@sprites["pokeicon"].x       = 46
	@sprites["pokeicon"].y       = 92
	@sprites["movesel"] = MoveSelectionSprite.new(@viewport, !move_to_learn.nil?)
	@sprites["movesel"].visible = false
	@sprites["movesel"].visible = true
	@sprites["movesel"].index   = 0
    new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
    drawSelectedMove(new_move, @pokemon.moves[0])
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
	@typebitmap.dispose
	@markingbitmap&.dispose
	@viewport.dispose
  end

  def pbDisplay(text)
	@sprites["messagebox"].text = text
	@sprites["messagebox"].visible = true
    pbPlayDecisionSE
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["messagebox"].busy?
        if Input.trigger?(Input::USE)
          pbPlayDecisionSE if @sprites["messagebox"].pausing?
      	@sprites["messagebox"].resume
        end
      elsif Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        break
      end
    end
	@sprites["messagebox"].visible = false
  end

  def pbConfirm(text)
    ret = -1
	@sprites["messagebox"].text    = text
	@sprites["messagebox"].visible = true
    using(cmdwindow = Window_CommandPokemon.new([_INTL("Yes"), _INTL("No")])) {
      cmdwindow.z       = @viewport.z + 1
      cmdwindow.visible = false
      pbBottomRight(cmdwindow)
      cmdwindow.y -= @sprites["messagebox"].height
      loop do
        Graphics.update
        Input.update
        cmdwindow.visible = true if !@sprites["messagebox"].busy?
        cmdwindow.update
        pbUpdate
        if !@sprites["messagebox"].busy?
          if Input.trigger?(Input::BACK)
            ret = false
            break
          elsif Input.trigger?(Input::USE) && @sprites["messagebox"].resume
            ret = (cmdwindow.index == 0)
            break
          end
        end
      end
    }
	@sprites["messagebox"].visible = false
    return ret
  end

  def pbShowCommands(commands, index = 0)
    ret = -1
    using(cmdwindow = Window_CommandPokemon.new(commands)) {
      cmdwindow.z = @viewport.z + 1
      cmdwindow.index = index
      pbBottomRight(cmdwindow)
      loop do
        Graphics.update
        Input.update
        cmdwindow.update
        pbUpdate
        if Input.trigger?(Input::BACK)
          pbPlayCancelSE
          ret = -1
          break
        elsif Input.trigger?(Input::USE)
          pbPlayDecisionSE
          ret = cmdwindow.index
          break
        end
      end
    }
    return ret
  end

  def drawMarkings(bitmap, x, y)
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
    markings = @pokemon.markings
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    (@markingbitmap.bitmap.width / MARK_WIDTH).times do |i|
      markrect.x = i * MARK_WIDTH
      markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
      bitmap.blt(x + (i * MARK_WIDTH), y, @markingbitmap.bitmap, markrect)
    end
  end

  def drawPage(page)
    if @pokemon.egg?
      drawPageOneEgg
      return
    end
	@sprites["itemicon"].item = @pokemon.item_id
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    # Set background image
	@sprites["background"].setBitmap("Graphics/UI/Summary/bg_#{page}")
    imagepos = []
    # Show the Poké Ball containing the Pokémon
    ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
    imagepos.push([ballimage, 186, 40])
    # Show status/fainted/Pokérus infected icon
    status = -1
    if @pokemon.fainted?
      status = GameData::Status.count - 1
    elsif @pokemon.status != :NONE
      status = GameData::Status.get(@pokemon.status).icon_position
    elsif @pokemon.pokerusStage == 1
      status = GameData::Status.count
    end
    if status >= 0
      imagepos.push(["Graphics/UI/statuses", 124, 100, 0, 16 * status, 44, 16])
    end
    # Show Pokérus cured icon
    if @pokemon.pokerusStage == 2
      imagepos.push([sprintf("Graphics/UI/Summary/icon_pokerus"), 176, 100])
    end
    # Show shininess star
    if @pokemon.shiny?
      imagepos.push([sprintf("Graphics/UI/shiny"), 376, 292])
    end
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
    # Write various bits of text
    pagename = [_INTL("INFO"),
                _INTL("TRAINER MEMO"),
                _INTL("STATS"),
				_INTL("VALUES"),
                _INTL("MOVES"),
                _INTL("MEMENTOS")][page - 1]
    textpos = [
      [pagename, 26, 22, 0, base, shadow],
      [@pokemon.name, 296, 48, 2, base, shadow],
      [_INTL("Item"), 278, 324, 0, base, shadow]
    ]
    # Write the held item's name
    if @pokemon.hasItem?
      textpos.push([@pokemon.item.name, 214, 358, 0, Color.new(248, 248, 248), Color.new(104, 104, 104)])
    else
      textpos.push([_INTL("None"), 208, 358, 0, Color.new(248, 248, 248), Color.new(104, 104, 104)])
    end
    # Write the gender symbol
    if @pokemon.male?
      textpos.push([_INTL("♂"), 370, 48, 0, Color.new(103, 159, 224), Color.new(16, 79, 150)])
    elsif @pokemon.female?
      textpos.push([_INTL("♀"), 370, 48, 0, Color.new(255, 124, 109), Color.new(168, 53, 40)])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw the Pokémon's markings
    drawMarkings(overlay, 276, 292)
    # Draw page-specific information
    case page
    when 1 then drawPageOne
    when 2 then drawPageTwo
    when 3 then drawPageThree
	when 4 then drawPageBaseIVEV
    when 5 then drawPageFour
    when 6 then drawPageFive
    end
  end

  def drawPageOne
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    dexNumBase   = (@pokemon.shiny?) ? Color.new(248, 56, 32) : Color.new(248, 248, 248)
    dexNumShadow = (@pokemon.shiny?) ? Color.new(224, 152, 144) : Color.new(104, 104, 104)
    # If a Shadow Pokémon, draw the heart gauge area and bar
    if @pokemon.shadowPokemon?
      shadowfract = @pokemon.heart_gauge.to_f / @pokemon.max_gauge_size
      imagepos = [
        ["Graphics/UI/Summary/overlay_shadow", 224, 240],
        ["Graphics/UI/Summary/overlay_shadowbar", 242, 280, 0, 0, (shadowfract * 248).floor, -1]
      ]
      pbDrawImagePositions(overlay, imagepos)
    end
    # Write various bits of text
    textpos = [
	  [_INTL("Ability"), 26, 56, 0, base, shadow],
      [_INTL("Level"), 410, 54, 0, base, shadow],
	  [@pokemon.level.to_s, 607, 54, 2, base, shadow],
	  [_INTL("Dex No."), 410, 118, 0, base, shadow],
      [_INTL("Species"), 410, 86, 0, base, shadow],
      [@pokemon.speciesName, 607, 86, 2, base, shadow],
      [_INTL("Type"), 410, 150, 0, base, shadow],
      [_INTL("OT"), 410, 182, 0, base, shadow],
      [_INTL("ID No."), 410, 214, 0, base, shadow]
    ]
	# Draw ability name and description
    ability = @pokemon.ability
	abilityname = @pokemon.ability.name
	combined_abilitykey = "#{abilityname}:\nPress [Special] to view the Ability Page."
    if ability
      drawTextEx(overlay, 8, 92, 178, 8, combined_abilitykey, base, shadow)
    end
    # Write the Regional/National Dex number
    dexnum = 0
    dexnumshift = false
    if $player.pokedex.unlocked?(-1)   # National Dex is unlocked
      dexnum = @nationalDexList.index(@pokemon.species_data.species) || 0
      dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(-1)
    else
      ($player.pokedex.dexes_count - 1).times do |i|
        next if !$player.pokedex.unlocked?(i)
        num = pbGetRegionalNumber(i, @pokemon.species)
        next if num <= 0
        dexnum = num
        dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(i)
        break
      end
    end
    if dexnum <= 0
      textpos.push(["???", 607, 118, 2, base, shadow])
    else
      dexnum -= 1 if dexnumshift
      textpos.push([sprintf("%03d", dexnum), 607, 118, 2, base, shadow])
    end
    # Write Original Trainer's name and ID number
    if @pokemon.owner.name.empty?
      textpos.push([_INTL("RENTAL"), 607, 182, 2, base, shadow])
      textpos.push(["?????", 607, 214, 2, base, shadow])
    else
      ownerbase   = base
      ownershadow = shadow
      case @pokemon.owner.gender
      when 0
        ownerbase = Color.new(103, 159, 224)
        ownershadow = Color.new(16, 79, 150)
      when 1
        ownerbase = Color.new(255, 124, 109)
        ownershadow = Color.new(168, 53, 40)
	  when 2
        ownerbase = Color.new(75, 221, 75)
        ownershadow = Color.new(10, 138, 10)
      end
      textpos.push([@pokemon.owner.name, 607, 182, 2, ownerbase, ownershadow])
      textpos.push([sprintf("%05d", @pokemon.owner.public_id), 607, 214, 2,
                    base, shadow])
    end
    # Write Exp text OR heart gauge message (if a Shadow Pokémon)
    if @pokemon.shadowPokemon?
      textpos.push([_INTL("Heart Gauge"), 410, 246, 0, base, shadow])
      heartmessage = [_INTL("The door to its heart is open! Undo the final lock!"),
                      _INTL("The door to its heart is almost fully open."),
                      _INTL("The door to its heart is nearly open."),
                      _INTL("The door to its heart is opening wider."),
                      _INTL("The door to its heart is opening up."),
                      _INTL("The door to its heart is tightly shut.")][@pokemon.heartStage]
      memo = sprintf("<c3=f8f8f8,686868>%s\n", heartmessage)
      drawFormattedTextEx(overlay, 410, 308, 264, memo)
    else
      endexp = @pokemon.growth_rate.minimum_exp_for_level(@pokemon.level + 1)
      textpos.push([_INTL("Exp. Points"), 410, 246, 0, base, shadow])
      textpos.push([@pokemon.exp.to_s_formatted, 520, 278, 1, base, shadow])
      textpos.push([_INTL("To Next Lv."), 410, 310, 0, base, shadow])
      textpos.push([(endexp - @pokemon.exp).to_s_formatted, 520, 342, 1, base, shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw Pokémon type(s)
	@pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * 28, 64, 28)
      type_x = (@pokemon.types.length == 1) ? 576 : 542 + (66 * i)
      overlay.blt(type_x, 146, @typebitmap.bitmap, type_rect)
    end
    # Draw Exp bar
    if @pokemon.level < GameData::GrowthRate.max_level
      w = @pokemon.exp_fraction * 128
      w = ((w / 2).round) * 2
      pbDrawImagePositions(overlay,
                           [["Graphics/UI/Summary/overlay_exp", 544, 352, 0, 0, w, 6]])
    end
  end

  def drawPageOneEgg
	@sprites["itemicon"].item = @pokemon.item_id
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    # Set background image
	@sprites["background"].setBitmap("Graphics/UI/Summary/bg_egg")
    imagepos = []
    # Show the Poké Ball containing the Pokémon
    ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
    imagepos.push([ballimage, 206, 40])
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
    # Write various bits of text
    textpos = [
      [_INTL("TRAINER MEMO"), 26, 22, 0, base, shadow],
      [@pokemon.name, 46, 68, 0, base, shadow],
      [_INTL("Item"), 66, 324, 0, base, shadow]
    ]
    # Write the held item's name
    if @pokemon.hasItem?
      textpos.push([@pokemon.item.name, 16, 358, 0, base, shadow])
    else
      textpos.push([_INTL("None"), 16, 358, 0, base, shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    memo = ""
    # Write date received
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      memo += _INTL("<c3=f8f8f8,686868>{1} {2}, {3}\n", date, month, year)
    end
    # Write map name egg was received on
    mapname = pbGetMapNameFromId(@pokemon.obtain_map)
    mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
    if mapname && mapname != ""
      memo += _INTL("<c3=f8f8f8,686868>A mysterious Pokémon Egg received from <c3=ff7c6d,a83528>{1}<c3=f8f8f8,686868>.\n", mapname)
    else
      memo += _INTL("<c3=f8f8f8,686868>A mysterious Pokémon Egg.\n", mapname)
    end
    memo += "\n" # Empty line
    # Write Egg Watch blurb
    memo += _INTL("<c3=f8f8f8,686868>\"The Egg Watch\"\n")
    eggstate = _INTL("It looks like this Egg will take a long time to hatch.")
    eggstate = _INTL("What will hatch from this? It doesn't seem close to hatching.") if @pokemon.steps_to_hatch < 10_200
    eggstate = _INTL("It appears to move occasionally. It may be close to hatching.") if @pokemon.steps_to_hatch < 2550
    eggstate = _INTL("Sounds can be heard coming from inside! It will hatch soon!") if @pokemon.steps_to_hatch < 1275
    memo += sprintf("<c3=f8f8f8,686868>%s\n", eggstate)
    # Draw all text
    drawFormattedTextEx(overlay, 232, 86, 268, memo)
    # Draw the Pokémon's markings
    drawMarkings(overlay, 84, 292)
  end

  def drawPageTwo
	base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
	case @pokemon.scale
		when 0 			#xxxs
			height = @pokemon.species_data.height
			height = (height * 0.68).round
			if System.user_language[3..4] == "US"   # If the user is in the United States
				inches = (height / 0.254).round
				feet = (inches / 12)
				inch = (inches % 12)
				size = _INTL("<c3=f8f8f8,686868>{1}'{2}\" tall\nIt's Miniscule!", feet, inch)
			else
				metres = (height / 10.0)
				size = _INTL("<c3=f8f8f8,686868>{1}m tall\nIt's Miniscule!", metres)
			end
		when 1..24 		#xxs
			height = @pokemon.species_data.height
			height = (height * 0.76).round
			if System.user_language[3..4] == "US"   # If the user is in the United States
				inches = (height / 0.254).round
				feet = (inches / 12)
				inch = (inches % 12)
				size = _INTL("<c3=f8f8f8,686868>{1}'{2}\" tall\nIt's Micro!", feet, inch)
			else
				metres = (height / 10.0)
				size = _INTL("<c3=f8f8f8,686868>{1}m tall\nIt's Micro!", metres)
			end
		when 25..59 	#xs
			height = @pokemon.species_data.height
			height = (height * 0.84).round
			if System.user_language[3..4] == "US"   # If the user is in the United States
				inches = (height / 0.254).round
				feet = (inches / 12)
				inch = (inches % 12)
				size = _INTL("<c3=f8f8f8,686868>{1}'{2}\" tall\nIt's Tiny!", feet, inch)
			else
				metres = (height / 10.0)
				size = _INTL("<c3=f8f8f8,686868>{1}m tall\nIt's Tiny!", metres)
			end
		when 60..99 	#s
			height = @pokemon.species_data.height
			height = (height * 0.92).round
			if System.user_language[3..4] == "US"   # If the user is in the United States
				inches = (height / 0.254).round
				feet = (inches / 12)
				inch = (inches % 12)
				size = _INTL("<c3=f8f8f8,686868>{1}'{2}\" tall\nIt's Small!", feet, inch)
			else
				metres = (height / 10.0)
				size = _INTL("<c3=f8f8f8,686868>{1}m tall\nIt's Small!", metres)
			end
		when 100..155 	#m
			height = @pokemon.species_data.height
			if System.user_language[3..4] == "US"   # If the user is in the United States
				inches = (height / 0.254).round
				feet = (inches / 12)
				inch = (inches % 12)
				size = _INTL("<c3=f8f8f8,686868>{1}'{2}\" tall\nIt's Average!", feet, inch)
			else
				metres = (height / 10.0)
				size = _INTL("<c3=f8f8f8,686868>{1}m tall\nIt's Average!", metres)
			end
		when 156..195 	#l
			height = @pokemon.species_data.height
			height = (height * 1.08).round
			if System.user_language[3..4] == "US"   # If the user is in the United States
				inches = (height / 0.254).round
				feet = (inches / 12)
				inch = (inches % 12)
				size = _INTL("<c3=f8f8f8,686868>{1}'{2}\" tall\nIt's Big!", feet, inch)
			else
				metres = (height / 10.0)
				size = _INTL("<c3=f8f8f8,686868>{1}m tall\nIt's Big!", metres)
			end
		when 196..230 	#xl
			height = @pokemon.species_data.height
			height = (height * 1.16).round
			if System.user_language[3..4] == "US"   # If the user is in the United States
				inches = (height / 0.254).round
				feet = (inches / 12)
				inch = (inches % 12)
				size = _INTL("<c3=f8f8f8,686868>{1}'{2}\" tall\nIt's Large!", feet, inch)
			else
				metres = (height / 10.0)
				size = _INTL("<c3=f8f8f8,686868>{1}m tall\nIt's Large!", metres)
			end
		when 231..254 	#xxl
			height = @pokemon.species_data.height
			height = (height * 1.24).round
			if System.user_language[3..4] == "US"   # If the user is in the United States
				inches = (height / 0.254).round
				feet = (inches / 12)
				inch = (inches % 12)
				size = _INTL("<c3=f8f8f8,686868>{1}'{2}\" tall\nIt's Huge!", feet, inch)
			else
				metres = (height / 10.0)
				size = _INTL("<c3=f8f8f8,686868>{1}m tall\nIt's Huge!", metres)
			end
		when 255		#xxxl
			height = @pokemon.species_data.height
			height = (height * 1.32).round
			if System.user_language[3..4] == "US"   # If the user is in the United States
				inches = (height / 0.254).round
				feet = (inches / 12)
				inch = (inches % 12)
				size = _INTL("<c3=f8f8f8,686868>{1}'{2}\" tall\nIt's Gigantic!", feet, inch)
			else
				metres = (height / 10.0)
				size = _INTL("<c3=f8f8f8,686868>{1}m tall\nIt's Gigantic!", metres)
			end
	end
    overlay = @sprites["overlay"].bitmap
    memo = ""
	textpos = [[_INTL("Mementos"), 26, 56, 0, base, shadow]]
    # Write nature
    showNature = !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
    if showNature
      natureName = @pokemon.nature.name
      memo += _INTL("<c3=ff7c6d,a83528>{1}<c3=f8f8f8,686868> nature.\n", natureName)
    end
    # Write date received
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      memo += _INTL("<c3=f8f8f8,686868>{1} {2}, {3}\n", date, month, year)
    end
    # Write map name Pokémon was received on
    mapname = pbGetMapNameFromId(@pokemon.obtain_map)
    mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
    mapname = _INTL("Faraway place") if nil_or_empty?(mapname)
    memo += sprintf("<c3=ff7c6d,a83528>%s\n", mapname)
    # Write how Pokémon was obtained
    mettext = [_INTL("Met at Lv. {1}.", @pokemon.obtain_level),
               _INTL("Egg received."),
               _INTL("Traded at Lv. {1}.", @pokemon.obtain_level),
               "",
               _INTL("Had a fateful encounter at Lv. {1}.", @pokemon.obtain_level)][@pokemon.obtain_method]
    memo += sprintf("<c3=f8f8f8,686868>%s\n", mettext) if mettext && mettext != ""
    # If Pokémon was hatched, write when and where it hatched
    if @pokemon.obtain_method == 1
      if @pokemon.timeEggHatched
        date  = @pokemon.timeEggHatched.day
        month = pbGetMonthName(@pokemon.timeEggHatched.mon)
        year  = @pokemon.timeEggHatched.year
        memo += _INTL("<c3=f8f8f8,686868>{1} {2}, {3}\n", date, month, year)
      end
      mapname = pbGetMapNameFromId(@pokemon.hatched_map)
      mapname = _INTL("Faraway place") if nil_or_empty?(mapname)
      memo += sprintf("<c3=ff7c6d,a83528>%s\n", mapname)
      memo += _INTL("<c3=f8f8f8,686868>Egg hatched.\n")
    else
      memo += "\n"   # Empty line
    end
    # Write characteristic
    if showNature
      best_stat = nil
      best_iv = 0
      stats_order = [:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE]
      start_point = @pokemon.personalID % stats_order.length   # Tiebreaker
      stats_order.length.times do |i|
        stat = stats_order[(i + start_point) % stats_order.length]
        if !best_stat || @pokemon.iv[stat] > @pokemon.iv[best_stat]
          best_stat = stat
          best_iv = @pokemon.iv[best_stat]
        end
      end
      characteristics = {
        :HP              => [_INTL("Loves to eat."),
                             _INTL("Takes plenty of siestas."),
                             _INTL("Nods off a lot."),
                             _INTL("Scatters things often."),
                             _INTL("Likes to relax.")],
        :ATTACK          => [_INTL("Proud of its power."),
                             _INTL("Likes to thrash about."),
                             _INTL("A little quick tempered."),
                             _INTL("Likes to fight."),
                             _INTL("Quick tempered.")],
        :DEFENSE         => [_INTL("Sturdy body."),
                             _INTL("Capable of taking hits."),
                             _INTL("Highly persistent."),
                             _INTL("Good endurance."),
                             _INTL("Good perseverance.")],
        :SPECIAL_ATTACK  => [_INTL("Highly curious."),
                             _INTL("Mischievous."),
                             _INTL("Thoroughly cunning."),
                             _INTL("Often lost in thought."),
                             _INTL("Very finicky.")],
        :SPECIAL_DEFENSE => [_INTL("Strong willed."),
                             _INTL("Somewhat vain."),
                             _INTL("Strongly defiant."),
                             _INTL("Hates to lose."),
                             _INTL("Somewhat stubborn.")],
        :SPEED           => [_INTL("Likes to run."),
                             _INTL("Alert to sounds."),
                             _INTL("Impetuous and silly."),
                             _INTL("Somewhat of a clown."),
                             _INTL("Quick to flee.")]
      }
      memo += sprintf("<c3=f8f8f8,686868>%s\n", characteristics[best_stat][best_iv % 5])
    end
    # Write all text
    drawFormattedTextEx(overlay, 410, 86, 268, memo)
	drawFormattedTextEx(overlay, 26, 134, 268, size)
  end

  def drawPageThree
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statshadows = {}
    GameData::Stat.each_main { |s| statshadows[s.id] = shadow }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
  	@pokemon.nature_for_stats.stat_changes.each do |change|
        statshadows[change[0]] = Color.new(136, 96, 72) if change[1] > 0
        statshadows[change[0]] = Color.new(64, 120, 152) if change[1] < 0
      end
    end
    # Write various bits of text
    textpos = [
	  [_INTL("Ability"), 26, 56, 0, base, shadow],
      [_INTL("HP"), 478, 82, 2, base, statshadows[:HP]],
      [sprintf("%d/%d", @pokemon.hp, @pokemon.totalhp), 648, 82, 1, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Attack"), 434, 126, 0, base, statshadows[:ATTACK]],
      [sprintf("%d", @pokemon.attack), 642, 126, 1, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Defense"), 434, 158, 0, base, statshadows[:DEFENSE]],
      [sprintf("%d", @pokemon.defense), 642, 158, 1, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Sp. Atk"), 434, 190, 0, base, statshadows[:SPECIAL_ATTACK]],
      [sprintf("%d", @pokemon.spatk), 642, 190, 1, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Sp. Def"), 434, 222, 0, base, statshadows[:SPECIAL_DEFENSE]],
      [sprintf("%d", @pokemon.spdef), 642, 222, 1, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Speed"), 434, 254, 0, base, statshadows[:SPEED]],
      [sprintf("%d", @pokemon.speed), 642, 254, 1, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Tera:"), 434, 356, 0, base, shadow]
    ]
	# Draw ability name and description
    ability = @pokemon.ability
	abilityname = @pokemon.ability.name
	combined_abilitykey = "#{abilityname}:\nPress [Special] to view the Ability Page."
    if ability
      drawTextEx(overlay, 8, 92, 178, 8, combined_abilitykey, base, shadow)
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
		return if !Settings::SUMMARY_TERA_TYPES
		overlay = @sprites["overlay"].bitmap
		coords = [584, 346]
		pbDisplayTeraType(@pokemon, overlay, coords[0], coords[1])
    # Draw HP bar
    if @pokemon.hp > 0
      w = @pokemon.hp * 96 / @pokemon.totalhp.to_f
      w = 1 if w < 1
      w = ((w / 2).round) * 2
      hpzone = 0
      hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
      hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
      imagepos = [
        ["Graphics/UI/Summary/overlay_hp", 546, 110, 0, hpzone * 6, w, 6]
      ]
      pbDrawImagePositions(overlay, imagepos)
    end
  end
  
  def drawPageBaseIVEV
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    ev_total = 0
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statshadows = {}
	@sprites["background"].setBitmap("Graphics/UI/Summary/bg_stats")
    GameData::Stat.each_main { |s| statshadows[s.id] = shadow; ev_total += @pokemon.ev[s.id] }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
      @pokemon.nature_for_stats.stat_changes.each do |change|
        statshadows[change[0]] = Color.new(136, 96, 72) if change[1] > 0
        statshadows[change[0]] = Color.new(64, 120, 152) if change[1] < 0
      end
    end
    # Write various bits of text
    textpos = [
	  [_INTL("Ability"), 26, 56, 0, base, shadow],
      [_INTL("Base"), 556, 94, :center, base, shadow],
      [_INTL("IV"), 602, 94, :center, base, shadow],
      [_INTL("EV"), 648, 94, :center, base, shadow],
      [_INTL("HP"), 434, 126, :left, base, statshadows[:HP]],
      [sprintf("%d", @pokemon.baseStats[:HP]), 576, 126, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.iv[:HP]), 614, 126, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.ev[:HP]), 666, 126, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Attack"), 434, 158, :left, base, statshadows[:ATTACK]],
      [sprintf("%d", @pokemon.baseStats[:ATTACK]), 576, 158, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.iv[:ATTACK]), 614, 158, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.ev[:ATTACK]), 666, 158, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Defense"), 434, 190, :left, base, statshadows[:DEFENSE]],
      [sprintf("%d", @pokemon.baseStats[:DEFENSE]), 576, 190, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.iv[:DEFENSE]), 614, 190, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.ev[:DEFENSE]), 666, 190, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Sp. Atk"), 434, 222, :left, base, statshadows[:SPECIAL_ATTACK]],
      [sprintf("%d", @pokemon.baseStats[:SPECIAL_ATTACK]), 576, 222, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.iv[:SPECIAL_ATTACK]), 614, 222, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.ev[:SPECIAL_ATTACK]), 666, 222, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Sp. Def"), 434, 254, :left, base, statshadows[:SPECIAL_DEFENSE]],
      [sprintf("%d", @pokemon.baseStats[:SPECIAL_DEFENSE]), 576, 254, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.iv[:SPECIAL_DEFENSE]), 614, 254, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.ev[:SPECIAL_DEFENSE]), 666, 254, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Speed"), 434, 286, :left, base, statshadows[:SPEED]],
      [sprintf("%d", @pokemon.baseStats[:SPEED]), 576, 286, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.iv[:SPEED]), 614, 286, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [sprintf("%d", @pokemon.ev[:SPEED]), 666, 286, :right, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Total EV"), 410, 324, :left, base, shadow],
      [sprintf("%d/%d", ev_total, Pokemon::EV_LIMIT), 630, 324, :center, Color.new(248, 248, 248), Color.new(104, 104, 104)],
      [_INTL("Hidden Power"), 404, 356, :left, base, shadow]
    ]
	# Draw ability name and description
    ability = @pokemon.ability
	abilityname = @pokemon.ability.name
	combined_abilitykey = "#{abilityname}:\nPress [Special] to view the Ability Page."
    if ability
      drawTextEx(overlay, 8, 92, 178, 8, combined_abilitykey, base, shadow)
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    hiddenpower = pbHiddenPower(@pokemon)
    type_number = GameData::Type.get(hiddenpower[0]).icon_position
    type_rect = Rect.new(0, type_number * 28, 64, 28)
    overlay.blt(584, 351, @typebitmap.bitmap, type_rect)
  end

  def drawPageFour
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    overlay = @sprites["overlay"].bitmap
    moveBase   = Color.new(248, 248, 248)
    moveShadow = Color.new(104, 104, 104)
    ppBase   = [moveBase,                # More than 1/2 of total PP
                Color.new(248, 192, 0),    # 1/2 of total PP or less
                Color.new(248, 136, 32),   # 1/4 of total PP or less
                Color.new(248, 72, 72)]    # Zero PP
    ppShadow = [moveShadow,             # More than 1/2 of total PP
                Color.new(144, 104, 0),   # 1/2 of total PP or less
                Color.new(144, 72, 24),   # 1/4 of total PP or less
                Color.new(136, 48, 48)]   # Zero PP
	@sprites["pokemon"].visible  = true
	@sprites["pokemonglow1"].visible = true
	@sprites["pokemonglow2"].visible = true
	@sprites["pokemonglow3"].visible = true
	@sprites["pokemonglow4"].visible = true
	@sprites["pokeicon"].visible = false
	@sprites["itemicon"].visible = true
    textpos  = [
	  [_INTL("Ability"), 26, 56, 0, base, shadow]
	  ]
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 104
    Pokemon::MAX_MOVES.times do |i|
      move = @pokemon.moves[i]
      if move
        type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
        imagepos.push(["Graphics/UI/Summary/moves", 410, yPos - 4, 0, type_number * 66, 264, 66])
		textpos.push([move.name, 420, yPos + 6, 0, moveBase, moveShadow])
        if move.total_pp > 0
        # textpos.push([_INTL("PP"), 520, yPos + 36, 0, moveBase, moveShadow])
          ppfraction = 0
          if move.pp == 0
            ppfraction = 3
          elsif move.pp * 4 <= move.total_pp
            ppfraction = 2
          elsif move.pp * 2 <= move.total_pp
            ppfraction = 1
          end
          textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 560, yPos + 36, 0, ppBase[ppfraction], ppShadow[ppfraction]])
        end
      else
        textpos.push(["-", 420, yPos + 6, 0, moveBase, moveShadow])
        textpos.push(["--", 560, yPos + 36, 1, moveBase, moveShadow])
      end
      yPos += 68
    end
	# Draw ability name and description
    ability = @pokemon.ability
	abilityname = @pokemon.ability.name
	combined_abilitykey = "#{abilityname}:\nPress [Special] to view the Ability Page."
    if ability
      drawTextEx(overlay, 8, 92, 178, 8, combined_abilitykey, base, shadow)
    end
    # Draw all text and images
	pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
  end

def drawPageFourSelecting(move_to_learn)
  overlay = @sprites["overlay"].bitmap
  overlay.clear
  base   = Color.new(248, 248, 248)
  shadow = Color.new(104, 104, 104)
  moveBase   = Color.new(248, 248, 248)
  moveShadow = Color.new(104, 104, 104)
  ppBase   = [moveBase,                # More than 1/2 of total PP
              Color.new(248, 192, 0),    # 1/2 of total PP or less
              Color.new(248, 136, 32),   # 1/4 of total PP or less
              Color.new(248, 72, 72)]    # Zero PP
  ppShadow = [moveShadow,             # More than 1/2 of total PP
              Color.new(144, 104, 0),   # 1/2 of total PP or less
              Color.new(144, 72, 24),   # 1/4 of total PP or less
              Color.new(136, 48, 48)]   # Zero PP
  # Set background image
  if move_to_learn
    @sprites["background"].setBitmap("Graphics/UI/Summary/bg_learnmove")
  else
    @sprites["background"].setBitmap("Graphics/UI/Summary/bg_movedetail")
  end
  # Write various bits of text
  textpos = [
    [_INTL("MOVES"), 26, 22, :left, base, shadow],
    [_INTL("CATEGORY"), 20, 128, :left, base, shadow],
    [_INTL("POWER"), 20, 160, :left, base, shadow],
    [_INTL("ACCURACY"), 20, 192, :left, base, shadow]
  ]
  imagepos = []
  # Write move names, types and PP amounts for each known move
  yPos = 104
  yPos -= 76 if move_to_learn
  limit = (move_to_learn) ? Pokemon::MAX_MOVES + 1 : Pokemon::MAX_MOVES
  limit.times do |i|
    move = @pokemon.moves[i]
    if i == Pokemon::MAX_MOVES
      move = move_to_learn
      yPos += 20
    end
    if move
      type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
      # Use moves graphic instead of types
      imagepos.push(["Graphics/UI/Summary/moves", 410, yPos - 4, 0, type_number * 66, 264, 66])
      textpos.push([move.name, 420, yPos + 6, :left, moveBase, moveShadow])
      if move.total_pp > 0
	  # textpos.push([_INTL("PP"), 520, yPos + 36, 0, moveBase, moveShadow])
        ppfraction = 0
          if move.pp == 0
            ppfraction = 3
          elsif move.pp * 4 <= move.total_pp
            ppfraction = 2
          elsif move.pp * 2 <= move.total_pp
            ppfraction = 1
          end
        textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 560, yPos + 36, 0, ppBase[ppfraction], ppShadow[ppfraction]])
      end
    else
      textpos.push(["-", 420, yPos + 6, :left, moveBase, moveShadow])
      textpos.push(["--", 560, yPos + 36, :right, moveBase, moveShadow])
    end
    yPos += 68
  end
  # Draw all text and images
  pbDrawImagePositions(overlay, imagepos)
  pbDrawTextPositions(overlay, textpos)
  # Draw Pokémon's type icon(s)
  @pokemon.types.each_with_index do |type, i|
    type_number = GameData::Type.get(type).icon_position
    type_rect = Rect.new(0, type_number * 28, 64, 28)
    type_x = (@pokemon.types.length == 1) ? 130 : 96 + (70 * i)
    overlay.blt(type_x, 78, @typebitmap.bitmap, type_rect)
  end
end

  def drawSelectedMove(move_to_learn, selected_move)
    # Draw all of page four, except selected move's details
    drawPageFourSelecting(move_to_learn)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    base    = Color.new(248, 248, 248)
    shadow  = Color.new(104, 104, 104)
    @sprites["pokemon"].visible = false if @sprites["pokemon"]
	@sprites["pokemonglow1"].visible = false if @sprites["pokemon"]
	@sprites["pokemonglow2"].visible = false if @sprites["pokemon"]
	@sprites["pokemonglow3"].visible = false if @sprites["pokemon"]
	@sprites["pokemonglow4"].visible = false if @sprites["pokemon"]
    @sprites["pokeicon"].pokemon = @pokemon
    @sprites["pokeicon"].visible = true
    @sprites["itemicon"].visible = false if @sprites["itemicon"]
    textpos = []
    # Write power and accuracy values for selected move
    case selected_move.display_damage(@pokemon)
    when 0 then textpos.push(["---", 216, 160, :right, base, shadow])   # Status move
    when 1 then textpos.push(["???", 216, 160, :right, base, shadow])   # Variable power move
    else        textpos.push([selected_move.display_damage(@pokemon).to_s, 216, 160, :right, base, shadow])
    end
    if selected_move.display_accuracy(@pokemon) == 0
      textpos.push(["---", 216, 192, :right, base, shadow])
    else
      textpos.push(["#{selected_move.display_accuracy(@pokemon)}%", 216 + overlay.text_size("%").width, 192, :right, base, shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw selected move's damage category icon
    imagepos = [["Graphics/UI/category", 166, 124, 0, selected_move.display_category(@pokemon) * 28, 64, 28]]
    pbDrawImagePositions(overlay, imagepos)
    # Draw selected move's description
    drawTextEx(overlay, 4, 224, 388, 5, selected_move.description, base, shadow)
  end

  def drawPageFive
    overlay = @sprites["overlay"].bitmap
    blkBase   = Color.new(255, 124, 109)
    blkShadow = Color.new(168, 53, 40)
    whtBase   = Color.new(248, 248, 248)
    whtShadow = Color.new(104, 104, 104)
    @sprites["uparrow"].visible   = false
    @sprites["downarrow"].visible = false
    path  = Settings::MEMENTOS_GRAPHICS_PATH
    idnum = type = name = title = "---"
    memento_data = GameData::Ribbon.try_get(@pokemon.memento)
    xpos = (PluginManager.installed?("BW Summary Screen")) ? -4 : 218
    ypos = (PluginManager.installed?("BW Summary Screen")) ? 70 : 74
    imagepos = []
    if memento_data
      icon  = memento_data.icon_position
      idnum = (icon + 1).to_s
      rank  = @pokemon.getMementoRank(@pokemon.memento)
      name  = memento_data.name
      title = "'#{memento_data.title_upcase}'"
      type  = (memento_data.is_ribbon?) ? "Ribbon" : "Mark"
      typeX = (memento_data.is_ribbon?) ? 362 : 372
      imagepos.push([path + "mementos", xpos + 190, ypos + 14, 78 * (icon % 8), 78 * (icon / 8).floor, 78, 78],
                    [path + "memento_icon", xpos + typeX, ypos + 7, (memento_data.is_ribbon?) ? 0 : 28, 0, 28, 28])
      if rank < 5
        rank.times do |i| 
          offset = (rank == 1) ? 44 : (rank == 2) ? 35 : (rank == 3) ? 26 : 17
          imagepos.push([path + "memento_rank", xpos + 360 + offset + (18 * i), ypos + 77])
        end
      else
        imagepos.push([path + "memento_rank", xpos + 424, ypos + 77])
      end
    end
    pbDrawImagePositions(overlay, imagepos)
    textpos = [
      [_INTL("Type:"),            xpos + 282, ypos + 12,  0, whtBase, whtShadow],
      [_INTL("ID No.:"),          xpos + 282, ypos + 44,  0, whtBase, whtShadow],
      [_INTL("#{idnum}"),         xpos + 412, ypos + 44,  2, blkBase, blkShadow],
      [_INTL("Rank:"),            xpos + 282, ypos + 76,  0, whtBase, whtShadow],
      [_INTL("Name:"),            xpos + 323, ypos + 116, 2, whtBase, whtShadow],
      [_INTL("#{name}"),          xpos + 323, ypos + 148, 2, blkBase, blkShadow],
      [_INTL("Title Conferred:"), xpos + 323, ypos + 190, 2, whtBase, whtShadow],
      [_INTL("#{title}"),         xpos + 323, ypos + 222, 2, blkBase, blkShadow],
      [_INTL("View mementos:"),   xpos + 370, ypos + 268, 1, whtBase, whtShadow],
	  [_INTL("Use"),  			  xpos + 440, ypos + 268, 1, blkBase, blkShadow]
    ]
    if memento_data
      typeX = (memento_data.is_ribbon?) ? 391 : 406
      textpos.push([_INTL("#{type}"), xpos + typeX, ypos + 12, 0, blkBase, blkShadow])
      textpos.push([_INTL("#{rank}"), xpos + 418, ypos + 76, 1, blkBase, blkShadow]) if rank > 4
    else
      textpos.push([_INTL("#{type}"), xpos + 410, ypos + 12, 2, blkBase, blkShadow])
    end
    pbDrawTextPositions(overlay, textpos)
  end

  def drawSelectedRibbon(ribbonid)
    # Draw all of page five
    drawPage(5)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(64, 64, 64)
    shadow = Color.new(176, 176, 176)
    nameBase   = Color.new(248, 248, 248)
    nameShadow = Color.new(104, 104, 104)
    # Get data for selected ribbon
    name = ribbonid ? GameData::Ribbon.get(ribbonid).name : ""
    desc = ribbonid ? GameData::Ribbon.get(ribbonid).description : ""
    # Draw the description box
    imagepos = [
      ["Graphics/UI/Summary/overlay_ribbon", 8, 280]
    ]
    pbDrawImagePositions(overlay, imagepos)
    # Draw name of selected ribbon
    textpos = [
      [name, 18, 292, 0, nameBase, nameShadow]
    ]
    pbDrawTextPositions(overlay, textpos)
    # Draw selected ribbon's description
    drawTextEx(overlay, 18, 324, 480, 2, desc, base, shadow)
  end

  def pbGoToPrevious
    newindex = @partyindex
    while newindex > 0
      newindex -= 1
      if @party[newindex] && (@page == 1 || !@party[newindex].egg?)
    	@partyindex = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @partyindex
    while newindex < @party.length - 1
      newindex += 1
      if @party[newindex] && (@page == 1 || !@party[newindex].egg?)
    	@partyindex = newindex
        break
      end
    end
  end

  def pbChangePokemon
	@pokemon = @party[@partyindex]
	@sprites["pokemon"].setPokemonBitmap(@pokemon)
	@sprites["pokemonglow1"].setPokemonBitmap(@pokemon)
	@sprites["pokemonglow2"].setPokemonBitmap(@pokemon)
	@sprites["pokemonglow3"].setPokemonBitmap(@pokemon)
	@sprites["pokemonglow4"].setPokemonBitmap(@pokemon)
	@sprites["itemicon"].item = @pokemon.item_id
    pbSEStop
	@pokemon.play_cry
  end


  def pbMoveSelection
	@sprites["movesel"].visible = true
	@sprites["movesel"].index   = 0
    selmove    = 0
    oldselmove = 0
    switching = false
    drawSelectedMove(nil, @pokemon.moves[selmove])
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["movepresel"].index == @sprites["movesel"].index
    	@sprites["movepresel"].z = @sprites["movesel"].z + 1
      else
    	@sprites["movepresel"].z = @sprites["movesel"].z
      end
      if Input.trigger?(Input::BACK)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
    	@sprites["movepresel"].visible = false
        switching = false
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        if selmove == Pokemon::MAX_MOVES
          break if !switching
      	@sprites["movepresel"].visible = false
          switching = false
        elsif !@pokemon.shadowPokemon?
          if switching
            tmpmove                    = @pokemon.moves[oldselmove]
        	@pokemon.moves[oldselmove] = @pokemon.moves[selmove]
        	@pokemon.moves[selmove]    = tmpmove
        	@sprites["movepresel"].visible = false
            switching = false
            drawSelectedMove(nil, @pokemon.moves[selmove])
          else
        	@sprites["movepresel"].index   = selmove
        	@sprites["movepresel"].visible = true
            oldselmove = selmove
            switching = true
          end
        end
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = @pokemon.numMoves - 1
        end
        selmove = 0 if selmove >= Pokemon::MAX_MOVES
        selmove = @pokemon.numMoves - 1 if selmove < 0
    	@sprites["movesel"].index = selmove
        pbPlayCursorSE
        drawSelectedMove(nil, @pokemon.moves[selmove])
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
        selmove = 0 if selmove >= Pokemon::MAX_MOVES
        selmove = Pokemon::MAX_MOVES if selmove < 0
    	@sprites["movesel"].index = selmove
        pbPlayCursorSE
        drawSelectedMove(nil, @pokemon.moves[selmove])
      end
    end
	@sprites["movesel"].visible = false
  end

  def pbRibbonSelection
	@sprites["ribbonsel"].visible = true
	@sprites["ribbonsel"].index   = 0
    selribbon    = @ribbonOffset * 4
    oldselribbon = selribbon
    switching = false
    numRibbons = @pokemon.ribbons.length
    numRows    = [((numRibbons + 3) / 4).floor, 3].max
    drawSelectedRibbon(@pokemon.ribbons[selribbon])
    loop do
  	@sprites["uparrow"].visible   = (@ribbonOffset > 0)
  	@sprites["downarrow"].visible = (@ribbonOffset < numRows - 3)
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["ribbonpresel"].index == @sprites["ribbonsel"].index
    	@sprites["ribbonpresel"].z = @sprites["ribbonsel"].z + 1
      else
    	@sprites["ribbonpresel"].z = @sprites["ribbonsel"].z
      end
      hasMovedCursor = false
      if Input.trigger?(Input::BACK)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
    	@sprites["ribbonpresel"].visible = false
        switching = false
      elsif Input.trigger?(Input::USE)
        if switching
          pbPlayDecisionSE
          tmpribbon                      = @pokemon.ribbons[oldselribbon]
      	@pokemon.ribbons[oldselribbon] = @pokemon.ribbons[selribbon]
      	@pokemon.ribbons[selribbon]    = tmpribbon
          if @pokemon.ribbons[oldselribbon] || @pokemon.ribbons[selribbon]
        	@pokemon.ribbons.compact!
            if selribbon >= numRibbons
              selribbon = numRibbons - 1
              hasMovedCursor = true
            end
          end
      	@sprites["ribbonpresel"].visible = false
          switching = false
          drawSelectedRibbon(@pokemon.ribbons[selribbon])
        else
          if @pokemon.ribbons[selribbon]
            pbPlayDecisionSE
        	@sprites["ribbonpresel"].index = selribbon - (@ribbonOffset * 4)
            oldselribbon = selribbon
        	@sprites["ribbonpresel"].visible = true
            switching = true
          end
        end
      elsif Input.trigger?(Input::UP)
        selribbon -= 4
        selribbon += numRows * 4 if selribbon < 0
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        selribbon += 4
        selribbon -= numRows * 4 if selribbon >= numRows * 4
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        selribbon -= 1
        selribbon += 4 if selribbon % 4 == 3
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::RIGHT)
        selribbon += 1
        selribbon -= 4 if selribbon % 4 == 0
        hasMovedCursor = true
        pbPlayCursorSE
      end
      next if !hasMovedCursor
  	@ribbonOffset = (selribbon / 4).floor if selribbon < @ribbonOffset * 4
  	@ribbonOffset = (selribbon / 4).floor - 2 if selribbon >= (@ribbonOffset + 3) * 4
  	@ribbonOffset = 0 if @ribbonOffset < 0
  	@ribbonOffset = numRows - 3 if @ribbonOffset > numRows - 3
  	@sprites["ribbonsel"].index    = selribbon - (@ribbonOffset * 4)
  	@sprites["ribbonpresel"].index = oldselribbon - (@ribbonOffset * 4)
      drawSelectedRibbon(@pokemon.ribbons[selribbon])
    end
	@sprites["ribbonsel"].visible = false
  end

  def pbMarking(pokemon)
	@sprites["markingbg"].visible      = true
	@sprites["markingoverlay"].visible = true
	@sprites["markingsel"].visible     = true
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    ret = pokemon.markings.clone
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
      	@sprites["markingoverlay"].bitmap.blt(300 + (58 * (i % 3)), 154 + (50 * (i / 3)),
                                            	@markingbitmap.bitmap, markrect)
        end
        textpos = [
          [_INTL("Mark {1}", pokemon.name), 366, 102, 2, base, shadow],
          [_INTL("OK"), 366, 254, 2, base, shadow],
          [_INTL("Cancel"), 366, 304, 2, base, shadow]
        ]
        pbDrawTextPositions(@sprites["markingoverlay"].bitmap, textpos)
        redraw = false
      end
      # Reposition the cursor
  	@sprites["markingsel"].x = 284 + (58 * (index % 3))
  	@sprites["markingsel"].y = 144 + (50 * (index / 3))
      case index
      when 6   # OK
    	@sprites["markingsel"].x = 284
    	@sprites["markingsel"].y = 244
    	@sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height / 2
      when 7   # Cancel
    	@sprites["markingsel"].x = 284
    	@sprites["markingsel"].y = 294
    	@sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height / 2
      else
    	@sprites["markingsel"].src_rect.y = 0
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        case index
        when 6   # OK
          ret = markings
          break
        when 7   # Cancel
          break
        else
          markings[index] = ((markings[index] || 0) + 1) % mark_variants
          redraw = true
        end
      elsif Input.trigger?(Input::ACTION)
        if index < 6 && markings[index] > 0
          pbPlayDecisionSE
          markings[index] = 0
          redraw = true
        end
      elsif Input.trigger?(Input::UP)
        if index == 7
          index = 6
        elsif index == 6
          index = 4
        elsif index < 3
          index = 7
        else
          index -= 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        if index == 7
          index = 1
        elsif index == 6
          index = 7
        elsif index >= 3
          index = 6
        else
          index += 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        if index < 6
          index -= 1
          index += 3 if index % 3 == 2
          pbPlayCursorSE
        end
      elsif Input.trigger?(Input::RIGHT)
        if index < 6
          index += 1
          index -= 3 if index % 3 == 0
          pbPlayCursorSE
        end
      end
    end
	@sprites["markingbg"].visible      = false
	@sprites["markingoverlay"].visible = false
	@sprites["markingsel"].visible     = false
    if pokemon.markings != ret
      pokemon.markings = ret
      return true
    end
    return false
  end

  def pbOptions
    dorefresh = false
    commands = []
    cmdGiveItem = -1
    cmdTakeItem = -1
    cmdPokedex  = -1
    cmdMark     = -1
    if !@pokemon.egg?
      commands[cmdGiveItem = commands.length] = _INTL("Give item")
      commands[cmdTakeItem = commands.length] = _INTL("Take item") if @pokemon.hasItem?
      commands[cmdPokedex = commands.length]  = _INTL("View Pokédex") if $player.has_pokedex
    end
    commands[cmdMark = commands.length]       = _INTL("Mark")
    commands[commands.length]                 = _INTL("Cancel")
    command = pbShowCommands(commands)
    if cmdGiveItem >= 0 && command == cmdGiveItem
      item = nil
      pbFadeOutIn {
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene, $bag)
        item = screen.pbChooseItemScreen(proc { |itm| GameData::Item.get(itm).can_hold? })
      }
      if item
        dorefresh = pbGiveItemToPokemon(item, @pokemon, self, @partyindex)
      end
    elsif cmdTakeItem >= 0 && command == cmdTakeItem
      dorefresh = pbTakeItemFromPokemon(@pokemon, self)
    elsif cmdPokedex >= 0 && command == cmdPokedex
      $player.pokedex.register_last_seen(@pokemon)
      pbFadeOutIn {
        scene = PokemonPokedexInfo_Scene.new
        screen = PokemonPokedexInfoScreen.new(scene)
        screen.pbStartSceneSingle(@pokemon.species)
      }
      dorefresh = true
    elsif cmdMark >= 0 && command == cmdMark
      dorefresh = pbMarking(@pokemon)
    end
    return dorefresh
  end

  def pbChooseMoveToForget(move_to_learn)
    new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
    selmove = 0
    maxmove = (new_move) ? Pokemon::MAX_MOVES : Pokemon::MAX_MOVES - 1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        selmove = Pokemon::MAX_MOVES
        pbPlayCloseMenuSE if new_move
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        selmove = maxmove if selmove < 0
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = @pokemon.numMoves - 1
        end
    	@sprites["movesel"].index = selmove
        selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
        drawSelectedMove(new_move, selected_move)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove > maxmove
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = (new_move) ? maxmove : 0
        end
    	@sprites["movesel"].index = selmove
        selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
        drawSelectedMove(new_move, selected_move)
      end
    end
    return (selmove == Pokemon::MAX_MOVES) ? -1 : selmove
  end

  def pbshowAbilityDescription
	pokemon = @pokemon
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/UI/Summary/bg_ability")
    imagepos = []
    ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
    imagepos.push([ballimage, 186, 40])
    pbDrawImagePositions(overlay, imagepos)
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    pbSetSystemFont(overlay)
    abilityname = pokemon.ability.name
    abilitydesc = pokemon.ability.description
	combined_abilitynamedesc = "#{abilityname}:\n\n#{abilitydesc}"
    pokename = @pokemon.name
    # texts
    textpos = [
       [_INTL("ABILITY"), 26, 22, 0, base, shadow],
       [pokename, 296, 48, 2, base, shadow],
       [_INTL("Item"), 278, 324, 0, base, shadow]
      ] 
    # Write the held item's name
    if @pokemon.hasItem?
      textpos.push([@pokemon.item.name, 214, 358, 0, Color.new(248, 248, 248), Color.new(104, 104, 104)])
    else
      textpos.push([_INTL("None"), 208, 358, 0, Color.new(248, 248, 248), Color.new(104, 104, 104)])
    end
    # Write the gender symbol
    if @pokemon.male?
      textpos.push([_INTL("♂"), 370, 48, 0, Color.new(103, 159, 224), Color.new(16, 79, 150)])
    elsif @pokemon.female?
      textpos.push([_INTL("♀"), 370, 48, 0, Color.new(255, 124, 109), Color.new(168, 53, 40)])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw the Pokémon's markings
    drawMarkings(overlay, 276, 292)
	drawTextEx(overlay, 410, 54, 250, 10 , combined_abilitynamedesc, base, shadow)  
    # drawTextEx(overlay, 410, 118, 250, 10 , abilitydesc, base, shadow)  
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK) || Input.trigger?(Input::SPECIAL)
        Input.update
        if PluginManager.installed?("Modular UI Scenes")
          drawPage(1) 
        else
          drawPage(1)
        end
        break
      end
    end
  end

  def pbScene
	@pokemon.play_cry
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::ACTION)
        pbSEStop
    	@pokemon.play_cry
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        if @page == 5
          pbPlayDecisionSE
          pbMoveSelection
          dorefresh = true
        elsif @page == 6
          pbPlayDecisionSE
          pbRibbonSelection
          dorefresh = true
        elsif !@inbattle
          pbPlayDecisionSE
          dorefresh = pbOptions
        end
	  elsif Input.trigger?(Input::SPECIAL)
	    if @page == 1 || @page == 3 || @page == 4 || @page == 5
          pbPlayDecisionSE
          pbshowAbilityDescription
          dorefresh = true
		end
      elsif Input.trigger?(Input::UP) && @partyindex > 0
        oldindex = @partyindex
        pbGoToPrevious
        if @partyindex != oldindex
          pbChangePokemon
      	@ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::DOWN) && @partyindex < @party.length - 1
        oldindex = @partyindex
        pbGoToNext
        if @partyindex != oldindex
          pbChangePokemon
      	@ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::LEFT) && !@pokemon.egg?
        oldpage = @page
    	@page -= 1
    	@page = 1 if @page < 1
    	@page = 6 if @page > 6
        if @page != oldpage   # Move to next page
          pbSEPlay("GUI summary change page")
      	@ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::RIGHT) && !@pokemon.egg?
        oldpage = @page
    	@page += 1
    	@page = 1 if @page < 1
    	@page = 6 if @page > 6
        if @page != oldpage   # Move to next page
          pbSEPlay("GUI summary change page")
      	@ribbonOffset = 0
          dorefresh = true
        end
      end
      if dorefresh
        drawPage(@page)
      end
    end
    return @partyindex
  end
end

#===============================================================================
#
#===============================================================================
class PokemonSummaryScreen
  def initialize(scene, inbattle = false)
	@scene = scene
	@inbattle = inbattle
  end

  def pbStartScreen(party, partyindex)
	@scene.pbStartScene(party, partyindex, @inbattle)
    ret = @scene.pbScene
	@scene.pbEndScene
    return ret
  end

  def pbStartForgetScreen(party, partyindex, move_to_learn)
    ret = -1
	@scene.pbStartForgetScene(party, partyindex, move_to_learn)
    loop do
      ret = @scene.pbChooseMoveToForget(move_to_learn)
      break if ret < 0 || !move_to_learn
      break if $DEBUG || !party[partyindex].moves[ret].hidden_move?
      pbMessage(_INTL("HM moves can't be forgotten now.")) { @scene.pbUpdate }
    end
	@scene.pbEndScene
    return ret
  end

  def pbStartChooseMoveScreen(party, partyindex, message)
    ret = -1
	@scene.pbStartForgetScene(party, partyindex, nil)
    pbMessage(message) { @scene.pbUpdate }
    loop do
      ret = @scene.pbChooseMoveToForget(nil)
      break if ret >= 0
      pbMessage(_INTL("You must choose a move!")) { @scene.pbUpdate }
    end
	@scene.pbEndScene
    return ret
  end
end

#===============================================================================
#
#===============================================================================
def pbChooseMove(pokemon, variableNumber, nameVarNumber)
  return if !pokemon
  ret = -1
  pbFadeOutIn {
    scene = PokemonSummary_Scene.new
    screen = PokemonSummaryScreen.new(scene)
    ret = screen.pbStartForgetScreen([pokemon], 0, nil)
  }
  $game_variables[variableNumber] = ret
  if ret >= 0
    $game_variables[nameVarNumber] = pokemon.moves[ret].name
  else
    $game_variables[nameVarNumber] = ""
  end
  $game_map.need_refresh = true if $game_map
end
