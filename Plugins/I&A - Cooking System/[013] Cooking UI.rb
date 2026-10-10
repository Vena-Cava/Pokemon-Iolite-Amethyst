#===============================================================================
# I&A - Cooking System
# Cooking UI
#===============================================================================

module Cooking
  #=============================================================================
  # Creative Mode scene
  #=============================================================================
  class CreativeScene
    LIST_X       = 8
    LIST_Y       = 46
    LIST_WIDTH   = 300
    LIST_HEIGHT  = 218

    ROW_HEIGHT   = 30
    VISIBLE_ROWS = 6

    INFO_X       = 382
    INFO_Y       = 34
    INFO_WIDTH   = Graphics.width - INFO_X - 16
    INFO_CENTER  = INFO_X + (INFO_WIDTH / 2)

    TRAY_Y       = 318
    TRAY_SLOT_SIZE = 32
    TRAY_GAP       = 2

    TEXT_BASE    = Color.new(248, 248, 248)
    TEXT_SHADOW  = Color.new(72, 72, 72)
    DISABLED     = Color.new(144, 144, 144)

    attr_reader :selection

    #===========================================================================
    # Scene setup
    #===========================================================================

    def initialize
      @selection = Cooking::Selection.new(:CREATIVE)
      @items     = []
      @index     = 0
      @top_row   = 0
      @last_item = nil
    end

    def pbStartScene
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99999

      @sprites = {}

      #-------------------------------------------------------------------------
      # Temporary plain background.
      # Replace this later with the game's Cooking UI artwork.
      #-------------------------------------------------------------------------
      @sprites["background"] = BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )
      @sprites["background"].bitmap.fill_rect(
        0, 0, Graphics.width, Graphics.height,
        Color.new(48, 64, 80)
      )

      #-------------------------------------------------------------------------
      # Main overlay.
      #-------------------------------------------------------------------------
      @sprites["overlay"] = BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )
      pbSetSystemFont(@sprites["overlay"].bitmap)

      #-------------------------------------------------------------------------
      # Enlarged highlighted item icon.
      #-------------------------------------------------------------------------
      @sprites["itemicon"] = ItemIconSprite.new(
        INFO_CENTER,
        110,
        nil,
        @viewport
      )
      @sprites["itemicon"].setOffset(PictureOrigin::CENTER)
      @sprites["itemicon"].zoom_x = 2
      @sprites["itemicon"].zoom_y = 2

      rebuild_item_list
      refresh

      pbFadeInAndShow(@sprites)
    end

    def pbEndScene
      pbFadeOutAndHide(@sprites)
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end

    #===========================================================================
    # Main loop
    #===========================================================================

    def pbMain
      loop do
        Graphics.update
        Input.update
        pbUpdateSpriteHash(@sprites)

        #-----------------------------------------------------------------------
        # Confirmation stage has its own input.
        #-----------------------------------------------------------------------
        if @selection.confirming?
          if Keybinds.trigger?(:use)
            pbPlayDecisionSE
            return confirm_current_selection
          elsif Keybinds.trigger?(:back)
            pbPlayCancelSE
            @selection.back
            rebuild_item_list
            refresh
          end

          next
        end

        #-----------------------------------------------------------------------
        # Navigation.
        #-----------------------------------------------------------------------
        old_index = @index

        if Keybinds.repeat?(:up)
          move_vertical(-1)
        elsif Keybinds.repeat?(:down)
          move_vertical(1)
        end

        if @index != old_index
          pbPlayCursorSE
          ensure_cursor_visible
          refresh
        end

        #-----------------------------------------------------------------------
        # Select highlighted item.
        #-----------------------------------------------------------------------
        if Keybinds.trigger?(:use)
          item = current_item

          if item && @selection.add(item)
            pbPlayDecisionSE

            old_stage = @selection.stage
            rebuild_item_list

            # add() may have automatically advanced after item #6/#4.
            if @selection.confirming?
              refresh
              next
            end

            @index = [@index, @items.length - 1].min
            @index = 0 if @index < 0
            ensure_cursor_visible
            refresh
          else
            pbPlayBuzzerSE
          end

        #-----------------------------------------------------------------------
        # Back = undo.
        #-----------------------------------------------------------------------
        elsif Keybinds.trigger?(:back)
          result = @selection.back

          if result == :EXIT
            pbPlayCancelSE
            return :EXIT
          end

          pbPlayCancelSE
          rebuild_item_list
          refresh

        #-----------------------------------------------------------------------
        # Special = Next.
        #-----------------------------------------------------------------------
        elsif Keybinds.trigger?(:special)
          if @selection.special
            pbPlayDecisionSE
            rebuild_item_list
            refresh
          else
            pbPlayBuzzerSE
          end
        end
      end
    end

    #===========================================================================
    # Current list
    #===========================================================================

    def rebuild_item_list
      old_item = current_item

      @items = if @selection.choosing_ingredients?
                 @selection.available_ingredients
               elsif @selection.choosing_condiments?
                 @selection.available_condiments
               else
                 []
               end

      if old_item && @items.include?(old_item)
        @index = @items.index(old_item)
      else
        @index = [@index, @items.length - 1].min
        @index = 0 if @index < 0
      end

      ensure_cursor_visible
    end

    def current_item
      return nil if @items.empty?
      return @items[@index]
    end

    #===========================================================================
    # Single-column navigation
    #===========================================================================

    def row_count
      return @items.length
    end

    def current_row
      return @index
    end

    def move_vertical(direction)
      return if @items.length <= 1
      @index = (@index + direction) % @items.length
    end

    def ensure_cursor_visible
      row = current_row

      if row < @top_row
        @top_row = row
      elsif row >= @top_row + VISIBLE_ROWS
        @top_row = row - VISIBLE_ROWS + 1
      end

      max_top = [row_count - VISIBLE_ROWS, 0].max
      @top_row = [[@top_row, 0].max, max_top].min
    end

    #===========================================================================
    # Confirmation
    #===========================================================================

    def confirm_current_selection
      return false unless @selection.can_cook?

      # Determine the result only after the player has committed to cooking.
      recipe = @selection.matched_recipe

      # Debug builds show the raw Recipe Matcher result.
      # This is intentionally kept as a permanent development diagnostic and is
      # never shown to players in a normal game.
      if $DEBUG
        if recipe
          pbMessage(
            _INTL(
              "DEBUG: Recipe Matcher result:\n{1} [{2}]",
              recipe.name,
              recipe.id
            )
          )
        else
          pbMessage(
            _INTL("DEBUG: Recipe Matcher result:\nNo matching recipe.")
          )
        end
      end

      # The actual cooking/result sequence will be called here.
      # No items are consumed yet.

      refresh
      return false
    end

    #===========================================================================
    # Drawing
    #===========================================================================

    def refresh
      overlay = @sprites["overlay"].bitmap
      overlay.clear

      draw_header(overlay)

      if @selection.confirming?
        @sprites["itemicon"].visible = false
        draw_confirmation(overlay)
      else
        @sprites["itemicon"].visible = true
        draw_item_list(overlay)
        draw_item_information(overlay)
        draw_selection_tray(overlay)
      end

      draw_controls(overlay)
    end

    #---------------------------------------------------------------------------

    def draw_header(overlay)
      stage_name = case @selection.stage
                   when :INGREDIENTS then _INTL("Choose Ingredients")
                   when :CONDIMENTS  then _INTL("Choose Condiments")
                   when :CONFIRM     then _INTL("Confirm Meal")
                   else @selection.stage.to_s
                   end

      pbDrawTextPositions(
        overlay,
        [
          [
            _INTL("Creative Mode"),
            16, 8, :left,
            TEXT_BASE, TEXT_SHADOW
          ],
          [
            stage_name,
            Graphics.width - 16, 8, :right,
            TEXT_BASE, TEXT_SHADOW
          ]
        ]
      )
    end

    #---------------------------------------------------------------------------

    def draw_item_list(overlay)
      list_bitmap = AnimatedBitmap.new(
        "Graphics/UI/Cooking/ingredient_list"
      )

      overlay.blt(
        LIST_X,
        LIST_Y,
        list_bitmap.bitmap,
        Rect.new(
          0,
          0,
          300,
          218
        )
      )

      list_bitmap.dispose

      first_row = @top_row
      last_row  = [@top_row + VISIBLE_ROWS - 1, row_count - 1].min

      (first_row..last_row).each do |row|
        item_id = @items[row]
        next if !item_id

        item = GameData::Item.get(item_id)

        x = LIST_X + 8
        y = LIST_Y + 18 + ((row - @top_row) * ROW_HEIGHT)

        if row == @index
          overlay.fill_rect(
            LIST_X,
            y - 4,
            LIST_WIDTH,
            ROW_HEIGHT,
            Color.new(88, 112, 136)
          )
        end

        quantity = @selection.available_quantity(item_id)

        pbDrawTextPositions(
          overlay,
          [
            [
              item.name,
              x,
              y,
              :left,
              TEXT_BASE,
              TEXT_SHADOW
            ],
            [
              _INTL("x{1}", quantity),
              LIST_X + LIST_WIDTH - 12,
              y,
              :right,
              TEXT_BASE,
              TEXT_SHADOW
            ]
          ]
        )
      end

      if @top_row > 0
        pbDrawTextPositions(
          overlay,
          [[
            "▲",
            LIST_X + (LIST_WIDTH / 2),
            LIST_Y - 4,
            :center,
            TEXT_BASE,
            TEXT_SHADOW
          ]]
        )
      end

      if @top_row + VISIBLE_ROWS < row_count
        pbDrawTextPositions(
          overlay,
          [[
            "▼",
            LIST_X + (LIST_WIDTH / 2),
            LIST_Y + LIST_HEIGHT - 24,
            :center,
            TEXT_BASE,
            TEXT_SHADOW
          ]]
        )
      end
    end

    #---------------------------------------------------------------------------

    def draw_item_information(overlay)
      item_id = current_item

      if !item_id
        @sprites["itemicon"].item = nil

        pbDrawTextPositions(
          overlay,
          [[
            _INTL("No available items."),
            INFO_X,
            INFO_Y,
            :left,
            DISABLED,
            TEXT_SHADOW
          ]]
        )

        return
      end

      item = GameData::Item.get(item_id)

      @sprites["itemicon"].item = item_id

      pbDrawTextPositions(
        overlay,
        [
          [
            item.name,
            INFO_CENTER,
            INFO_Y,
            :center,
            TEXT_BASE,
            TEXT_SHADOW
          ]
        ]
      )

      description_x     = 312
      # description_x     = (Graphics.width - (INFO_X + INFO_WIDTH)
      description_width = 368

      pbSetSmallFont(overlay)

      drawFormattedTextEx(
        overlay,
        description_x,
        164,
        description_width,
        "<ac>#{item.description}</ac>",
        TEXT_BASE,
        TEXT_SHADOW
      )

      pbSetSystemFont(overlay)
    end

    #---------------------------------------------------------------------------

    def draw_selection_tray(overlay)
      slot_size = TRAY_SLOT_SIZE
      gap       = TRAY_GAP

      ingredient_x = 8

      # Put Condiments immediately after the six Ingredient slots rather than
      # positioning them independently far to the right.
      condiment_x = ingredient_x + (6 * (slot_size + gap)) + 6
      pbSetSmallFont(overlay)

      # Ingredient label.
      pbDrawTextPositions(
        overlay,
        [[
          _INTL("Ing. {1}/6", @selection.ingredient_count),
          ingredient_x,
          TRAY_Y - 22,
          :left,
          TEXT_BASE,
          TEXT_SHADOW
        ]]
      )

      6.times do |i|
        x = ingredient_x + (i * (slot_size + gap))

        draw_small_ingredient_box(
          overlay,
          x,
          TRAY_Y,
          false
        )

        item_id = @selection.selected_ingredients[i]
        draw_tray_item(overlay, item_id, x, TRAY_Y, slot_size) if item_id
      end

      # Condiment label.
      pbDrawTextPositions(
        overlay,
        [[
          _INTL("Con. {1}/4", @selection.condiment_count),
          condiment_x,
          TRAY_Y - 22,
          :left,
          TEXT_BASE,
          TEXT_SHADOW
        ]]
      )

      4.times do |i|
        x = condiment_x + (i * (slot_size + gap))

        draw_small_ingredient_box(
          overlay,
          x,
          TRAY_Y,
          true
        )

        item_id = @selection.selected_condiments[i]
        draw_tray_item(overlay, item_id, x, TRAY_Y, slot_size) if item_id
      end

      pbSetSystemFont(overlay)
    end

    #---------------------------------------------------------------------------

    def draw_small_ingredient_box(overlay, x, y, condiment = false)
      boxes = AnimatedBitmap.new(
        "Graphics/UI/Cooking/ingredient_box_small"
      )

      # Frame 0: Ingredient
      # Frame 1: Condiment
      source_x = condiment ? 32 : 0

      overlay.blt(
        x,
        y,
        boxes.bitmap,
        Rect.new(
          source_x,
          0,
          32,
          32
        )
      )

      boxes.dispose
    end

    #---------------------------------------------------------------------------

    def draw_tray_item(overlay, item_id, x, y, slot_size)
      icon = AnimatedBitmap.new(GameData::Item.icon_filename(item_id))
      bitmap = icon.bitmap

      source_width  = bitmap.width
      source_height = bitmap.height

      # I&A's item artwork is authored at 2x pixel density.
      #
      # Halving both dimensions converts each 2x2 source-pixel block into one
      # screen pixel while preserving the intended pixel grid.
      draw_width  = source_width / 2
      draw_height = source_height / 2

      # Force even placement inside the slot. This keeps the icon aligned with
      # the same effective pixel grid as the slot itself.
      draw_x = x + ((slot_size - draw_width) / 2)
      draw_y = y + ((slot_size - draw_height) / 2)

      draw_x -= draw_x % 2
      draw_y -= draw_y % 2

      overlay.stretch_blt(
        Rect.new(draw_x, draw_y, draw_width, draw_height),
        bitmap,
        Rect.new(0, 0, source_width, source_height)
      )

      icon.dispose
    end

    #---------------------------------------------------------------------------

    def draw_controls(overlay)
      controls = []

      if @selection.confirming?
        controls.push(_INTL("Use: Confirm"))
        controls.push(_INTL("Back: Undo"))
      else
        controls.push(_INTL("Use: Select"))
        controls.push(_INTL("Back: Undo"))

        if @selection.can_continue?
          controls.push(
            _INTL(
              "{1}: Next",
              Keybinds.button_name(:special)
            )
          )
        end
      end

      pbDrawTextPositions(
        overlay,
        [[
          controls.join("    "),
          Graphics.width / 2,
          Graphics.height - 26,
          :center,
          TEXT_BASE,
          TEXT_SHADOW
        ]]
      )
    end

    #---------------------------------------------------------------------------

    def draw_confirmation(overlay)
      pbDrawTextPositions(
        overlay,
        [[
          _INTL("Ready to cook?"),
          Graphics.width / 2,
          58,
          :center,
          TEXT_BASE,
          TEXT_SHADOW
        ]]
      )

      #-------------------------------------------------------------------------
      # Ingredients
      #-------------------------------------------------------------------------
      ingredient_count = @selection.selected_ingredients.length

      if ingredient_count > 0
        pbDrawTextPositions(
          overlay,
          [[
            _INTL("Ingredients"),
            Graphics.width / 2,
            116,
            :center,
            TEXT_BASE,
            TEXT_SHADOW
          ]]
        )

        draw_confirmation_item_row(
          overlay,
          @selection.selected_ingredients,
          144,
          false
        )
      end

      #-------------------------------------------------------------------------
      # Condiments
      #-------------------------------------------------------------------------
      condiment_count = @selection.selected_condiments.length

      if condiment_count > 0
        pbDrawTextPositions(
          overlay,
          [[
            _INTL("Condiments"),
            Graphics.width / 2,
            222,
            :center,
            TEXT_BASE,
            TEXT_SHADOW
          ]]
        )

        draw_confirmation_item_row(
          overlay,
          @selection.selected_condiments,
          250,
          true
        )
      end
    end

        #---------------------------------------------------------------------------

        def draw_confirmation_item_row(
          overlay,
          items,
          y,
          condiment = false
        )
          return if !items || items.empty?

          slot_size = 64
          gap       = 12

          total_width = (items.length * slot_size) +
                        ((items.length - 1) * gap)

          start_x = (Graphics.width - total_width) / 2

          items.each_with_index do |item_id, i|
            x = start_x + (i * (slot_size + gap))

            draw_large_ingredient_box(
              overlay,
              x,
              y,
              condiment
            )

            draw_confirmation_item(
              overlay,
              item_id,
              x,
              y,
              slot_size
            )
          end
        end

        #---------------------------------------------------------------------------

    def draw_large_ingredient_box(overlay, x, y, condiment = false)
      boxes = AnimatedBitmap.new(
        "Graphics/UI/Cooking/ingredient_box_large"
      )

      # Frame 0: 64x64 Ingredient box
      # Frame 1: 64x64 Condiment box
      source_x = condiment ? 64 : 0

      overlay.blt(
        x,
        y,
        boxes.bitmap,
        Rect.new(
          source_x,
          0,
          64,
          64
        )
      )

      boxes.dispose
    end

    def draw_confirmation_item(overlay, item_id, x, y, slot_size)
      icon = AnimatedBitmap.new(GameData::Item.icon_filename(item_id))
      bitmap = icon.bitmap

      source_width  = bitmap.width
      source_height = bitmap.height

      # Keep the same pixel-density rule as the selection tray.
      draw_width  = source_width / 2
      draw_height = source_height / 2

      # Confirmation icons are intentionally displayed at twice the size of
      # the small selection-tray versions.
      draw_width  *= 2
      draw_height *= 2

      draw_x = x + ((slot_size - draw_width) / 2)
      draw_y = y + ((slot_size - draw_height) / 2)

      # Keep placement aligned with I&A's 2x2 pixel grid.
      draw_x -= draw_x % 2
      draw_y -= draw_y % 2

      overlay.stretch_blt(
        Rect.new(draw_x, draw_y, draw_width, draw_height),
        bitmap,
        Rect.new(0, 0, source_width, source_height)
      )

      icon.dispose
    end
  end

  #=============================================================================
  # Creative Mode entry point
  #=============================================================================
  def self.open_creative
    scene = Cooking::CreativeScene.new

    pbFadeOutIn do
      scene.pbStartScene
      scene.pbMain
      scene.pbEndScene
    end

    return true
  end
end