#===============================================================================
# I&A - Cooking System
# Recipe Matcher
#===============================================================================

module Cooking
  module RecipeMatcher
    module_function

    #===========================================================================
    # Public methods
    #===========================================================================

    #---------------------------------------------------------------------------
    # Returns whether the selected Ingredients and Condiments form this exact
    # recipe.
    #
    # Each entry in ingredient_items/condiment_items represents one physical
    # copy of an item. Duplicate IDs are therefore meaningful.
    #
    # Examples:
    #   [:WHITEFLOUR, :TOMATO, :MOZZARELLA]
    #   [:SALT, :OLIVEOIL]
    #---------------------------------------------------------------------------
    def matches?(recipe, ingredient_items, condiment_items)
      recipe = GameData::CookingRecipe.get(recipe) unless recipe.is_a?(
        GameData::CookingRecipe
      )

      ingredient_items = normalize_item_list(ingredient_items)
      condiment_items  = normalize_item_list(condiment_items)

      return false unless valid_selected_items?(
        ingredient_items,
        :INGREDIENT
      )

      return false unless valid_selected_items?(
        condiment_items,
        :CONDIMENT
      )

      ingredient_slots = build_slots(
        recipe.required_ingredients,
        recipe.optional_ingredients
      )

      condiment_slots = build_slots(
        recipe.required_condiments,
        recipe.optional_condiments
      )

      return false unless match_slot_set?(
        ingredient_items,
        ingredient_slots
      )

      return false unless match_slot_set?(
        condiment_items,
        condiment_slots
      )

      return true
    end

    #---------------------------------------------------------------------------
    # Returns the highest-tier matching recipe in a particular recipe family.
    #
    # Returns nil if no recipe in the family matches.
    #---------------------------------------------------------------------------
    def match_family(family, ingredient_items, condiment_items)
      family = normalize_symbol(family)

      recipes = []

      GameData::CookingRecipe.each do |recipe|
        next unless recipe.family == family
        recipes.push(recipe)
      end

      recipes.sort_by! { |recipe| -recipe.tier_value }

      recipes.each do |recipe|
        return recipe if matches?(
          recipe,
          ingredient_items,
          condiment_items
        )
      end

      return nil
    end

    #---------------------------------------------------------------------------
    # Returns every recipe that matches the selected items.
    #
    # Recipes are returned from highest tier to lowest tier.
    #---------------------------------------------------------------------------
    def matching_recipes(ingredient_items, condiment_items)
      matches = []

      GameData::CookingRecipe.each do |recipe|
        next unless matches?(
          recipe,
          ingredient_items,
          condiment_items
        )

        matches.push(recipe)
      end

      matches.sort_by! do |recipe|
        [
          -recipe.tier_value,
          recipe.family.to_s,
          recipe.name
        ]
      end

      return matches
    end

    #---------------------------------------------------------------------------
    # Returns the highest-tier matching recipe from all recipe families.
    #
    # If several recipes of the same tier happen to match, this returns the
    # first one in the normal compiled recipe order. For normal cooking, recipe
    # families should be sufficiently distinct that this is unambiguous.
    #---------------------------------------------------------------------------
    def best_match(ingredient_items, condiment_items)
      matches = matching_recipes(
        ingredient_items,
        condiment_items
      )

      return nil if matches.empty?
      return matches[0]
    end

    #===========================================================================
    # Slot matching
    #===========================================================================

    #---------------------------------------------------------------------------
    # Combines required and optional recipe slots into a single working array.
    #
    # A required slot must be occupied for the recipe to match.
    # An optional slot may be occupied, but does not need to be.
    #---------------------------------------------------------------------------
    def build_slots(required_slots, optional_slots)
      ret = []

      required_slots.each do |slot|
        ret.push({
          :type     => slot[:type],
          :id       => slot[:id],
          :required => true
        })
      end

      optional_slots.each do |slot|
        ret.push({
          :type     => slot[:type],
          :id       => slot[:id],
          :required => false
        })
      end

      return ret
    end

    #---------------------------------------------------------------------------
    # Determines whether all selected item copies can be assigned to unique
    # recipe slots while also filling every required slot.
    #
    # This intentionally uses backtracking rather than a greedy match.
    #
    # Example:
    #   Group A = Cheese A, Cheese B
    #   Group B = Cheese B
    #
    # If Cheese A and Cheese B are selected, a greedy matcher could waste
    # Cheese B on Group A and then incorrectly fail Group B.
    #
    # Backtracking can instead assign:
    #   Cheese A -> Group A
    #   Cheese B -> Group B
    #---------------------------------------------------------------------------
    def match_slot_set?(selected_items, slots)
      required_count = slots.count { |slot| slot[:required] }

      # There aren't enough selected items to fill all required slots.
      return false if selected_items.length < required_count

      # There are more selected items than the recipe has total available slots.
      return false if selected_items.length > slots.length

      used_slots = Array.new(slots.length, false)

      # Match the most constrained selected items first. This isn't required
      # for correctness, but greatly reduces unnecessary backtracking.
      ordered_items = selected_items.sort_by do |item_id|
        matching_slot_count(item_id, slots)
      end

      return assign_selected_items(
        ordered_items,
        0,
        slots,
        used_slots
      )
    end

    #---------------------------------------------------------------------------
    # Recursive backtracking assignment.
    #---------------------------------------------------------------------------
    def assign_selected_items(selected_items, item_index, slots, used_slots)
      # Every selected item has been assigned.
      if item_index >= selected_items.length
        # The recipe only matches if every required slot is filled.
        slots.each_with_index do |slot, index|
          next unless slot[:required]
          return false unless used_slots[index]
        end

        return true
      end

      item_id = selected_items[item_index]

      slots.each_with_index do |slot, slot_index|
        next if used_slots[slot_index]
        next unless item_matches_slot?(item_id, slot)

        used_slots[slot_index] = true

        if assign_selected_items(
          selected_items,
          item_index + 1,
          slots,
          used_slots
        )
          return true
        end

        used_slots[slot_index] = false
      end

      return false
    end

    #---------------------------------------------------------------------------
    # Returns how many slots a selected item could potentially occupy.
    #---------------------------------------------------------------------------
    def matching_slot_count(item_id, slots)
      count = 0

      slots.each do |slot|
        count += 1 if item_matches_slot?(item_id, slot)
      end

      return count
    end

    #---------------------------------------------------------------------------
    # Determines whether one item copy can satisfy one recipe slot.
    #---------------------------------------------------------------------------
    def item_matches_slot?(item_id, slot)
      case slot[:type]
      when :ITEM
        return item_id == slot[:id]

      when :GROUP
        group = GameData::IngredientGroup.try_get(slot[:id])
        return false unless group

        return group.includes?(item_id)
      end

      return false
    end

    #===========================================================================
    # Selection validation/helpers
    #===========================================================================

    def normalize_item_list(items)
      return [] if !items

      return items.map do |item|
        if item.respond_to?(:id)
          item.id
        else
          normalize_symbol(item)
        end
      end
    end

    def normalize_symbol(value)
      return value if value.is_a?(Symbol)
      return value.to_s.upcase.to_sym
    end

    #---------------------------------------------------------------------------
    # Ensures that everything passed to the matcher really is a cooking
    # Ingredient/Condiment of the expected category.
    #---------------------------------------------------------------------------
    def valid_selected_items?(items, expected_type)
      items.each do |item_id|
        data = GameData::Ingredient.try_get(item_id)
        return false unless data

        case expected_type
        when :INGREDIENT
          return false unless data.ingredient?
        when :CONDIMENT
          return false unless data.condiment?
        end
      end

      return true
    end
  end
end