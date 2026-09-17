#===============================================================================
# I&A - Cooking System
# Cooking Recipe compiler
#===============================================================================

module Compiler
  #-----------------------------------------------------------------------------
  # Parses one cooking recipe slot.
  #
  # Examples:
  #   Item:TOMATO
  #   Group:PIZZA_CHEESE
  #   Item:MEATBALLS*2
  #   Group:PIZZA_CHEESE*2
  #
  # Returns:
  #   {
  #     :type     => :ITEM or :GROUP,
  #     :id       => Symbol,
  #     :quantity => Integer
  #   }
  #-----------------------------------------------------------------------------
  def self.parse_cooking_recipe_slot(value, expected_slot_type)
    text = value.to_s.strip

    if text.empty?
      raise _INTL("A cooking recipe slot cannot be blank.")
    end

    quantity = 1

    if text =~ /\A(.+)\*(\d+)\z/
      text     = $1.strip
      quantity = $2.to_i
    end

    if quantity <= 0
      raise _INTL(
        "Cooking recipe slot \"{1}\" has an invalid quantity of {2}.",
        value,
        quantity
      )
    end

    slot_type = nil
    slot_id   = nil

    if text =~ /\AItem:(.+)\z/i
      slot_type = :ITEM
      slot_id   = $1.strip.to_sym
    elsif text =~ /\AGroup:(.+)\z/i
      slot_type = :GROUP
      slot_id   = $1.strip.to_sym
    else
      raise _INTL(
        "Cooking recipe slot \"{1}\" must begin with Item: or Group:.",
        value
      )
    end

    case slot_type
    when :ITEM
      unless GameData::Ingredient.exists?(slot_id)
        raise _INTL(
          "Cooking recipe slot \"{1}\" refers to ingredient {2}, which does not exist in ingredients.txt.",
          value,
          slot_id
        )
      end

      ingredient = GameData::Ingredient.get(slot_id)

      if expected_slot_type == :INGREDIENT && !ingredient.ingredient?
        raise _INTL(
          "Cooking recipe slot \"{1}\" uses {2}, but that item is a Condiment rather than an Ingredient.",
          value,
          slot_id
        )
      elsif expected_slot_type == :CONDIMENT && !ingredient.condiment?
        raise _INTL(
          "Cooking recipe slot \"{1}\" uses {2}, but that item is an Ingredient rather than a Condiment.",
          value,
          slot_id
        )
      end

    when :GROUP
      unless GameData::IngredientGroup.exists?(slot_id)
        raise _INTL(
          "Cooking recipe slot \"{1}\" refers to Ingredient Group {2}, which does not exist in ingredient_groups.txt.",
          value,
          slot_id
        )
      end

      group = GameData::IngredientGroup.get(slot_id)

      if expected_slot_type == :INGREDIENT && !group.ingredient?
        raise _INTL(
          "Cooking recipe slot \"{1}\" uses Ingredient Group {2}, but that group contains Condiments.",
          value,
          slot_id
        )
      elsif expected_slot_type == :CONDIMENT && !group.condiment?
        raise _INTL(
          "Cooking recipe slot \"{1}\" uses Ingredient Group {2}, but that group contains Ingredients.",
          value,
          slot_id
        )
      end
    end

    return {
      :type     => slot_type,
      :id       => slot_id,
      :quantity => quantity
    }
  end

  #-----------------------------------------------------------------------------
  # Parses an array of recipe slot strings.
  #-----------------------------------------------------------------------------
  def self.parse_cooking_recipe_slots(values, expected_slot_type)
    return [] if !values

    ret = []

    values.each do |value|
      slot = parse_cooking_recipe_slot(value, expected_slot_type)

      slot[:quantity].times do
        ret << {
          :type     => slot[:type],
          :id       => slot[:id],
          :quantity => 1
        }
      end
    end

    return ret
  end

  #-----------------------------------------------------------------------------
  # Validates one compiled CookingRecipe entry.
  #-----------------------------------------------------------------------------
  def self.validate_cooking_recipe(hash)
    recipe_id = hash[:id]

        #-------------------------------------------------------------------------
        # Normalize symbolic PBS values.
        #
        # The generic PBS compiler preserves the capitalization written in the
        # PBS, e.g. "Base", "MainCourse" and "CreativeMode". Internally, the
        # Cooking System uses uppercase Symbols consistently.
        #-------------------------------------------------------------------------
        hash[:family] = hash[:family].to_s.upcase.to_sym if hash[:family]
        hash[:tier] = hash[:tier].to_s.upcase.to_sym if hash[:tier]
        hash[:category] = hash[:category].to_s.upcase.to_sym if hash[:category]
        hash[:unlock_method] = hash[:unlock_method].to_s.upcase.to_sym if hash[:unlock_method]

    if !hash[:real_name] || hash[:real_name].empty?
      raise _INTL(
        "Cooking recipe {1} has no Name.",
        recipe_id
      )
    end

    #-------------------------------------------------------------------------
    # Family
    #-------------------------------------------------------------------------
    hash[:family] ||= recipe_id

    #-------------------------------------------------------------------------
    # Tier
    #-------------------------------------------------------------------------
    hash[:tier] ||= :BASE
    unless GameData::CookingRecipe::TIER_ORDER.key?(hash[:tier])
      raise _INTL(
        "Cooking recipe {1} has invalid Tier {2}. Valid tiers are Base, Great, Ultra and Master.",
        recipe_id,
        hash[:tier]
      )
    end

    #-------------------------------------------------------------------------
    # Category
    #-------------------------------------------------------------------------
    hash[:category] ||= :MAINCOURSE

    unless GameData::CookingRecipe::CATEGORIES.include?(hash[:category])
      raise _INTL(
        "Cooking recipe {1} has invalid Category {2}.",
        recipe_id,
        hash[:category]
      )
    end

    #-------------------------------------------------------------------------
    # Recipe slots
    #-------------------------------------------------------------------------
    hash[:required_ingredients] = parse_cooking_recipe_slots(
      hash[:required_ingredients],
      :INGREDIENT
    )

    hash[:optional_ingredients] = parse_cooking_recipe_slots(
      hash[:optional_ingredients],
      :INGREDIENT
    )

    hash[:required_condiments] = parse_cooking_recipe_slots(
      hash[:required_condiments],
      :CONDIMENT
    )

    hash[:optional_condiments] = parse_cooking_recipe_slots(
      hash[:optional_condiments],
      :CONDIMENT
    )

    #-------------------------------------------------------------------------
    # Limits
    #-------------------------------------------------------------------------
    required_ingredient_count = hash[:required_ingredients].length
    optional_ingredient_count = hash[:optional_ingredients].length
    required_condiment_count  = hash[:required_condiments].length
    optional_condiment_count  = hash[:optional_condiments].length

    if required_ingredient_count > 6
      raise _INTL(
        "Cooking recipe {1} requires {2} Ingredients, but a recipe can require at most 6.",
        recipe_id,
        required_ingredient_count
      )
    end

    if required_condiment_count > 4
      raise _INTL(
        "Cooking recipe {1} requires {2} Condiments, but a recipe can require at most 4.",
        recipe_id,
        required_condiment_count
      )
    end

    minimum_total = required_ingredient_count + required_condiment_count

    if minimum_total < 2
      raise _INTL(
        "Cooking recipe {1} requires only {2} total items. A recipe must require at least 2.",
        recipe_id,
        minimum_total
      )
    end

    if minimum_total > 10
      raise _INTL(
        "Cooking recipe {1} requires {2} total items, but a recipe can use at most 10.",
        recipe_id,
        minimum_total
      )
    end

    #-------------------------------------------------------------------------
    # Ensure the optional slots can never exceed the cooking UI limits.
    #
    # Optional slots are allowed to provide choices beyond the hard cap.
    # For example, a recipe may have several possible optional additions even
    # though the player can only select up to 6 Ingredients and 4 Condiments.
    #
    # Therefore we intentionally do NOT reject a recipe merely because:
    #
    #   required + optional > maximum
    #
    # The cooking UI/matcher will enforce the actual selected-item cap.
    #-------------------------------------------------------------------------

    return hash
  end

  #-----------------------------------------------------------------------------
  # Compile cooking_recipes.txt
  #-----------------------------------------------------------------------------
  def self.compile_cooking_recipes(*paths)
    compile_PBS_file_generic(GameData::CookingRecipe, *paths) do |final_validate, hash|
      validate_cooking_recipe(hash) if !final_validate
    end
  end
end

#===============================================================================
# Hook Cooking Recipes into the normal PBS compilation process.
#===============================================================================

module Compiler
  class << self
    unless method_defined?(:ia_cooking_compile_pbs_files_without_recipes)
      alias ia_cooking_compile_pbs_files_without_recipes compile_pbs_files
    end

    def compile_pbs_files
      ia_cooking_compile_pbs_files_without_recipes

      text_files = get_all_pbs_files_to_compile
      recipe_files = text_files[:CookingRecipe]

      if recipe_files && recipe_files[1] && recipe_files[1].length > 0
        compile_cooking_recipes(*recipe_files[1])
      end
    end
  end
end

#===============================================================================
# Cooking Recipe Debug Viewer
#===============================================================================

MenuHandlers.add(:debug_menu, :cooking_recipe_test, {
  "name"        => _INTL("Test Cooking Recipe"),
  "parent"      => :items_menu,
  "description" => _INTL("View the compiled data for a cooking recipe."),
  "effect"      => proc {
    recipes = []

    GameData::CookingRecipe.each do |recipe|
      recipes.push(recipe)
    end

    if recipes.empty?
      pbMessage(_INTL("No Cooking Recipes are defined."))
      next false
    end

    recipes.sort_by! do |recipe|
      [
        recipe.family.to_s,
        recipe.tier_value,
        recipe.name
      ]
    end

    commands = recipes.map do |recipe|
      _INTL("{1} [{2}]", recipe.name, recipe.tier)
    end

    commands.push(_INTL("Cancel"))

    choice = pbMessage(
      _INTL("Choose a Cooking Recipe."),
      commands,
      commands.length - 1
    )

    next false if choice < 0 || choice >= recipes.length

    recipe = recipes[choice]

    pbMessage(_INTL(
      "{1}\nID: {2}\nFamily: {3}\nTier: {4}\nCategory: {5}",
      recipe.name,
      recipe.id,
      recipe.family,
      recipe.tier,
      recipe.category
    ))

    pbMessage(_INTL(
      "Default Recipe: {1}\nUnlock Method: {2}\nSprite: {3}",
      recipe.default? ? "Yes" : "No",
      recipe.unlock_method || "None",
      recipe.sprite || "None"
    ))

    format_slot = proc do |slot|
      case slot[:type]
      when :ITEM
        item = GameData::Item.try_get(slot[:id])
        item_name = item ? item.name : slot[:id].to_s
        "Item: #{item_name} [#{slot[:id]}]"
      when :GROUP
        group = GameData::IngredientGroup.try_get(slot[:id])
        group_name = group ? group.name : slot[:id].to_s
        "Group: #{group_name} [#{slot[:id]}]"
      else
        "Unknown: #{slot.inspect}"
      end
    end

    required_ingredients = recipe.required_ingredients.map do |slot|
      format_slot.call(slot)
    end

    optional_ingredients = recipe.optional_ingredients.map do |slot|
      format_slot.call(slot)
    end

    required_condiments = recipe.required_condiments.map do |slot|
      format_slot.call(slot)
    end

    optional_condiments = recipe.optional_condiments.map do |slot|
      format_slot.call(slot)
    end

    pbMessage(_INTL(
      "Required Ingredients ({1}):\n{2}",
      required_ingredients.length,
      required_ingredients.empty? ? "None" : required_ingredients.join("\n")
    ))

    pbMessage(_INTL(
      "Optional Ingredients ({1}):\n{2}",
      optional_ingredients.length,
      optional_ingredients.empty? ? "None" : optional_ingredients.join("\n")
    ))

    pbMessage(_INTL(
      "Required Condiments ({1}):\n{2}",
      required_condiments.length,
      required_condiments.empty? ? "None" : required_condiments.join("\n")
    ))

    pbMessage(_INTL(
      "Optional Condiments ({1}):\n{2}",
      optional_condiments.length,
      optional_condiments.empty? ? "None" : optional_condiments.join("\n")
    ))

    if recipe.description && !recipe.description.empty?
      pbMessage(_INTL(
        "Description:\n{1}",
        recipe.description
      ))
    end

    next false
  }
})