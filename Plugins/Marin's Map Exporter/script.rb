#==============================================================================#
#                              Map Exporter                                    #
#                                by Marin                                      #
#==============================================================================#
# Manually export a map using `pbExportMap(id)`, or go into the Debug menu and #
#            choose the `Export a Map` option that is now in there.            #
#                                                                              #
#  `pbExportMap(id, options)`, where `options` is an array that can contain:   #
#       - :events  ->  This will also export all events present on the map     #
#       - :player  ->  This will also export the player if they're on that map #
#  `id` can be nil, which case it will use the current map the player is on.   #
#==============================================================================#
#                    Please give credit when using this.                       #
#==============================================================================#

# This is where the map will be exported to once it has been created.
# If this file already exists, it is overwritten.
EXPORTED_FILENAME = "exported.png"



def pbExportMap(id = nil, options = [])
  MarinMapExporter.new(id, options)
end

def pbExportAMap
  vp = Viewport.new(0, 0, Graphics.width, Graphics.height)
  vp.z = 99999
  s = Sprite.new(vp)
  s.bitmap = Bitmap.new(Graphics.width, Graphics.height)
  s.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0,0,0))
  mapid = pbListScreen(_INTL("Export Map"),MapLister.new(pbDefaultMap))
  if mapid > 0
    player = $game_map.map_id == mapid
	if player
	  cmds = ["Export", "[  ] Events", "[  ] Player", "[  ] Fog", "Cancel"]
	else
	  cmds = ["Export", "[  ] Events", "[  ] Fog", "Cancel"]
	end
    cmd = 0
    loop do
      cmd = pbShowCommands(nil,cmds,-1,cmd)
      if cmd == 0
        Graphics.update
        options = []
		options << :events if cmds[1].split("")[1] == "X"
		options << :player if player && cmds[2].split("")[1] == "X"
		options << :fog if cmds[player ? 3 : 2].split("")[1] == "X"
        msgwindow = Window_AdvancedTextPokemon.newWithSize(
            _INTL("Saving... Please be patient."),
            0, Graphics.height - 96, Graphics.width, 96, vp
        )
        msgwindow.setSkin(MessageConfig.pbGetSpeechFrame)
        Graphics.update
        pbExportMap(mapid, options)
        msgwindow.setText(_INTL("Successfully exported the map."))
        60.times { Graphics.update; Input.update }
        pbDisposeMessageWindow(msgwindow)
        break
      elsif cmd == 1
        if cmds[1].split("")[1] == " "
          cmds[1] = "[X] Events"
        else
          cmds[1] = "[  ] Events"
        end
      elsif cmd == 2 && player
        if cmds[2].split("")[1] == " "
          cmds[2] = "[X] Player"
        else
          cmds[2] = "[  ] Player"
        end
	  elsif cmd == (player ? 3 : 2)
	    fog_index = player ? 3 : 2
	    if cmds[fog_index].split("")[1] == " "
		  cmds[fog_index] = "[X] Fog"
	    else
		  cmds[fog_index] = "[  ] Fog"
	    end
      elsif cmd == (player ? 4 : 3) || cmd == -1
        break
      end
    end
  end
  s.bitmap.dispose
  s.dispose
  vp.dispose
end

MenuHandlers.add(:debug_menu, :exportmap, {
  "name"        => "Export a Map",
  "parent"      => :field_menu,
  "description" => "Choose a map to export it as a PNG.",
  "effect"      => proc { |sprites, viewport| pbExportAMap }
})

class MarinMapExporter
  def initialize(id = nil, options = [])
    @id = id || $game_map.map_id
    @options = options
    @data = load_data("Data/Map#{@id.to_digits}.rxdata")
    @tiles = @data.data
    @result = Bitmap.new(32 * @tiles.xsize, 32 * @tiles.ysize)
    @tilesetdata = load_data("Data/Tilesets.rxdata")
    @tileset_info = @tilesetdata[@data.tileset_id]
    tilesetname = @tileset_info.tileset_name
    @tileset = Bitmap.new("Graphics/Tilesets/#{tilesetname}")
    @autotiles = @tileset_info.autotile_names
        .filter { |e| e && e.size > 0 }
        .map { |e| Bitmap.new("Graphics/Autotiles/#{e}") }

    # Draw normal map tiles in editor layer order.
    # Do NOT let priority move lower/middle-layer map tiles above everything,
    # because RPG Maker still treats those as normal map layers.
    #
    # Only the top editor layer (z == 2) is delayed when it has tile priority.
    # This lets tree tops/roof edges on the top layer cover events, while a
    # priority tile placed on Layer 1 keeps rendering with Layer 1.
    draw_queue = []
    for z in 0..2
      for y in 0...@tiles.ysize
        for x in 0...@tiles.xsize
          tile_id = @tiles[x, y, z]
          next if tile_id == 0
          priority = tile_priority(tile_id)
          if z == 2 && priority > 0
            draw_queue << {
              :z     => tile_overlay_z(y, priority),
              :order => z,
              :kind  => :tile,
              :x     => x,
              :y     => y,
              :id    => tile_id
            }
          else
            draw_tile(@result, x * 32, y * 32, tile_id)
          end
        end
      end
    end

    # Tile graphic events are included even when :events is off.
    # Normal character/sprite events still require :events.
    event_items = collect_event_draw_items(@options.include?(:events))
    draw_queue.concat(event_items)

    if @options.include?(:player) && $game_map.map_id == @id && $game_player.character_name &&
       $game_player.character_name.size > 0
      bmp = Bitmap.new("Graphics/Characters/#{$game_player.character_name}")
      dir = $game_player.direction
      frame_width = bmp.width / 4
      frame_height = bmp.height / 4
      draw_queue << {
        :z     => character_z($game_player.y, frame_height, false),
        :order => 50,
        :kind  => :character,
        :bmp   => bmp,
        :x     => $game_player.x * 32 + 16 - bmp.width / 8,
        :y     => ($game_player.y + 1) * 32 - frame_height,
        :rect  => Rect.new(0, frame_height * (dir / 2 - 1), frame_width, frame_height)
      }
    end

    draw_queue.sort_by! { |item| [item[:z], item[:order]] }
    draw_queue.each { |item| draw_queued_item(item) }

    if @options.include?(:fog)
      fog_settings = get_fog_settings

      if fog_settings
        fog_name, fog_hue, fog_opacity, fog_blend_type, fog_zoom = fog_settings

        if fog_name && fog_name.size > 0
          fog = Bitmap.new("Graphics/Fogs/#{fog_name}")
          fog.hue_change(fog_hue) if fog_hue && fog_hue != 0

          opacity = fog_opacity || 64
          zoom = (fog_zoom || 100) / 100.0

          fog_w = [(fog.width * zoom).to_i, 1].max
          fog_h = [(fog.height * zoom).to_i, 1].max

          temp = Bitmap.new(fog_w, fog_h)
          temp.stretch_blt(
            Rect.new(0, 0, fog_w, fog_h),
            fog,
            Rect.new(0, 0, fog.width, fog.height)
          )

          y = 0
          while y < @result.height
            x = 0
            while x < @result.width
              @result.blt(x, y, temp, Rect.new(0, 0, fog_w, fog_h), opacity)
              x += fog_w
            end
            y += fog_h
          end

          temp.dispose
          fog.dispose
        end
      end
    end
    @result.save_to_png(EXPORTED_FILENAME)
    Input.update
  end

  def tile_priority(tile_id)
    return 0 if !@tileset_info || !@tileset_info.priorities
    return @tileset_info.priorities[tile_id] || 0
  end

  def tile_overlay_z(tile_y, priority)
    return (tile_y * 32) + (priority * 32) + 33
  end

  def draw_tile(bitmap, x, y, tile_id)
    if tile_id < 384
      build_autotile(bitmap, x, y, tile_id)
    else
      bitmap.blt(
        x,
        y,
        @tileset,
        Rect.new(32 * ((tile_id - 384) % 8), 32 * ((tile_id - 384) / 8).floor, 32, 32)
      )
    end
  end

  def draw_queued_item(item)
    case item[:kind]
    when :tile
      draw_tile(@result, item[:x] * 32, item[:y] * 32, item[:id])
    when :event_tile
      draw_tile(@result, item[:x] * 32, item[:y] * 32, item[:id])
    when :character
      @result.blt(item[:x], item[:y], item[:bmp], item[:rect])
    end
  end

  def collect_event_draw_items(include_character_events)
    ret = []
    @data.events.keys.sort.each do |id|
      event = @data.events[id]
      page = pbGetActiveEventPage(event, @id)
      next unless page && page.graphic
      graphic = page.graphic

      # Tile graphic event, useful for "4th layer" patchups.
      # These always export, even if :events was not selected.
      if graphic.tile_id && graphic.tile_id > 0
        tile_id = graphic.tile_id
        ret << {
          :z     => event_tile_z(event.y, tile_id, page.always_on_top),
          :order => 40,
          :kind  => :event_tile,
          :x     => event.x,
          :y     => event.y,
          :id    => tile_id
        }
        next
      end

      next unless include_character_events
      next unless graphic.character_name && graphic.character_name.size > 0

      bmp = Bitmap.new("Graphics/Characters/#{graphic.character_name}")
      bmp = bmp.clone
      bmp.hue_change(graphic.character_hue) unless graphic.character_hue == 0

      frame_width = bmp.width / 4
      frame_height = bmp.height / 4
      ex = frame_width * graphic.pattern
      ey = frame_height * (graphic.direction / 2 - 1)

      ret << {
        :z     => character_z(event.y, frame_height, page.always_on_top),
        :order => 50,
        :kind  => :character,
        :bmp   => bmp,
        :x     => event.x * 32 + 16 - bmp.width / 8,
        :y     => (event.y + 1) * 32 - frame_height,
        :rect  => Rect.new(ex, ey, frame_width, frame_height)
      }
    end
    return ret
  end

  def character_z(tile_y, frame_height, always_on_top = false)
    return 999 if always_on_top
    z = (tile_y + 1) * 32
    return z + ((frame_height > 32) ? 31 : 0)
  end

  def event_tile_z(tile_y, tile_id, always_on_top = false)
    return 999 if always_on_top
    return ((tile_y + 1) * 32) + (tile_priority(tile_id) * 32)
  end

  def get_fog_settings
    # If exporting the current map, read the active fog from $game_map
    if $game_map && $game_map.map_id == @id && $game_map.respond_to?(:fog_name)
      return [
        $game_map.fog_name,
        $game_map.fog_hue,
        $game_map.fog_opacity,
        $game_map.fog_blend_type,
        $game_map.fog_zoom
      ]
    end

    # Otherwise, try to find a "Change Map Settings: Fog" event command
    @data.events.each_value do |event|
      page = pbGetActiveEventPage(event, @id)
      next unless page

      page.list.each do |command|
        next unless command.code == 204   # Change Map Settings
        next unless command.parameters[0] == 1   # Fog

        return [
          command.parameters[1], # fog name
          command.parameters[2], # hue
          command.parameters[3], # opacity
          command.parameters[4], # blend type
          command.parameters[5]  # zoom
        ]
      end
    end

    return nil
  end

  def build_autotile(bitmap, x, y, id)
    autotile = @autotiles[id / 48 - 1]
    return unless autotile
    if autotile.height == 32
      bitmap.blt(x,y,autotile,Rect.new(0,0,32,32))
    else
      id %= 48
      tiles = TileDrawingHelper::AUTOTILE_PATTERNS[id >> 3][id & 7]
      src = Rect.new(0,0,0,0)
      halfTileWidth = halfTileHeight = halfTileSrcWidth = halfTileSrcHeight = 32 >> 1
      for i in 0...4
        tile_position = tiles[i] - 1
        src.set((tile_position % 6) * halfTileSrcWidth,
           (tile_position / 6) * halfTileSrcHeight, halfTileSrcWidth, halfTileSrcHeight)
        bitmap.blt(i % 2 * halfTileWidth + x, i / 2 * halfTileHeight + y,
            autotile, src)
      end
    end
  end
end