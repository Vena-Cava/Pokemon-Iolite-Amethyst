#===============================================================================
# I&A - Cooking System
# Recipe Selection UI
#
# Used when Recipe Mode needs the player to choose a concrete item for a
# recipe slot.
#
# Current implementation:
#   - Required Group selection
#
# Planned:
#   - Optional Ingredient selection
#   - Optional Condiment selection
#===============================================================================

module Cooking
  class RecipeSelectionScene
    #---------------------------------------------------------------------------
    # Item list - same layout as Creative Mode
    #---------------------------------------------------------------------------
    LIST_X       = 8
    LIST_Y       = 46
    LIST_WIDTH   = 300
    LIST_HEIGHT  = 218

    ROW_HEIGHT   = 30
    VISIBLE_ROWS = 6

    #---------------------------------------------------------------------------
    # Item information - same layout as Creative Mode
    #---------------------------------------------------------------------------
    INFO_X       = 382
    INFO_Y       = 34
    INFO_WIDTH   = Graphics.width - INFO_X - 16
    INFO_CENTER  = INFO_X + (INFO_WIDTH / 2)

    #---------------------------------------------------------------------------
    # Recipe tray - same layout as Creative Mode
    #---------------------------------------------------------------------------
    TRAY_Y       = 318
    SLOT_SIZE    = 32
    SLOT_GAP     = 2

    TEXT_BASE     = Color.new(248, 248, 248)
    TEXT_SHADOW   = Color.new(72, 72, 72)
    TEXT_DISABLED = Color.new(144, 144, 144)

    #===========================================================================
    # Setup
    #===========================================================================

    def initialize(
      recipe,
      candidates,
      selected_ingredients,
      selected_condiments,
      category,
      slot_index
    )
      @recipe = recipe

      @items = candidates.clone

      @selected_ingredients = selected_ingredients.clone
      @selected_condiments  = selected_condiments.clone

      @category   = category
      @slot_index = slot_index

      @index   = 0
      @top_row = 0
    end

    def pbStartScene
      @viewport = Viewport.new(
        0,
        0,
        Graphics.width,
        Graphics.height
      )
      @viewport.z = 99999

      @sprites = {}

      @sprites["background"] = BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )

      @sprites["background"].bitmap.fill_rect(
        0,
        0,
        Graphics.width,
        Graphics.height,
        Color.new(48, 64, 80)
      )

      @sprites["overlay"] = BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )

      pbSetSystemFont(@sprites["overlay"].bitmap)

      @sprites["itemicon"] = ItemIconSprite.new(
        INFO_CENTER,
        110,
        nil,
        @viewport
      )
      @sprites["itemicon"].setOffset(PictureOrigin::CENTER)
      @sprites["itemicon"].zoom_x = 2
      @sprites["itemicon"].zoom_y = 2

      refresh

      pbFadeInAndShow(@sprites)
    end

    def pbEndScene
      pbFadeOutAndHide(@sprites)
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end

    def set_selection(
      candidates,
      selected_ingredients,
      selected_condiments,
      category,
      slot_index
    )
      @items = candidates.clone

      @selected_ingredients = selected_ingredients.clone
      @selected_condiments  = selected_condiments.clone

      @category   = category
      @slot_index = slot_index

      @index   = 0
      @top_row = 0

      refresh
    end

    #===========================================================================
    # Main loop
    #===========================================================================

    def pbChoose
      loop do
        Graphics.update
        Input.update
        pbUpdateSpriteHash(@sprites)

        old_index = @index

        if Keybinds.repeat?(:up)
          move_vertical(-1)
        elsif Keybinds.repeat?(:down)
          move_vertical(1)
        end

        if old_index != @index
          pbPlayCursorSE
          ensure_cursor_visible
          refresh
        end

        #-----------------------------------------------------------------------
        # Required slot: selecting an item immediately resolves the slot.
        #-----------------------------------------------------------------------
        if Keybinds.trigger?(:use)
          item = current_item

          if item
            pbPlayDecisionSE
            return item
          end

          pbPlayBuzzerSE

        #-----------------------------------------------------------------------
        # Back cancels this Recipe Mode attempt.
        #-----------------------------------------------------------------------
        elsif Keybinds.trigger?(:back)
          pbPlayCancelSE
          return nil
        end
      end
    end

    #===========================================================================
    # Item list
    #===========================================================================

    def current_item
      return nil if @items.empty?
      return @items[@index]
    end

    def move_vertical(direction)
      return if @items.length <= 1

      @index = (@index + direction) % @items.length
    end

    def ensure_cursor_visible
      if @index < @top_row
        @top_row = @index
      elsif @index >= @top_row + VISIBLE_ROWS
        @top_row = @index - VISIBLE_ROWS + 1
      end

      max_top = [@items.length - VISIBLE_ROWS, 0].max
      @top_row = [[@top_row, 0].max, max_top].min
    end

    #===========================================================================
    # Drawing
    #===========================================================================

    def refresh
      overlay = @sprites["overlay"].bitmap
      overlay.clear

      draw_header(overlay)
      draw_item_list(overlay)
      draw_item_information(overlay)
      draw_recipe_tray(overlay)
      draw_controls(overlay)
    end

    #---------------------------------------------------------------------------

    def draw_header(overlay)
      slot_name = current_slot_name

      pbDrawTextPositions(
        overlay,
        [
          [
            _INTL("Choose {1}", slot_name),
            16,
            8,
            :left,
            TEXT_BASE,
            TEXT_SHADOW
          ],
          [
            @recipe.name,
            Graphics.width - 16,
            8,
            :right,
            TEXT_BASE,
            TEXT_SHADOW
          ]
        ]
      )
    end

    def current_slot_name
      slots = current_required_slots
      slot = slots[@slot_index]

      return _INTL("Ingredient") if !slot

      if slot[:type] == :GROUP
        group = GameData::IngredientGroup.try_get(slot[:id])

        return group.name if group
      end

      item = GameData::Item.try_get(slot[:id])

      return item.name if item

      return @category == :CONDIMENT ?
        _INTL("Condiment") :
        _INTL("Ingredient")
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

      if @items.empty?
        pbDrawTextPositions(
          overlay,
          [[
            _INTL("No available items."),
            LIST_X + 8,
            LIST_Y + 8,
            :left,
            TEXT_DISABLED,
            TEXT_SHADOW
          ]]
        )
        return
      end

      last_index = [
        @top_row + VISIBLE_ROWS - 1,
        @items.length - 1
      ].min

      (@top_row..last_index).each do |item_index|
        item_id = @items[item_index]
        item    = GameData::Item.get(item_id)

        x = LIST_X + 8
        y = LIST_Y + 18 +
            ((item_index - @top_row) * ROW_HEIGHT)

        if item_index == @index
          overlay.fill_rect(
            LIST_X,
            y - 4,
            LIST_WIDTH,
            ROW_HEIGHT,
            Color.new(88, 112, 136)
          )
        end

        quantity = bag_quantity(item_id)

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
              LIST_X + LIST_WIDTH - 8,
              y,
              :right,
              TEXT_BASE,
              TEXT_SHADOW
            ]
          ]
        )
      end
    end

    #---------------------------------------------------------------------------

    def draw_item_information(overlay)
      item_id = current_item

      if !item_id
        @sprites["itemicon"].visible = false
        return
      end

      item = GameData::Item.get(item_id)

      @sprites["itemicon"].visible = true
      @sprites["itemicon"].item = item_id

      pbDrawTextPositions(
        overlay,
        [[
          item.name,
          INFO_CENTER,
          INFO_Y,
          :center,
          TEXT_BASE,
          TEXT_SHADOW
        ]]
      )

      description_x     = 312
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

    #===========================================================================
    # Recipe tray
    #===========================================================================

    def draw_recipe_tray(overlay)
      slot_size = SLOT_SIZE
      gap       = SLOT_GAP

      ingredient_x = 8
      condiment_x  = ingredient_x +
                     (6 * (slot_size + gap)) +
                     6

      tray_y = TRAY_Y

      draw_recipe_tray_labels(
        overlay,
        ingredient_x,
        condiment_x
      )

      draw_recipe_tray_category(
        overlay,
        @recipe.required_ingredients || [],
        @selected_ingredients,
        :INGREDIENT,
        ingredient_x,
        tray_y,
        6
      )

      draw_recipe_tray_category(
        overlay,
        @recipe.required_condiments || [],
        @selected_condiments,
        :CONDIMENT,
        condiment_x,
        tray_y,
        4
      )
    end

    def draw_recipe_tray_labels(
      overlay,
      ingredient_x,
      condiment_x
    )
      ingredient_count = @selected_ingredients.length
      condiment_count  = @selected_condiments.length

      pbSetSmallFont(overlay)

      pbDrawTextPositions(
        overlay,
        [
          [
            _INTL("Ing. {1}/6", ingredient_count),
            ingredient_x,
            TRAY_Y - 24,
            :left,
            TEXT_BASE,
            TEXT_SHADOW
          ],
          [
            _INTL("Con. {1}/4", condiment_count),
            condiment_x,
            TRAY_Y - 24,
            :left,
            TEXT_BASE,
            TEXT_SHADOW
          ]
        ]
      )

      pbSetSystemFont(overlay)
    end

    def draw_recipe_tray_category(
      overlay,
      required_slots,
      selected_items,
      category,
      start_x,
      y,
      capacity
    )
      capacity.times do |i|
        x = start_x + (i * (SLOT_SIZE + SLOT_GAP))

        draw_small_ingredient_box(
          overlay,
          x,
          y,
          category == :CONDIMENT
        )

        #-----------------------------------------------------------------------
        # Required recipe slot.
        #-----------------------------------------------------------------------
        if i < required_slots.length
          slot = required_slots[i]

          item_id = selected_items[i]

          if !item_id
            item_id = preview_item_for_slot(slot)
          end

          if item_id
            draw_tray_item(
              overlay,
              item_id,
              x,
              y,
              SLOT_SIZE
            )
          end

          # The small cursor identifies the exact required slot currently being
          # resolved.
          if category == @category && i == @slot_index
            draw_slot_cursor(
              overlay,
              x,
              y
            )
          end
        end
      end
    end

    #---------------------------------------------------------------------------

    def preview_item_for_slot(slot)
      return nil if !slot

      if slot[:type] == :ITEM
        return slot[:id]
      end

      if slot[:type] == :GROUP
        group = GameData::IngredientGroup.try_get(slot[:id])
        return nil if !group || group.items.empty?

        owned = group.items.select do |item_id|
          bag_quantity(item_id) > 0
        end

        return owned[0] if !owned.empty?
        return group.items[0]
      end

      return nil
    end

    #---------------------------------------------------------------------------

    def draw_small_ingredient_box(
      overlay,
      x,
      y,
      condiment = false
    )
      boxes = AnimatedBitmap.new(
        "Graphics/UI/Cooking/ingredient_box_small"
      )

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

    def draw_slot_cursor(overlay, x, y)
      cursor = AnimatedBitmap.new(
        "Graphics/UI/Cooking/cursor_ingredient_box_small"
      )

      # The cursor is 36x36 while the box is 32x32, so offset it by 2 pixels
      # to surround the box evenly.
      overlay.blt(
        x - 2,
        y - 2,
        cursor.bitmap,
        Rect.new(
          0,
          0,
          36,
          36
        )
      )

      cursor.dispose
    end

    #---------------------------------------------------------------------------

    def draw_tray_item(
      overlay,
      item_id,
      x,
      y,
      slot_size
    )
      icon = AnimatedBitmap.new(
        GameData::Item.icon_filename(item_id)
      )

      bitmap = icon.bitmap

      source_width  = bitmap.width
      source_height = bitmap.height

      # Cooking UI uses the game's 2x2 art-pixel density.
      draw_width  = source_width / 2
      draw_height = source_height / 2

      draw_x = x + ((slot_size - draw_width) / 2)
      draw_y = y + ((slot_size - draw_height) / 2)

      draw_x -= draw_x % 2
      draw_y -= draw_y % 2

      overlay.stretch_blt(
        Rect.new(
          draw_x,
          draw_y,
          draw_width,
          draw_height
        ),
        bitmap,
        Rect.new(
          0,
          0,
          source_width,
          source_height
        )
      )

      icon.dispose
    end

    #===========================================================================
    # Data helpers
    #===========================================================================

    def current_required_slots
      if @category == :CONDIMENT
        return @recipe.required_condiments || []
      end

      return @recipe.required_ingredients || []
    end

    def bag_quantity(item_id)
      return 0 if !item_id
      return 0 if !$bag

      item = GameData::Item.try_get(item_id)
      return 0 if !item

      pocket = item.pocket

      return 0 if !pocket || pocket <= 0
      return 0 if !$bag.pockets[pocket]

      quantity = 0

      $bag.pockets[pocket].each do |slot|
        next if !slot
        next if slot[0] != item_id

        quantity += slot[1]
      end

      return quantity
    end

    #===========================================================================
    # Controls
    #===========================================================================

    def draw_controls(overlay)
      controls = [
        _INTL("Use: Select"),
        _INTL("Back: Cancel")
      ]

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
  end
end