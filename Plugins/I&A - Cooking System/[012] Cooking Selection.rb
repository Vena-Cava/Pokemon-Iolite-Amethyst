#===============================================================================
# I&A - Cooking System
# Cooking Selection
#
# Handles the player's temporary Ingredient/Condiment selections while cooking.
#
# Nothing is removed from the Bag here. Selected items are only "reserved"
# virtually until the final cooking confirmation.
#===============================================================================

module Cooking
  class Selection
    #===========================================================================
    # Limits
    #===========================================================================

    MIN_INGREDIENTS = 1
    MAX_INGREDIENTS = 6
    MAX_CONDIMENTS  = 4
    MIN_TOTAL       = 2
    MAX_TOTAL       = 10

    #===========================================================================
    # Read-only state
    #===========================================================================

    attr_reader :mode
    attr_reader :stage
    attr_reader :recipe
    attr_reader :selected_ingredients
    attr_reader :selected_condiments

    #===========================================================================
    # Setup
    #===========================================================================

    def initialize(mode = :CREATIVE, recipe = nil)
      @mode = mode.to_sym
      @recipe = recipe

      @selected_ingredients = []
      @selected_condiments  = []

      case @mode
      when :CREATIVE
        @stage = :INGREDIENTS
      when :RECIPE
        @stage = :INGREDIENTS
      else
        raise ArgumentError, "Unknown Cooking Selection mode: #{@mode}"
      end
    end

    #===========================================================================
    # Basic state
    #===========================================================================

    def creative?
      return @mode == :CREATIVE
    end

    def recipe?
      return @mode == :RECIPE
    end

    def choosing_ingredients?
      return @stage == :INGREDIENTS
    end

    def choosing_condiments?
      return @stage == :CONDIMENTS
    end

    def confirming?
      return @stage == :CONFIRM
    end

    def ingredient_count
      return @selected_ingredients.length
    end

    def condiment_count
      return @selected_condiments.length
    end

    def total_count
      return ingredient_count + condiment_count
    end

    #===========================================================================
    # Bag quantities
    #===========================================================================

    #---------------------------------------------------------------------------
    # Number of copies currently in the player's Bag.
    #---------------------------------------------------------------------------
    def bag_quantity(item)
      item = normalize_item_id(item)
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

    #---------------------------------------------------------------------------
    # Number of copies currently reserved by this selection.
    #---------------------------------------------------------------------------
    def reserved_quantity(item)
      item = normalize_item_id(item)
      return 0 if !item

      count = 0

      @selected_ingredients.each do |selected|
        count += 1 if selected == item
      end

      @selected_condiments.each do |selected|
        count += 1 if selected == item
      end

      return count
    end

    #---------------------------------------------------------------------------
    # Number of copies which may still be selected.
    #---------------------------------------------------------------------------
    def available_quantity(item)
      quantity = bag_quantity(item) - reserved_quantity(item)
      return [quantity, 0].max
    end

    def item_available?(item)
      return available_quantity(item) > 0
    end

    #===========================================================================
    # Available item lists
    #===========================================================================

    #---------------------------------------------------------------------------
    # All cooking Ingredients currently owned by the player.
    #
    # Items with every copy already reserved are omitted.
    #---------------------------------------------------------------------------
    def available_ingredients
      return available_items_for_category(:INGREDIENT)
    end

    #---------------------------------------------------------------------------
    # All cooking Condiments currently owned by the player.
    #
    # Items with every copy already reserved are omitted.
    #---------------------------------------------------------------------------
    def available_condiments
      return available_items_for_category(:CONDIMENT)
    end

    def available_items_for_category(category)
      ret = []

      GameData::Ingredient.each do |ingredient|
        next unless ingredient.category == category
        next unless available_quantity(ingredient.id) > 0
        ret.push(ingredient.id)
      end

      ret.sort_by! do |item_id|
        GameData::Item.get(item_id).name
      end

      return ret
    end

    #===========================================================================
    # Adding selections
    #===========================================================================

    def can_add?(item)
      item = normalize_item_id(item)
      return false if !item

      ingredient_data = GameData::Ingredient.try_get(item)
      return false if !ingredient_data
      return false if available_quantity(item) <= 0
      return false if total_count >= MAX_TOTAL

      if choosing_ingredients?
        return false unless ingredient_data.ingredient?
        return ingredient_count < MAX_INGREDIENTS
      end

      if choosing_condiments?
        return false unless ingredient_data.condiment?
        return condiment_count < MAX_CONDIMENTS
      end

      return false
    end

    #---------------------------------------------------------------------------
    # Adds one physical copy of an item.
    #
    # Returns true if successful.
    #
    # In Creative Mode:
    #   Ingredient #6 automatically advances to Condiments.
    #   Condiment #4 automatically advances to Confirmation.
    #---------------------------------------------------------------------------
    def add(item)
      item = normalize_item_id(item)
      return false unless can_add?(item)

      ingredient_data = GameData::Ingredient.get(item)

      if ingredient_data.ingredient?
        @selected_ingredients.push(item)

        if creative? && ingredient_count >= MAX_INGREDIENTS
          @stage = :CONDIMENTS
        end
      else
        @selected_condiments.push(item)

        if creative? && condiment_count >= MAX_CONDIMENTS
          @stage = :CONFIRM
        end
      end

      return true
    end

    #===========================================================================
    # Moving forward
    #===========================================================================

    #---------------------------------------------------------------------------
    # Can the player manually advance from the current stage?
    #---------------------------------------------------------------------------
    def can_continue?
      case @stage
      when :INGREDIENTS
        return ingredient_count >= MIN_INGREDIENTS

      when :CONDIMENTS
        return total_count >= MIN_TOTAL

      when :CONFIRM
        return can_cook?
      end

      return false
    end

    #---------------------------------------------------------------------------
    # Manually advances to the next stage.
    #
    # Ingredients -> Condiments
    # Condiments  -> Confirmation
    #
    # Returns true if the stage changed.
    #---------------------------------------------------------------------------
    def next_stage
      return false unless can_continue?

      case @stage
      when :INGREDIENTS
        @stage = :CONDIMENTS
        return true

      when :CONDIMENTS
        @stage = :CONFIRM
        return true
      end

      return false
    end

    #-----------------------------------------------------------------------------
    # Handles the Cooking screen's Special-key action.
    #
    # INGREDIENTS:
    #   Advances to Condiments if at least 1 Ingredient has been selected.
    #
    # CONDIMENTS:
    #   Advances to Confirmation if at least 2 total items have been selected.
    #
    # CONFIRM:
    #   Does nothing. Cooking requires an explicit confirmation with Use.
    #
    # Returns true if the stage changed.
    #-----------------------------------------------------------------------------
    def special
      return next_stage
    end

    #===========================================================================
    # Going back / undo
    #===========================================================================

    #---------------------------------------------------------------------------
    # Creative Mode Back behaviour:
    #
    # CONFIRM:
    #   Return to Condiments without removing anything.
    #
    # CONDIMENTS with Condiments selected:
    #   Remove the most recently selected Condiment.
    #
    # CONDIMENTS with no Condiments:
    #   Return to Ingredients AND remove the most recently selected Ingredient
    #   in the same action.
    #
    # INGREDIENTS with Ingredients selected:
    #   Remove the most recently selected Ingredient.
    #
    # INGREDIENTS with nothing selected:
    #   Return :EXIT so the UI knows to leave Creative Mode.
    #
    # Returns:
    #   :STAGE_CHANGED
    #   :REMOVED
    #   :EXIT
    #   :NONE
    #---------------------------------------------------------------------------
    def back
      if confirming?
        @stage = :CONDIMENTS

        if !@selected_condiments.empty?
          @selected_condiments.pop
          return :REMOVED
        end

        if !@selected_ingredients.empty?
          @stage = :INGREDIENTS
          @selected_ingredients.pop
          return :REMOVED
        end

        return :STAGE_CHANGED
      end

      if choosing_condiments?
        if !@selected_condiments.empty?
          @selected_condiments.pop
          return :REMOVED
        end

        if !@selected_ingredients.empty?
          @stage = :INGREDIENTS
          @selected_ingredients.pop
          return :REMOVED
        end

        @stage = :INGREDIENTS
        return :STAGE_CHANGED
      end

      if choosing_ingredients?
        if !@selected_ingredients.empty?
          @selected_ingredients.pop
          return :REMOVED
        end

        return :EXIT
      end

      return :NONE
    end

    #===========================================================================
    # Cooking / matcher
    #===========================================================================

    def can_cook?
      return false if ingredient_count < MIN_INGREDIENTS
      return false if ingredient_count > MAX_INGREDIENTS
      return false if condiment_count > MAX_CONDIMENTS
      return false if total_count < MIN_TOTAL
      return false if total_count > MAX_TOTAL

      # Make sure every reserved copy still exists in the Bag.
      all_selected_items.each do |item|
        return false if reserved_quantity(item) > bag_quantity(item)
      end

      return true
    end

    #---------------------------------------------------------------------------
    # Returns the highest matching Cooking Recipe, or nil.
    #---------------------------------------------------------------------------
    def matched_recipe
      return nil unless can_cook?

      return Cooking::RecipeMatcher.best_match(
        @selected_ingredients,
        @selected_condiments
      )
    end

    def all_selected_items
      return @selected_ingredients + @selected_condiments
    end

    #===========================================================================
    # Reset
    #===========================================================================

    def clear
      @selected_ingredients.clear
      @selected_condiments.clear
      @stage = :INGREDIENTS
    end

    #===========================================================================
    # Internal helpers
    #===========================================================================

    private

    def normalize_item_id(item)
      return item.id if item.respond_to?(:id)
      return item if item.is_a?(Symbol)

      if item.is_a?(String)
        return item.upcase.to_sym
      end

      return nil
    end
  end
end