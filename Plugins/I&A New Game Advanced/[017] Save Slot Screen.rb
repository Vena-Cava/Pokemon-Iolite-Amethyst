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
  SLIDE_TIME = 0.20
  CARD_STEP  = CARD_W + GAP

  BASE   = Color.new(248, 248, 248)
  SHADOW = Color.new(104, 104, 104)
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
  
  def animate_to_slot(old_index, new_index)
    center_x = Graphics.width / 2 - CARD_W / 2
    timer_start = System.uptime

    loop do
      Graphics.update
      Input.update
      pbUpdate

      bitmap = @sprites["cards"].bitmap
      bitmap.clear

      t = [(System.uptime - timer_start) / SLIDE_TIME, 1.0].min
      offset_lerp = lerp(old_index, new_index, SLIDE_TIME, timer_start, System.uptime)

      AdvancedNewGame.slot_range.each do |slot|
        offset = slot - offset_lerp
        x = center_x + (offset * CARD_STEP)
        next if x < -CARD_W
        next if x > Graphics.width

        draw_slot_card(bitmap, slot, x, CARD_Y, slot == new_index)
      end

      refresh_slot_sprites(offset_lerp)

      break if t >= 1.0
    end

    refresh
  end

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    @sprites["panorama"] = IconSprite.new(0, 0, @viewport)

    panorama_path = "Graphics/UI/Summary/bg_pan_am"
    if defined?(IASummary) && IASummary::IAVERSION == 2
      panorama_path = "Graphics/UI/Summary/bg_pan_io"
    end

    @sprites["panorama"].setBitmap(panorama_path)

    @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
      screen_title, 0, -16, Graphics.width, 64, @viewport
    )
    @sprites["title"].back_opacity = 0
    @sprites["title"].baseColor   = BASE
    @sprites["title"].shadowColor = SHADOW

    @sprites["cards"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @slot_sprite_cache = {}
    pbSetSystemFont(@sprites["cards"].bitmap)

    @sprites["help"] = BitmapSprite.new(Graphics.width, 64, @viewport)
    @sprites["help"].x = 0
    @sprites["help"].y = Graphics.height - 64
    @sprites["help"].z = 0
    @sprites["options_help"] = BitmapSprite.new(220, 40, @viewport)
    @sprites["options_help"].x = Graphics.width - 220
    @sprites["options_help"].y = 8
    @sprites["options_help"].z = 0
    pbSetSystemFont(@sprites["options_help"].bitmap)
    pbSetSystemFont(@sprites["help"].bitmap)
    
    @slot_metadata_cache = {}
    refresh_metadata_cache

    refresh
    pbFadeInAndShow(@sprites)
    8.times do
      each_slot_sprite { |s| s.opacity += 32 }
      Graphics.update
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    dispose_slot_sprites
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
  
  def each_slot_sprite
    return if !@slot_sprite_cache

    @slot_sprite_cache.each_value do |data|
      yield data[:player] if data[:player] && !data[:player].disposed?
      data[:party].each do |s|
        yield s if s && !s.disposed?
      end
    end
  end
  
  def refresh_metadata_cache
    @slot_metadata_cache ||= {}

    AdvancedNewGame.slot_range.each do |slot|
      @slot_metadata_cache[slot] = AdvancedNewGame.load_slot_metadata(slot)
    end
  end
  
  def slot_metadata(slot)
    @slot_metadata_cache ||= {}
    return @slot_metadata_cache[slot]
  end
  
  def draw_right_icon_row(bitmap, icons, right_x, y, icon_size = 24, gap = 4, max_per_row = 4)
    return 0 if !icons || icons.empty?
    return 0 if !right_x || !y

    row_count = 0

    icons.each_slice(max_per_row).with_index do |row_icons, row|
      row_count += 1

      row_width = (row_icons.length * icon_size) + ((row_icons.length - 1) * gap)
      x = right_x - row_width
      row_y = y + (row * (icon_size + gap))

      row_icons.each do |path|
        next if !pbResolveBitmap(path)

        icon = AnimatedBitmap.new(path)
        bitmap.blt(x, row_y, icon.bitmap, Rect.new(0, 0, icon_size, icon_size))
        icon.dispose

        x += icon_size + gap
      end
    end

    return row_count
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

      if key_left?
        old_index = @index
        @index -= 1
        @index = AdvancedNewGame::MAX_SAVE_SLOTS if @index < 1
        pbPlayCursorSE
        animate_to_slot(old_index, @index)
      elsif key_right?
        old_index = @index
        @index += 1
        @index = 1 if @index > AdvancedNewGame::MAX_SAVE_SLOTS
        pbPlayCursorSE
        animate_to_slot(old_index, @index)
      elsif key_use?
        result = choose_slot(@index)
        return result if result
        refresh
      elsif key_special?
        open_slot_options(@index)
        refresh
      elsif key_back?
        pbPlayCloseMenuSE
        return nil
      end
    pbUpdate
    end
  end
  
  def pbUpdate
    pbUpdateSpriteHash(@sprites)

    if @sprites["panorama"] && !@sprites["panorama"].disposed?
      @sprites["panorama"].x = 0 if @sprites["panorama"].x <= -56
      @sprites["panorama"].x -= 2 if defined?(IASummary) && IASummary::PANORAMA == true
    end
    
    update_slot_sprites
    
    current_device = Keybinds.last_device rescue nil
    if current_device != @last_input_device
      @last_input_device = current_device
      refresh_keybind_help
      refresh_options_help
    end
  end
  
  def choose_slot(slot)
    case @mode
    when :load
      if !AdvancedNewGame.save_slot_exists?(slot)
        pbPlayBuzzerSE
        return nil
      end

      meta = AdvancedNewGame.load_slot_metadata(slot)

      if meta &&
         (meta[:run_state] == :failed || meta[:run_state] == "failed") &&
         !AdvancedNewGame.can_open_failed_save?

        pbMessage(_INTL("This run has failed and cannot be continued."))
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

    refresh_keybind_help
    
    refresh_options_help
    @last_input_device = Keybinds.last_device rescue nil
  end
  
  def refresh_keybind_help
    x = 16
    y = 16
    
    return if !@sprites["help"]

    bitmap = @sprites["help"].bitmap
    bitmap.clear

    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)

    if Keybinds.gamepad?
      draw_gamepad_help(bitmap, base, shadow)
    else
      text = _INTL(
        "{1}/{2}: Change | {3}: Select | {4}: Back",
        Keybinds.button_name(:left),
        Keybinds.button_name(:right),
        Keybinds.button_name(:use),
        Keybinds.button_name(:back)
      )

      pbDrawTextPositions(bitmap, [[text, 16, y + 4, :left, base, shadow]])
    end
  end

  def draw_gamepad_help(bitmap, base, shadow)
    x = 16
    y = 16

    draw_dual_gamepad_help(bitmap, x, y, :left, :right, _INTL("Change"), base, shadow)
    x += 200

    sheet = RPG::Cache.load_bitmap("Graphics/UI/", "controller_buttons")

    [
      [:use,     _INTL("Select")],
      [:back,    _INTL("Back")]
    ].each do |action, label|
      button = Keybinds::GAMEPAD_BUTTONS[action]
      next if button.nil?

      src_rect = Rect.new(
        button * 32,
        $PokemonSystem.controller_layout * 32,
        32,
        32
      )

      bitmap.blt(x, y, sheet, src_rect)
      pbDrawTextPositions(bitmap, [[label, x + 36, y + 4, :left, base, shadow]])

      x += 120
    end
  end
  
  def draw_dual_gamepad_help(bitmap, x, y, action1, action2, label, base, shadow)
    sheet = RPG::Cache.load_bitmap("Graphics/UI/", "controller_buttons")

    button1 = Keybinds::GAMEPAD_BUTTONS[action1]
    button2 = Keybinds::GAMEPAD_BUTTONS[action2]

    row = $PokemonSystem.controller_layout * 32

    bitmap.blt(x, y, sheet, Rect.new(button1 * 32, row, 32, 32))

    pbDrawTextPositions(bitmap, [
      ["/", x + 38, y + 4, :left, base, shadow]
    ])

    bitmap.blt(x + 52, y, sheet, Rect.new(button2 * 32, row, 32, 32))

    pbDrawTextPositions(bitmap, [
      [label, x + 92, y + 4, :left, base, shadow]
    ])
  end
  
  def refresh_options_help
    return if !@sprites["options_help"]

    bitmap = @sprites["options_help"].bitmap
    bitmap.clear

    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)

    if Keybinds.gamepad?
      sheet = RPG::Cache.load_bitmap("Graphics/UI/", "controller_buttons")
      button = Keybinds::GAMEPAD_BUTTONS[:special]
      return if button.nil?

      src_rect = Rect.new(
        button * 32,
        $PokemonSystem.controller_layout * 32,
        32,
        32
      )

      options_text = _INTL("Options")

      text_width = bitmap.text_size(options_text).width

      text_x = 210
      text_y = 8

      text_left = text_x - text_width

      button_x = text_left - 36
      button_y = 0

      bitmap.blt(button_x, button_y, sheet, src_rect)

      pbDrawTextPositions(bitmap, [[
        options_text,
        text_x,
        text_y,
        :right,
        base,
        shadow
      ]])
    else
      text = _INTL("{1}: Options", Keybinds.button_name(:special))
      pbDrawTextPositions(bitmap, [[text, 210, 8, :right, base, shadow]])
    end
  end

  def keybind_name(action)
    if defined?(Keybinds)
      return Keybinds.button_name(action) rescue action.to_s
    end

    return action.to_s
  end

  def draw_slot_card(bitmap, slot, x, y, selected)
    meta = slot_metadata(slot)
    failed = meta && (meta[:run_state] == :failed || meta[:run_state] == "failed")
    
    card = AnimatedBitmap.new("Graphics/UI/Save Slots/card")
    bitmap.blt(x, y, card.bitmap, Rect.new(0, 0, CARD_W, CARD_H))
    card.dispose
    
    stars = save_slot_star_icons(meta)
    modes = save_slot_mode_icons(meta)

    right_x = x + CARD_W - 16
    top_y   = y + 16

    if stars.length > 0
      star_rows = draw_right_icon_row(bitmap, stars, right_x, top_y, 24, 4, 5)
      modes_y = top_y + (star_rows * (24 + 4)) + 4
      draw_right_icon_row(bitmap, modes, right_x, modes_y, 24, 4, 5) if modes.length > 0
    else
      draw_right_icon_row(bitmap, modes, right_x, top_y, 24, 4, 5) if modes.length > 0
    end

    text = []
    slot_title = meta && meta[:slot_name] ? meta[:slot_name] : AdvancedNewGame.save_slot_name(slot)
    text.push([slot_title, x + 24, y + 10, :left, BASE, SHADOW])

    if meta && meta[:corrupted]
      text.push([_INTL("Corrupted Save"), x + 24, y + 88, :left, Color.new(248, 80, 80), SHADOW])
    elsif meta
      play_time = format_play_time(meta[:play_time])
      map_name = meta[:map_id] ? pbGetMapNameFromId(meta[:map_id]) : _INTL("Unknown")

      name_base, name_shadow = trainer_name_colors(meta[:gender])

      text.push([meta[:player_name],x + 24,y + 34,:left,name_base,name_shadow])
      if failed
        banner = AnimatedBitmap.new("Graphics/UI/Save Slots/banner_failed")

        name_width = bitmap.text_size(meta[:player_name]).width
        banner_x = x + 24 + name_width + 8
        banner_y = y + 32

        bitmap.blt(
          banner_x,
          banner_y,
          banner.bitmap,
          Rect.new(0, 0, banner.width, banner.height)
        )

        banner.dispose
      end
      text.push([_INTL("Badges: {1}", meta[:badges]), x + 24, y + 112, :left, BASE, SHADOW])
      if meta[:advanced_new_game_settings] && meta[:advanced_new_game_settings][:nuzlocke]
        time_text = _INTL("Time: {1} | Retired PKMN: {2}",play_time,meta[:retired_count] || 0)
      else
        time_text = _INTL("Time: {1}", play_time)
      end
      text.push([time_text, x + 24, y + 146, :left, BASE, SHADOW])
      text.push([_INTL("Location: {1}", map_name), x + 24, y + 180, :left, BASE, SHADOW])
    else
      text.push([_INTL("Empty Slot"), x + 24, y + 108, :left, FADED, SHADOW])
    end

    pbDrawTextPositions(bitmap, text)
  end
  
  def save_slot_star_icons(meta)
    return [] if !meta
    count = meta[:stars].to_i
    return [] if count <= 0

    icons = []
    count.times do
      icons.push("Graphics/UI/Save Slots/icon_star")
    end
    return icons
  end

  def save_slot_mode_icons(meta)
    return [] if !meta || !meta[:advanced_new_game_settings]

    settings = meta[:advanced_new_game_settings]
    icons = []

    difficulty = settings[:difficulty]

    case difficulty
    when :easy, 0
      icons.push("Graphics/UI/Save Slots/icon_difficulty_easy")
    when :normal, 1
      icons.push("Graphics/UI/Save Slots/icon_difficulty_normal")
    when :hard, 2
      icons.push("Graphics/UI/Save Slots/icon_difficulty_hard")
    when :ultra_hard, 3
      icons.push("Graphics/UI/Save Slots/icon_difficulty_ultra_hard")
    end

    icons.push("Graphics/UI/Save Slots/icon_nuzlocke") if settings[:nuzlocke]
    icons.push("Graphics/UI/Save Slots/icon_inverse") if settings[:inverse]
    icons.push("Graphics/UI/Save Slots/icon_level_caps") if settings[:level_caps]
    icons.push("Graphics/UI/Save Slots/icon_no_bag") if settings[:no_bag_items_battle]

    if settings[:nuzlocke]
      options = settings[:nuzlocke_options] || {}

      icons.push("Graphics/UI/Save Slots/icon_dupes_clause") if options[:dupes_clause]
      icons.push("Graphics/UI/Save Slots/icon_shiny_clause") if options[:shiny_clause]
      icons.push("Graphics/UI/Save Slots/icon_nickname_clause") if options[:nickname_clause]
      icons.push("Graphics/UI/Save Slots/icon_hm_clause") if options[:hm_clause]
      icons.push("Graphics/UI/Save Slots/icon_wipe_deletes_save") if options[:wipe_deletes_save]

      case options[:pokecenter_limit]
      when :three, 3
        icons.push("Graphics/UI/Save Slots/icon_centre_3")
      when :one, 1
        icons.push("Graphics/UI/Save Slots/icon_centre_1")
      when :zero, 0
        icons.push("Graphics/UI/Save Slots/icon_centre_0")
      end
    end

    return icons
  end
  
  def refresh_slot_sprites(offset_lerp = @index)
    @slot_sprite_cache ||= {}

    @slot_sprite_cache.each_value do |data|
      data[:player]&.visible = false
      data[:party].each { |s| s.visible = false if s && !s.disposed? }
    end

    center_x = Graphics.width / 2 - CARD_W / 2

    AdvancedNewGame.slot_range.each do |slot|
      offset = slot - offset_lerp
      card_x = center_x + (offset * CARD_STEP)
      next if card_x < -CARD_W
      next if card_x > Graphics.width

      meta = slot_metadata(slot)
      next if !meta || meta[:corrupted]

      data = ensure_slot_sprites(slot, meta)

      meta[:party].each_with_index do |pkmn, i|
        next if !pkmn
        sprite = data[:party][i]
        sprite.x = card_x + 24 + (i * 56)
        sprite.y = CARD_Y + 190
        sprite.visible = true
      end

      if data[:player]
        charwidth  = data[:player].bitmap.width
        charheight = data[:player].bitmap.height

        if data[:failed]
          data[:player].x = card_x + 8
          data[:player].y = CARD_Y + 46
        else
          data[:player].x = card_x + 40 - (charwidth / 8)
          data[:player].y = CARD_Y + 78 - (charheight / 8)
        end
        data[:player].visible = true
      end
    end
  end
  
  def ensure_slot_sprites(slot, meta)
    return @slot_sprite_cache[slot] if @slot_sprite_cache[slot]

    data = {
      player: nil,
      party: [],
      failed: (meta[:run_state] == :failed || meta[:run_state] == "failed")
    }

    if meta[:character_ID]
      player_meta = GameData::PlayerMetadata.get(meta[:character_ID])
      if player_meta
        filename = pbGetPlayerCharset(player_meta.walk_charset, nil, true)

        if data[:failed]
          charset = AnimatedBitmap.new("Graphics/Characters/#{filename}")
          frame_w = charset.bitmap.width / 4
          frame_h = charset.bitmap.height / 4

          bmp = Bitmap.new(frame_w, frame_h)
          bmp.blt(
            0,
            0,
            charset.bitmap,
            Rect.new(0, 0, frame_w, frame_h)
          )

          bmp.advanced_new_game_grayscale!

          data[:player] = Sprite.new(@viewport)
          data[:player].bitmap = bmp

          charset.dispose
        else
          data[:player] = TrainerWalkingCharSprite.new(filename, @viewport)
        end

        data[:player].z = 0
        data[:player].visible = false
        @sprites["slot#{slot}_player"] = data[:player]
      end
    end

    6.times do |i|
      pkmn = meta[:party][i] rescue nil
      data[:party][i] = PokemonIconSprite.new(pkmn, @viewport)
      data[:party][i].visible = false
      data[:party][i].z = 0
      @sprites["slot#{slot}_party#{i}"] = data[:party][i]

      # Freeze icon animation
      # data[:party][i].instance_variable_set(:@animBitmap, nil)
      # data[:party][i].instance_variable_set(:@frame, 0)
      # data[:party][i].instance_variable_set(:@currentFrame, 0)
    end

    @slot_sprite_cache[slot] = data
    return data
  end

  def update_slot_sprites
    return if !@slot_sprite_cache

    @slot_sprite_cache.each_value do |data|
      if data[:player] && data[:player].visible
        data[:player]&.update if data[:player] && data[:player].visible && !data[:failed]
      end

      data[:party].each do |s|
        next if !s || s.disposed?
        next if !s.visible
        s.update
      end
    end
  end

  def dispose_slot_sprites
    return if !@slot_sprite_cache

    @slot_sprite_cache.each_value do |data|
      data[:player]&.dispose
      data[:party].each { |s| s.dispose if s && !s.disposed? }
    end

    @slot_sprite_cache.clear
  end
  
  # Marker :)
  
  def open_slot_options(slot)
    commands = [
      _INTL("Rename Slot"),
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
    return if choice < 0 || choice == 3

    case choice
    when 0
      rename_slot(slot)
    when 1
      copy_slot(slot)
    when 2
      delete_slot(slot)
    end
  end
  
  def rename_slot(slot)
    if !AdvancedNewGame.save_slot_exists?(slot)
      pbMessage(_INTL("Empty slots cannot be renamed."))
      return
    end
    current_name = AdvancedNewGame.save_slot_name(slot)

    new_name = pbEnterText(
      _INTL("Rename Slot {1}.", slot),
      1,
      16,
      current_name
    )

    return if !new_name || new_name.strip.empty?

    AdvancedNewGame.rename_save_slot(slot, new_name)
    refresh_metadata_cache
    refresh
    pbMessage(_INTL("Slot {1} was renamed.", slot))
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
    refresh_metadata_cache
    refresh
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
    refresh_metadata_cache
    refresh
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