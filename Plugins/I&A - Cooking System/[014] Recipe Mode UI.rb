#===============================================================================
# I&A - Cooking System
# Recipe Mode UI
#===============================================================================

module Cooking
  #=============================================================================
  # Recipe Browser
  #=============================================================================
  class RecipeScene
    #---------------------------------------------------------------------------
    # Recipe list
    #---------------------------------------------------------------------------
    LIST_X        = 8
    LIST_Y        = 46
    LIST_WIDTH    = 350
    LIST_HEIGHT   = 270

    COLUMN_GAP    = 8
    ROW_GAP       = 8

    CARD_WIDTH    = 200
    CARD_HEIGHT   = 100

    ROW_HEIGHT    = CARD_HEIGHT + ROW_GAP
    VISIBLE_ROWS  = 3

    MEAL_ICON_SIZE = 48

    #---------------------------------------------------------------------------
    # Recipe information
    #---------------------------------------------------------------------------
    INFO_X        = 464
    INFO_Y        = 46
    INFO_WIDTH    = Graphics.width - INFO_X - 8
    INFO_CENTER   = INFO_X + (INFO_WIDTH / 2)

    SLOT_SIZE     = 32
    SLOT_GAP      = 4

    TEXT_BASE     = Color.new(248, 248, 248)
    TEXT_SHADOW   = Color.new(72, 72, 72)
    TEXT_DISABLED = Color.new(144, 144, 144)

    # Number of frames before a Group changes its displayed member.
    GROUP_CYCLE_FRAMES = 60

    #===========================================================================
    # Setup
    #===========================================================================

    def initialize
      @recipes = []
      @index = 0
      @top_row = 0

      @page = :INGREDIENTS

      @group_cycle_counter = 0
      @group_cycle_index   = 0
    end

    def pbStartScene
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
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

      rebuild_recipe_list
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

        update_group_cycle

        old_index = @index

        if Keybinds.repeat?(:up)
          move_vertical(-1)
        elsif Keybinds.repeat?(:down)
          move_vertical(1)
        elsif Keybinds.repeat?(:left)
          move_horizontal(-1)
        elsif Keybinds.repeat?(:right)
          move_horizontal(1)
        end

        if old_index != @index
          pbPlayCursorSE
          @group_cycle_counter = 0
          @group_cycle_index   = 0
          ensure_cursor_visible
          refresh
        end

        #-----------------------------------------------------------------------
        # Select recipe.
        #-----------------------------------------------------------------------
        if Keybinds.trigger?(:use)
          recipe = current_recipe

          if recipe
            if !recipe_cookable?(recipe)
              pbPlayBuzzerSE
            else
              pbPlayDecisionSE
              begin_recipe(recipe)
              refresh
            end
          end

        #-----------------------------------------------------------------------
        # Back
        #-----------------------------------------------------------------------
        elsif Keybinds.trigger?(:back)
          pbPlayCancelSE
          return :EXIT

        #-----------------------------------------------------------------------
        # Special toggles Ingredients & Effects / Description.
        #-----------------------------------------------------------------------
        elsif Keybinds.trigger?(:special)
          pbPlayDecisionSE

          @page = if @page == :INGREDIENTS
                    :DESCRIPTION
                  else
                    :INGREDIENTS
                  end

          refresh
        end
      end
    end

    #===========================================================================
    # Known recipe list
    #===========================================================================

    def rebuild_recipe_list
      @recipes = Cooking.known_recipes

      @recipes.sort_by! do |recipe|
        [
          recipe.family.to_s,
          GameData::CookingRecipe::TIER_ORDER[recipe.tier] || 999,
          recipe.name
        ]
      end

      @index = [@index, @recipes.length - 1].min
      @index = 0 if @index < 0

      ensure_cursor_visible
    end

    def current_recipe
      return nil if @recipes.empty?
      return @recipes[@index]
    end

    #===========================================================================
    # Two-column navigation
    #===========================================================================

    def row_count
      return (@recipes.length / 2.0).ceil
    end

    def current_row
      return @index / 2
    end

    def current_column
      return @index % 2
    end

    def index_for(row, column)
      index = (row * 2) + column

      # If the final row only has one recipe, use its left-hand entry.
      if index >= @recipes.length
        index = row * 2
      end

      return index
    end

    def move_vertical(direction)
      return if @recipes.length <= 1

      row    = current_row
      column = current_column

      row = (row + direction) % row_count
      @index = index_for(row, column)
    end

    def move_horizontal(direction)
      return if @recipes.length <= 1

      row    = current_row
      column = current_column

      if direction < 0
        column = 0
      else
        column = 1
      end

      new_index = index_for(row, column)

      if new_index >= 0 && new_index < @recipes.length
        @index = new_index
      end
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
    # Group cycling
    #===========================================================================

    def update_group_cycle
      return if @page != :INGREDIENTS
      return if !current_recipe

      @group_cycle_counter += 1
      return if @group_cycle_counter < GROUP_CYCLE_FRAMES

      @group_cycle_counter = 0
      @group_cycle_index += 1

      refresh
    end

    #===========================================================================
    # Bag helpers
    #===========================================================================

    # Uses the same direct-pocket approach as Cooking::Selection so that
    # Cooking Ingredient Pocket 11 is handled safely.
    def bag_quantity(item)
      item = item.id if item.respond_to?(:id)
      item = item.upcase.to_sym if item.is_a?(String)

      return 0 if !item
      return 0 if !$bag

      item_data = GameData::Item.try_get(item)
      return 0 if !item_data

      pocket = item_data.pocket
      return 0 if !pocket || pocket <= 0
      return 0 if !$bag.pockets[pocket]

      quantity = 0

      $bag.pockets[pocket].each do |slot|
        next if !slot
        next if slot[0] != item
        quantity += slot[1]
      end

      return quantity
    end

    #===========================================================================
    # Recipe slot helpers
    #===========================================================================

    def slot_item?(slot)
      return slot.is_a?(Hash) && slot[:type] == :ITEM
    end

    def slot_group?(slot)
      return slot.is_a?(Hash) && slot[:type] == :GROUP
    end

    def slot_id(slot)
      return nil if !slot.is_a?(Hash)
      return slot[:id]
    end

    #---------------------------------------------------------------------------
    # Returns all item IDs which can satisfy a recipe slot.
    #---------------------------------------------------------------------------
    def items_for_slot(slot)
      if slot_item?(slot)
        item_id = slot_id(slot)
        return item_id ? [item_id] : []
      end

      if slot_group?(slot)
        group = GameData::IngredientGroup.try_get(slot_id(slot))
        return [] if !group
        return group.items.clone
      end

      return []
    end

    #---------------------------------------------------------------------------
    # For cycling a Group's icon:
    #
    # If the player owns any valid member, ONLY cycle through owned members.
    # Otherwise cycle through the entire Group.
    #
    # This prevents an unowned item from appearing with a green check.
    #---------------------------------------------------------------------------
    def display_items_for_slot(slot)
      items = items_for_slot(slot)
      return items if items.length <= 1

      owned = items.select { |item_id| bag_quantity(item_id) > 0 }

      return owned if !owned.empty?
      return items
    end

    def displayed_item_for_slot(slot)
      items = display_items_for_slot(slot)
      return nil if items.empty?

      return items[@group_cycle_index % items.length]
    end

    def displayed_item_for_recipe_slot(slot, available)
      items = items_for_slot(slot)
      return nil if items.empty?

      # Fixed Item slots never cycle.
      return items[0] if slot_item?(slot)

      # If this particular Group slot can currently be satisfied, only show
      # valid Group members the player actually owns.
      #
      # If it cannot be satisfied, cycle through every valid Group member so
      # the player can see all of the items that could fill the missing slot.
      if available
        owned_items = items.select do |item_id|
          bag_quantity(item_id) > 0
        end

        items = owned_items if !owned_items.empty?
      end

      return items[@group_cycle_index % items.length]
    end

    #===========================================================================
    # Recipe selection / required-slot resolution
    #===========================================================================

    def begin_recipe(recipe)
      required_ingredients = recipe.required_ingredients || []
      required_condiments  = recipe.required_condiments || []

      reserved = Hash.new(0)

      selected_ingredients = []
      selected_condiments  = []

      # This holds the ONE Recipe Selection scene used for this entire recipe.
      # It is created lazily, so recipes which need no Group choices never open it.
      selection_scene = [nil]

      result = resolve_required_slots(
        recipe,
        required_ingredients,
        reserved,
        selected_ingredients,
        selected_ingredients,
        selected_condiments,
        :INGREDIENT,
        selection_scene
      )

      if !result
        close_recipe_selection_scene(selection_scene)
        return false
      end

      result = resolve_required_slots(
        recipe,
        required_condiments,
        reserved,
        selected_condiments,
        selected_ingredients,
        selected_condiments,
        :CONDIMENT,
        selection_scene
      )

      if !result
        close_recipe_selection_scene(selection_scene)
        return false
      end

      close_recipe_selection_scene(selection_scene)

      if $DEBUG
        ingredient_names = selected_ingredients.map do |item_id|
          GameData::Item.get(item_id).name
        end

        condiment_names = selected_condiments.map do |item_id|
          GameData::Item.get(item_id).name
        end

        ingredient_text = ingredient_names.empty? ?
          _INTL("None") :
          ingredient_names.join(", ")

        condiment_text = condiment_names.empty? ?
          _INTL("None") :
          condiment_names.join(", ")

        pbMessage(
          _INTL(
            "DEBUG: Required slots resolved.\n\nIngredients:\n{1}\n\nCondiments:\n{2}",
            ingredient_text,
            condiment_text
          )
        )
      end

      return true
    end

    def close_recipe_selection_scene(selection_scene)
      return if !selection_scene
      return if !selection_scene[0]

      selection_scene[0].pbEndScene
      selection_scene[0] = nil
    end

    #-------------------------------------------------------------------------------
    # Resolves every required slot in one category.
    #
    # Fixed Item slots are selected automatically.
    #
    # Group slots:
    #   1 viable owned item  -> automatically selected
    #   2+ viable owned items -> player chooses
    #
    # A choice is only considered viable if choosing it still leaves enough items
    # to satisfy every later required slot.
    #
    # Returns an Array of concrete item IDs, or nil if the player cancels.
    #-------------------------------------------------------------------------------
    def resolve_required_slots(
      recipe,
      slots,
      reserved,
      selected,
      selected_ingredients,
      selected_condiments,
      category,
      selection_scene
    )
      slots = slots || []

      slots.each_with_index do |slot, index|
        candidates = viable_items_for_required_slot(
          slots,
          index,
          reserved
        )

        # This should normally be impossible because recipe_cookable? was checked
        # first, but keep the resolver safe if Bag contents change.
        if candidates.empty?
          pbPlayBuzzerSE
          return false
        end

        chosen_item = nil

        if slot_item?(slot)
          # Concrete Item slots always resolve automatically.
          chosen_item = candidates[0]

        elsif candidates.length == 1
          # Don't open a selection screen if there is only one valid solution.
          chosen_item = candidates[0]

        else
          if !selection_scene[0]
            selection_scene[0] = Cooking::RecipeSelectionScene.new(
              recipe,
              candidates,
              selected_ingredients,
              selected_condiments,
              category,
              index
            )

            selection_scene[0].pbStartScene
          else
            selection_scene[0].set_selection(
              candidates,
              selected_ingredients,
              selected_condiments,
              category,
              index
            )
          end

          chosen_item = selection_scene[0].pbChoose

          # Back on the graphical selection screen cancels this Recipe attempt.
          return false if !chosen_item
        end

        selected.push(chosen_item)
        reserved[chosen_item] += 1
      end

      return true
    end

    #-------------------------------------------------------------------------------
    # Returns the currently owned items that can satisfy this slot AND still allow
    # all later required slots to be completed.
    #-------------------------------------------------------------------------------
    def viable_items_for_required_slot(slots, index, reserved)
      slot = slots[index]

      candidates = items_for_slot(slot).select do |item_id|
        remaining_quantity(item_id, reserved) > 0
      end

      viable = []

      candidates.each do |item_id|
        reserved[item_id] += 1

        remaining_slots = slots[(index + 1)..-1] || []

        if required_slots_can_be_completed?(remaining_slots, reserved)
          viable.push(item_id)
        end

        reserved[item_id] -= 1
      end

      viable.sort_by! do |item_id|
        GameData::Item.get(item_id).name
      end

      return viable
    end

    #-------------------------------------------------------------------------------
    # Bag quantity after accounting for items already reserved by Recipe Mode.
    #-------------------------------------------------------------------------------
    def remaining_quantity(item_id, reserved)
      return [bag_quantity(item_id) - reserved[item_id], 0].max
    end

    #-------------------------------------------------------------------------------
    # Checks whether all supplied slots can still be satisfied simultaneously.
    #
    # This is deliberately backtracking rather than greedy because Ingredient
    # Groups are allowed to overlap.
    #-------------------------------------------------------------------------------
    def required_slots_can_be_completed?(slots, reserved)
      return true if !slots || slots.empty?

      return search_required_completion(
        slots,
        0,
        reserved
      )
    end

    def search_required_completion(slots, index, reserved)
      return true if index >= slots.length

      slot = slots[index]

      items_for_slot(slot).each do |item_id|
        next if remaining_quantity(item_id, reserved) <= 0

        reserved[item_id] += 1

        if search_required_completion(slots, index + 1, reserved)
          reserved[item_id] -= 1
          return true
        end

        reserved[item_id] -= 1
      end

      return false
    end

    #===========================================================================
    # Availability
    #===========================================================================

    def recipe_cookable?(recipe)
      required_ingredients = recipe.required_ingredients || []
      required_condiments  = recipe.required_condiments || []

      ingredient_checks = required_slot_availability(required_ingredients)
      condiment_checks  = required_slot_availability(required_condiments)

      return ingredient_checks.all? && condiment_checks.all?
    end

    def recipe_slot_availability(required_slots, optional_slots)
      required_slots = required_slots || []
      optional_slots = optional_slots || []

      all_slots = required_slots + optional_slots

      return [[], []] if all_slots.empty?

      remaining = {}

      all_slots.each do |slot|
        items_for_slot(slot).each do |item_id|
          if !remaining.key?(item_id)
            remaining[item_id] = bag_quantity(item_id)
          end
        end
      end

      best_required = Array.new(required_slots.length, false)
      best_optional = Array.new(optional_slots.length, false)

      search_recipe_slot_availability(
        required_slots,
        optional_slots,
        0,
        0,
        remaining,
        Array.new(required_slots.length, false),
        Array.new(optional_slots.length, false),
        best_required,
        best_optional
      )

      return [best_required, best_optional]
    end

    def search_recipe_slot_availability(
      required_slots,
      optional_slots,
      required_index,
      optional_index,
      remaining,
      current_required,
      current_optional,
      best_required,
      best_optional
    )
      # Required slots always take priority.
      if required_index < required_slots.length
        slot = required_slots[required_index]

        items_for_slot(slot).each do |item_id|
          next if !remaining[item_id] || remaining[item_id] <= 0

          remaining[item_id] -= 1
          current_required[required_index] = true

          search_recipe_slot_availability(
            required_slots,
            optional_slots,
            required_index + 1,
            optional_index,
            remaining,
            current_required,
            current_optional,
            best_required,
            best_optional
          )

          current_required[required_index] = false
          remaining[item_id] += 1
        end

        current_required[required_index] = false

        search_recipe_slot_availability(
          required_slots,
          optional_slots,
          required_index + 1,
          optional_index,
          remaining,
          current_required,
          current_optional,
          best_required,
          best_optional
        )

        return
      end

      if optional_index < optional_slots.length
        slot = optional_slots[optional_index]

        items_for_slot(slot).each do |item_id|
          next if !remaining[item_id] || remaining[item_id] <= 0

          remaining[item_id] -= 1
          current_optional[optional_index] = true

          search_recipe_slot_availability(
            required_slots,
            optional_slots,
            required_index,
            optional_index + 1,
            remaining,
            current_required,
            current_optional,
            best_required,
            best_optional
          )

          current_optional[optional_index] = false
          remaining[item_id] += 1
        end

        current_optional[optional_index] = false

        search_recipe_slot_availability(
          required_slots,
          optional_slots,
          required_index,
          optional_index + 1,
          remaining,
          current_required,
          current_optional,
          best_required,
          best_optional
        )

        return
      end

      current_required_count = current_required.count(true)
      best_required_count    = best_required.count(true)

      current_optional_count = current_optional.count(true)
      best_optional_count    = best_optional.count(true)

      better = current_required_count > best_required_count

      if current_required_count == best_required_count
        better = current_optional_count > best_optional_count
      end

      if better
        current_required.each_index do |i|
          best_required[i] = current_required[i]
        end

        current_optional.each_index do |i|
          best_optional[i] = current_optional[i]
        end
      end
    end

    #---------------------------------------------------------------------------
    # Determines which required slots can simultaneously be satisfied.
    #
    # This deliberately uses backtracking rather than checking each slot
    # independently. That matters for:
    #
    #   [Pizza Cheese] x2
    #
    # and for overlapping Ingredient Groups.
    #
    # Returns an Array<Boolean>, one value per slot.
    #---------------------------------------------------------------------------
    def required_slot_availability(slots)
      return [] if !slots || slots.empty?

      remaining = {}

      slots.each do |slot|
        items_for_slot(slot).each do |item_id|
          remaining[item_id] = bag_quantity(item_id) if !remaining.key?(item_id)
        end
      end

      best = Array.new(slots.length, false)
      current = Array.new(slots.length, false)

      search_required_availability(
        slots,
        0,
        remaining,
        current,
        best
      )

      return best
    end

    def search_required_availability(slots, index, remaining, current, best)
      if index >= slots.length
        if current.count(true) > best.count(true)
          current.each_index { |i| best[i] = current[i] }
        end
        return
      end

      # Try satisfying this slot first.
      items_for_slot(slots[index]).each do |item_id|
        next if !remaining[item_id] || remaining[item_id] <= 0

        remaining[item_id] -= 1
        current[index] = true

        search_required_availability(
          slots,
          index + 1,
          remaining,
          current,
          best
        )

        current[index] = false
        remaining[item_id] += 1
      end

      # Also consider leaving this slot unsatisfied.
      current[index] = false

      search_required_availability(
        slots,
        index + 1,
        remaining,
        current,
        best
      )
    end

    #===========================================================================
    # Drawing
    #===========================================================================

    def refresh
      overlay = @sprites["overlay"].bitmap
      overlay.clear

      draw_header(overlay)
      draw_recipe_list(overlay)

      recipe = current_recipe

      if !recipe
        draw_no_recipes(overlay)
      elsif @page == :INGREDIENTS
        draw_ingredients_page(overlay, recipe)
      else
        draw_description_page(overlay, recipe)
      end

      draw_controls(overlay)
    end

    #---------------------------------------------------------------------------

    def draw_header(overlay)
      page_name = if @page == :INGREDIENTS
                    _INTL("Ingredients & Effects")
                  else
                    _INTL("Description")
                  end

      pbDrawTextPositions(
        overlay,
        [
          [
            _INTL("Recipes"),
            8,
            8,
            :left,
            TEXT_BASE,
            TEXT_SHADOW
          ],
          [
            page_name,
            Graphics.width - 8,
            8,
            :right,
            TEXT_BASE,
            TEXT_SHADOW
          ]
        ]
      )
    end

    #---------------------------------------------------------------------------

    def draw_recipe_list(overlay)
      return if @recipes.empty?

      first_row = @top_row
      last_row  = [@top_row + VISIBLE_ROWS - 1, row_count - 1].min

      (first_row..last_row).each do |row|
        2.times do |column|
          recipe_index = (row * 2) + column
          next if recipe_index >= @recipes.length

          recipe = @recipes[recipe_index]

          x = LIST_X + (column * (CARD_WIDTH + COLUMN_GAP))
          y = LIST_Y + ((row - @top_row) * ROW_HEIGHT)

          selected = (recipe_index == @index)

          draw_recipe_card(
            overlay,
            recipe,
            x,
            y,
            selected
          )
        end
      end

      if @top_row > 0
        pbDrawTextPositions(
          overlay,
          [[
            "▲",
            LIST_X + (LIST_WIDTH / 2),
            LIST_Y - 6,
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
            LIST_Y + LIST_HEIGHT - 18,
            :center,
            TEXT_BASE,
            TEXT_SHADOW
          ]]
        )
      end
    end

    def draw_recipe_card(overlay, recipe, x, y, selected)
      cookable = recipe_cookable?(recipe)

      card_bitmap = AnimatedBitmap.new(
        "Graphics/UI/Cooking/recipe_card"
      )

      opacity = cookable ? 255 : 112

      overlay.blt(
        x,
        y,
        card_bitmap.bitmap,
        Rect.new(
          0,
          0,
          200,
          100
        ),
        opacity
      )

      card_bitmap.dispose

      if selected
        cursor_bitmap = AnimatedBitmap.new(
          "Graphics/UI/Cooking/cursor_recipe_card"
        )

        overlay.blt(
          x - 2,
          y - 2,
          cursor_bitmap.bitmap,
          Rect.new(
            0,
            0,
            204,
            104
          )
        )

        cursor_bitmap.dispose
      end

      draw_recipe_card_icon(
        overlay,
        recipe,
        x + 4,
        y + ((CARD_HEIGHT - MEAL_ICON_SIZE) / 2),
        cookable
      )

      text_x     = x + MEAL_ICON_SIZE + 8
      text_width = CARD_WIDTH - MEAL_ICON_SIZE - 12

      pbSetSmallFont(overlay)

      words = recipe.name.split(" ")
      lines = []
      current_line = ""

      words.each do |word|
        test_line = current_line.empty? ? word : "#{current_line} #{word}"

        if overlay.text_size(test_line).width <= text_width
          current_line = test_line
        else
          lines << current_line if !current_line.empty?
          current_line = word
        end
      end

      lines << current_line if !current_line.empty?

      line_height = overlay.font.size
      text_height = lines.length * line_height
      text_y = y + ((CARD_HEIGHT - text_height) / 2)

      text_color = cookable ? TEXT_BASE : TEXT_DISABLED

      lines.each_with_index do |line, i|
        pbDrawTextPositions(
          overlay,
          [[
            line,
            text_x,
            text_y + (i * line_height),
            :left,
            text_color,
            TEXT_SHADOW
          ]]
        )
      end

      pbSetSystemFont(overlay)
    end

    def draw_recipe_card_icon(overlay, recipe, x, y, cookable = true)
      placeholder = "Graphics/UI/Cooking/Meals/000"

      # Use the recipe's defined sprite if one exists.
      # Otherwise, fall back to the placeholder.
      sprite_name = recipe.sprite

      if sprite_name && !sprite_name.empty?
        filename = "Graphics/UI/Cooking/Meals/#{sprite_name}"

        if !pbResolveBitmap(filename)
          filename = placeholder
        end
      else
        filename = placeholder
      end

      # If even the placeholder is missing, don't crash the Recipe screen.
      return if !pbResolveBitmap(filename)

      icon = AnimatedBitmap.new(filename)
      bitmap = icon.bitmap

      source_width  = bitmap.width
      source_height = bitmap.height

      scale = [
        MEAL_ICON_SIZE.to_f / source_width,
        MEAL_ICON_SIZE.to_f / source_height
      ].min

      draw_width  = (source_width * scale).round
      draw_height = (source_height * scale).round

      # Preserve the game's 2x2 pixel alignment.
      draw_width  -= draw_width % 2
      draw_height -= draw_height % 2

      draw_x = x + ((MEAL_ICON_SIZE - draw_width) / 2)
      draw_y = y + ((MEAL_ICON_SIZE - draw_height) / 2)

      draw_x -= draw_x % 2
      draw_y -= draw_y % 2

      opacity = cookable ? 255 : 112

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
        ),
        opacity
      )

      icon.dispose
    end

    #---------------------------------------------------------------------------

    def draw_no_recipes(overlay)
      drawFormattedTextEx(
        overlay,
        INFO_X,
        110,
        INFO_WIDTH,
        "<ac>#{_INTL("You haven't learned any recipes yet.")}</ac>",
        TEXT_BASE,
        TEXT_SHADOW
      )
    end

    #---------------------------------------------------------------------------

    def draw_ingredients_page(overlay, recipe)
      pbDrawTextPositions(
        overlay,
        [[
          recipe.name,
          INFO_CENTER,
          INFO_Y,
          :center,
          TEXT_BASE,
          TEXT_SHADOW
        ]]
      )

      required_ingredients = recipe.required_ingredients || []
      optional_ingredients = recipe.optional_ingredients || []

      required_condiments = recipe.required_condiments || []
      optional_condiments = recipe.optional_condiments || []

      ingredient_checks = recipe_slot_availability(
        required_ingredients,
        optional_ingredients
      )

      condiment_checks = recipe_slot_availability(
        required_condiments,
        optional_condiments
      )

      draw_combined_recipe_slot_section(
        overlay,
        _INTL("Ingredients"),
        required_ingredients,
        optional_ingredients,
        ingredient_checks[0],
        ingredient_checks[1],
        86
      )

      draw_combined_recipe_slot_section(
        overlay,
        _INTL("Condiments"),
        required_condiments,
        optional_condiments,
        condiment_checks[0],
        condiment_checks[1],
        170
      )

      pbSetSmallFont(overlay)

      drawFormattedTextEx(
        overlay,
        INFO_X,
        266,
        INFO_WIDTH,
        "<ac>#{_INTL("Meal Powers vary with the ingredients used.")}</ac>",
        TEXT_BASE,
        TEXT_SHADOW
      )

      pbSetSystemFont(overlay)
    end

    def draw_combined_recipe_slot_section(
      overlay,
      title,
      required_slots,
      optional_slots,
      required_checks,
      optional_checks,
      y
    )
      required_slots = required_slots || []
      optional_slots = optional_slots || []

      pbDrawTextPositions(
        overlay,
        [[
          title,
          INFO_CENTER,
          y,
          :center,
          TEXT_BASE,
          TEXT_SHADOW
        ]]
      )

      # Each required recipe slot gets its own visible box.
      #
      # All optional definitions are represented by ONE optional box. That box
      # cycles through every item that is valid for any optional definition.
      visible_slot_count = required_slots.length
      visible_slot_count += 1 if !optional_slots.empty?

      if visible_slot_count <= 0
        pbDrawTextPositions(
          overlay,
          [[
            _INTL("None"),
            INFO_CENTER,
            y + 34,
            :center,
            TEXT_DISABLED,
            TEXT_SHADOW
          ]]
        )
        return
      end

      slot_size = SLOT_SIZE
      gap       = SLOT_GAP

      total_width = (visible_slot_count * slot_size) +
                    ((visible_slot_count - 1) * gap)

      start_x = INFO_CENTER - (total_width / 2)
      slot_y  = y + 30

      #---------------------------------------------------------------------------
      # Required slots
      #---------------------------------------------------------------------------
      required_slots.each_with_index do |slot, i|
        x = start_x + (i * (slot_size + gap))
        available = required_checks[i]

        draw_small_ingredient_box(
          overlay,
          x,
          slot_y,
          slot_size,
          title == _INTL("Condiments")
        )

        item_id = displayed_item_for_recipe_slot(
          slot,
          available
        )

        if item_id
          draw_recipe_item_icon(
            overlay,
            item_id,
            x,
            slot_y,
            slot_size
          )
        end

        draw_availability_mark(
          overlay,
          x,
          slot_y,
          slot_size,
          available
        )
      end

      #---------------------------------------------------------------------------
      # Combined Optional slot
      #---------------------------------------------------------------------------
      if !optional_slots.empty?
        x = start_x +
            (required_slots.length * (slot_size + gap))

        draw_optional_recipe_slot(
          overlay,
          optional_slots,
          x,
          slot_y,
          slot_size,
          title == _INTL("Condiments")
        )
      end
    end

    def draw_small_ingredient_box(
      overlay,
      x,
      y,
      slot_size,
      condiment = false
    )
      boxes = AnimatedBitmap.new(
        "Graphics/UI/Cooking/ingredient_box_small"
      )

      # Frame 0 = Ingredient
      # Frame 1 = Condiment
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

    def optional_items_for_slots(slots)
      items = []

      slots.each do |slot|
        items_for_slot(slot).each do |item_id|
          items.push(item_id) if !items.include?(item_id)
        end
      end

      items.sort_by! do |item_id|
        GameData::Item.get(item_id).name
      end

      return items
    end

    def draw_optional_recipe_slot(
      overlay,
      optional_slots,
      x,
      y,
      slot_size,
      condiment = false
    )
      draw_small_ingredient_box(
        overlay,
        x,
        y,
        slot_size,
        condiment
      )

      items = optional_items_for_slots(optional_slots)
      return if items.empty?

      # Optional slots advertise ALL valid possibilities, not merely the ones
      # currently owned.
      item_id = items[@group_cycle_index % items.length]

      draw_recipe_item_icon(
        overlay,
        item_id,
        x,
        y,
        slot_size
      )
    end

    #---------------------------------------------------------------------------

    def draw_recipe_slot_section(overlay, title, slots, checks, y)
      pbDrawTextPositions(
        overlay,
        [[
          title,
          INFO_CENTER,
          y,
          :center,
          TEXT_BASE,
          TEXT_SHADOW
        ]]
      )

      if !slots || slots.empty?
        pbDrawTextPositions(
          overlay,
          [[
            _INTL("None"),
            INFO_CENTER,
            y + 34,
            :center,
            TEXT_DISABLED,
            TEXT_SHADOW
          ]]
        )
        return
      end

      slot_size = SLOT_SIZE
      gap       = SLOT_GAP

      total_width = (slots.length * slot_size) +
                    ((slots.length - 1) * gap)

      start_x = INFO_CENTER - (total_width / 2)
      slot_y  = y + 30

      slots.each_with_index do |slot, i|
        x = start_x + (i * (slot_size + gap))

        overlay.fill_rect(
          x,
          slot_y,
          slot_size,
          slot_size,
          Color.new(72, 88, 104)
        )

        item_id = displayed_item_for_slot(slot)

        if item_id
          draw_recipe_item_icon(
            overlay,
            item_id,
            x,
            slot_y,
            slot_size
          )
        end

        draw_availability_mark(
          overlay,
          x,
          slot_y,
          slot_size,
          checks[i]
        )
      end
    end

    #---------------------------------------------------------------------------

    def draw_recipe_item_icon(overlay, item_id, x, y, slot_size)
      icon   = AnimatedBitmap.new(GameData::Item.icon_filename(item_id))
      bitmap = icon.bitmap

      source_width  = bitmap.width
      source_height = bitmap.height

      # Same 2x pixel-density handling as Creative Mode's small tray.
      draw_width  = source_width / 2
      draw_height = source_height / 2

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

    def draw_availability_mark(overlay, x, y, slot_size, available)
      icon = AnimatedBitmap.new("Graphics/UI/Cooking/icon_check_x")

      # Frame 0 = Check Mark
      # Frame 1 = X Mark
      source_x = available ? 0 : 16

      # Centre the mark over the bottom-right corner of the slot.
      #
      # The X's central 2x2 pixel is at source pixels 20-21, 4-5.
      # Relative to frame 1, that's x=4-5, y=4-5.
      target_center_x = x + slot_size - 4
      target_center_y = y + slot_size - 4

      draw_x = target_center_x - 8
      draw_y = target_center_y - 8

      overlay.blt(
        draw_x,
        draw_y,
        icon.bitmap,
        Rect.new(source_x, 0, 16, 12)
      )

      icon.dispose
    end

    #---------------------------------------------------------------------------

    def draw_description_page(overlay, recipe)
      pbDrawTextPositions(
        overlay,
        [[
          recipe.name,
          INFO_CENTER,
          INFO_Y,
          :center,
          TEXT_BASE,
          TEXT_SHADOW
        ]]
      )

      description = recipe.description

      if !description || description.empty?
        description = _INTL("No description has been written for this recipe.")
      end

      # Use the same small font as the Pause Menu's date/time and HUD text.
      pbSetSmallFont(overlay)

      drawFormattedTextEx(
        overlay,
        INFO_X,
        100,
        INFO_WIDTH,
        "<ac>#{description}</ac>",
        TEXT_BASE,
        TEXT_SHADOW
      )

      # Restore the normal UI font so this doesn't affect anything drawn afterward.
      pbSetSystemFont(overlay)
    end

    #---------------------------------------------------------------------------

    def draw_controls(overlay)
      controls = [
        _INTL("Use: Select"),
        _INTL("Back: Exit"),
        _INTL(
          "{1}: {2}",
          Keybinds.button_name(:special),
          @page == :INGREDIENTS ? _INTL("Description") : _INTL("Ingredients")
        )
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

  #=============================================================================
  # Recipe Mode entry point
  #=============================================================================

  def self.open_recipes
    scene = Cooking::RecipeScene.new

    pbFadeOutIn do
      scene.pbStartScene
      scene.pbMain
      scene.pbEndScene
    end

    return true
  end
end