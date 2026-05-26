class AdvancedNewGame_SaveSlotScreen

  def trainer_name_colors(gender)
    case gender
    when 0
      return [Color.new(56, 160, 248), Color.new(56, 104, 168)]
    when 1
      return [Color.new(240, 72, 88), Color.new(160, 64, 64)]
    else
      return [Color.new(75, 221, 75), Color.new(10, 138, 10)]
    end
  end
  
  CARD_W = 420
  CARD_H = 260
  CARD_Y = 70
  GAP    = 48

  BASE   = Color.new(248, 248, 248)
  SHADOW = Color.new(72, 80, 88)
  FADED  = Color.new(160, 160, 160)

  def initialize(mode)
    @mode = mode
    @index = 1
  end

  def pbStartScreen
    pbStartScene
    ret = pbMain
    pbEndScene
    return ret
  end

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    addBackgroundOrColoredPlane(@sprites, "bg", "optionsbg",
                                Color.new(192, 200, 208), @viewport)

    @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
      screen_title, 0, -16, Graphics.width, 64, @viewport
    )
    @sprites["title"].back_opacity = 0

    @sprites["cards"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @slot_party_icons = []
    6.times do |i|
      @slot_party_icons[i] = PokemonIconSprite.new(nil, @viewport)
      @slot_party_icons[i].visible = false
      @slot_party_icons[i].z = 99999
    end
    @sprites["player_sprite"] = TrainerWalkingCharSprite.new(nil, @viewport)
    @sprites["player_sprite"].visible = false
    @sprites["player_sprite"].z = 99999
    pbSetSystemFont(@sprites["cards"].bitmap)

    @sprites["help"] = Window_UnformattedTextPokemon.newWithSize(
      "", 0, Graphics.height - 64, Graphics.width, 64, @viewport
    )
    @sprites["help"].back_opacity = 0

    refresh
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def screen_title
    case @mode
    when :load
      return _INTL("Continue")
    when :new_game
      return _INTL("Choose New Game Slot")
    when :advanced_new_game
      return _INTL("Choose Advanced New Game Slot")
    end
    return _INTL("Choose Save Slot")
  end

  def pbMain
    loop do
      Graphics.update
      Input.update
      @sprites["player_sprite"]&.update
      @slot_party_icons.each { |s| s.update if s && !s.disposed? }

      if key_left?
        @index -= 1
        @index = AdvancedNewGame::MAX_SAVE_SLOTS if @index < 1
        pbPlayCursorSE
        refresh
      elsif key_right?
        @index += 1
        @index = 1 if @index > AdvancedNewGame::MAX_SAVE_SLOTS
        pbPlayCursorSE
        refresh
      elsif key_use?
        return choose_slot(@index)
      elsif key_special?
        open_slot_options(@index)
        refresh
      elsif key_back?
        pbPlayCloseMenuSE
        return nil
      end
    end
  end

  def choose_slot(slot)
    case @mode
    when :load
      if !AdvancedNewGame.save_slot_exists?(slot)
        pbPlayBuzzerSE
        return nil
      end
      AdvancedNewGame.current_save_slot = slot
      return slot

    when :new_game, :advanced_new_game
      if AdvancedNewGame.save_slot_exists?(slot)
        return nil if !pbConfirmMessage(_INTL("Overwrite Slot {1}?", slot))
        AdvancedNewGame.delete_save_slot(slot)
      end
      AdvancedNewGame.current_save_slot = slot
      return slot
    end

    return nil
  end

  def refresh
    bitmap = @sprites["cards"].bitmap
    bitmap.clear

    center_x = Graphics.width / 2 - CARD_W / 2

    AdvancedNewGame.slot_range.each do |slot|
      offset = slot - @index
      x = center_x + (offset * (CARD_W + GAP))
      next if x < -CARD_W
      next if x > Graphics.width

      draw_slot_card(bitmap, slot, x, CARD_Y, offset == 0)
    end
    refresh_slot_sprites

    @sprites["help"].text = _INTL("</> Change Slot   Confirm: Select   Back: Cancel")
  end

  def draw_slot_card(bitmap, slot, x, y, selected)
    meta = AdvancedNewGame.load_slot_metadata(slot)
    
    card = AnimatedBitmap.new("Graphics/UI/Save Slots/card")
    bitmap.blt(x, y, card.bitmap, Rect.new(0, 0, CARD_W, CARD_H))
    card.dispose

    text = []
    text.push([_INTL("Slot {1}", slot), x + 24, y + 10, :left, BASE, SHADOW])

    if meta && meta[:corrupted]
      text.push([_INTL("Corrupted Save"), x + 24, y + 88, :left, Color.new(248, 80, 80), SHADOW])
    elsif meta
      play_time = format_play_time(meta[:play_time])
      map_name = meta[:map_id] ? pbGetMapNameFromId(meta[:map_id]) : _INTL("Unknown")

      name_base, name_shadow = trainer_name_colors(meta[:gender])

      text.push([meta[:player_name],x + 24,y + 34,:left,name_base,name_shadow])
      text.push([_INTL("Badges: {1}", meta[:badges]), x + 24, y + 112, :left, BASE, SHADOW])
      text.push([_INTL("Time: {1}", play_time), x + 24, y + 146, :left, BASE, SHADOW])
      text.push([_INTL("Location: {1}", map_name), x + 24, y + 180, :left, BASE, SHADOW])
    else
      text.push([_INTL("Empty Slot"), x + 24, y + 108, :left, FADED, SHADOW])
    end

    pbDrawTextPositions(bitmap, text)
  end
  
  def refresh_slot_sprites
    meta = AdvancedNewGame.load_slot_metadata(@index)

    @slot_party_icons.each { |s| s.visible = false }
    @sprites["player_sprite"].visible = false

    return if !meta || meta[:corrupted]

    center_x = Graphics.width / 2 - CARD_W / 2
    x = center_x
    y = CARD_Y

    meta[:party].each_with_index do |pkmn, i|
      next if !pkmn
      sprite = @slot_party_icons[i]
      sprite.pokemon = pkmn
      sprite.x = x + 24 + (i * 56)
      sprite.y = y + 190
      sprite.visible = true
    end

    if meta[:character_ID]
      @sprites["player_sprite"]&.dispose

      player_meta = GameData::PlayerMetadata.get(meta[:character_ID])
      if player_meta
        filename = pbGetPlayerCharset(player_meta.walk_charset, nil, true)
        @sprites["player_sprite"] = TrainerWalkingCharSprite.new(filename, @viewport)

        charwidth  = @sprites["player_sprite"].bitmap.width
        charheight = @sprites["player_sprite"].bitmap.height

        @sprites["player_sprite"].x = x + 40 - (charwidth / 8)
        @sprites["player_sprite"].y = y + 78 - (charheight / 8)
        @sprites["player_sprite"].z = 99999
        @sprites["player_sprite"].visible = true
      end
    end
  end
  
  def open_slot_options(slot)
    commands = [
      _INTL("Copy Slot"),
      _INTL("Delete Slot"),
      _INTL("Cancel")
    ]

    cmdwindow = Window_CommandPokemon.new(commands)
    cmdwindow.viewport = @viewport
    cmdwindow.index = commands.length - 1
    cmdwindow.x = Graphics.width - cmdwindow.width - 16
    cmdwindow.y = Graphics.height - cmdwindow.height - 16

    choice = -1

    loop do
      Graphics.update
      Input.update
      cmdwindow.update

      if key_back?
        pbPlayCloseMenuSE
        choice = -1
        break
      elsif key_use?
        pbPlayDecisionSE
        choice = cmdwindow.index
        break
      end
    end

    cmdwindow.dispose
    return if choice < 0 || choice == 2

    case choice
    when 0
      copy_slot(slot)
    when 1
      delete_slot(slot)
    end
  end
  
  def copy_slot(source_slot)
    if !AdvancedNewGame.save_slot_exists?(source_slot)
      pbMessage(_INTL("Slot {1} is empty.", source_slot))
      return
    end

    source_meta = AdvancedNewGame.load_slot_metadata(source_slot)

    if AdvancedNewGame.save_slot_copy_locked?(source_meta)
      pbMessage(_INTL("Challenge Mode save files cannot be copied."))
      return
    end

    commands = []

    AdvancedNewGame.slot_range.each do |slot|
      next if slot == source_slot

      if AdvancedNewGame.save_slot_exists?(slot)
        commands.push(_INTL("Slot {1} - Used", slot))
      else
        commands.push(_INTL("Slot {1} - Empty", slot))
      end
    end

    commands.push(_INTL("Cancel"))

    choice = pbMessage(_INTL("Copy Slot {1} to where?", source_slot), commands, commands.length - 1)
    return if choice < 0 || choice == commands.length - 1

    target_slots = AdvancedNewGame.slot_range.to_a.reject { |s| s == source_slot }
    target_slot = target_slots[choice]

    if AdvancedNewGame.save_slot_exists?(target_slot)
      return if !pbConfirmMessage(_INTL("Overwrite Slot {1}?", target_slot))
    end

    source_path = AdvancedNewGame.save_slot_path(source_slot)
    target_path = AdvancedNewGame.save_slot_path(target_slot)

    File.open(source_path, "rb") do |source_file|
      File.open(target_path, "wb") do |target_file|
        target_file.write(source_file.read)
      end
    end

    pbMessage(_INTL("Slot {1} was copied to Slot {2}.", source_slot, target_slot))
  end
  
  def delete_slot(slot)
    if !AdvancedNewGame.save_slot_exists?(slot)
      pbMessage(_INTL("Slot {1} is already empty.", slot))
      return
    end

    return if !pbConfirmMessage(_INTL("Delete Slot {1}?", slot))
    return if !pbConfirmMessage(_INTL("This cannot be undone. Delete this save file?"))

    AdvancedNewGame.delete_save_slot(slot)
    pbMessage(_INTL("Slot {1} was deleted.", slot))
  end

  def format_play_time(seconds)
    seconds = seconds.to_i
    hours = seconds / 3600
    mins = (seconds / 60) % 60
    return _INTL("{1}h {2}m", hours, mins)
  end

  def key_left?
    return Keybinds.repeat?(:left) rescue Input.repeat?(Input::LEFT)
  end

  def key_right?
    return Keybinds.repeat?(:right) rescue Input.repeat?(Input::RIGHT)
  end

  def key_use?
    return Keybinds.trigger?(:use) rescue Input.trigger?(Input::USE)
  end

  def key_back?
    return Keybinds.trigger?(:back) rescue Input.trigger?(Input::BACK)
  end

  def key_special?
    return Keybinds.trigger?(:special) rescue Input.trigger?(Input::SPECIAL)
  end
end