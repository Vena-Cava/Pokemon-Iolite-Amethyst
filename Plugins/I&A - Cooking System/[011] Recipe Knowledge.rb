#===============================================================================
# I&A - Cooking System
# Recipe Knowledge
#===============================================================================

module Cooking
  #=============================================================================
  # Save data
  #=============================================================================

  #-----------------------------------------------------------------------------
  # Returns the player's permanently learned Cooking Recipe IDs.
  #
  # This is stored directly on $PokemonGlobal, which is already part of the
  # normal Pokémon Essentials save data.
  #-----------------------------------------------------------------------------
  def self.learned_recipes
    return [] if !$PokemonGlobal

    recipes = $PokemonGlobal.instance_variable_get(:@cooking_learned_recipes)

    if !recipes.is_a?(Array)
      recipes = []
      $PokemonGlobal.instance_variable_set(
        :@cooking_learned_recipes,
        recipes
      )
    end

    return recipes
  end

  #=============================================================================
  # Recipe lookup helpers
  #=============================================================================

  def self.normalize_recipe_id(recipe)
    return recipe.id if recipe.is_a?(GameData::CookingRecipe)
    return recipe if recipe.is_a?(Symbol)
    return recipe.to_s.upcase.to_sym
  end

  def self.normalize_family_id(family)
    return family.family if family.is_a?(GameData::CookingRecipe)
    return family if family.is_a?(Symbol)
    return family.to_s.upcase.to_sym
  end

  #-----------------------------------------------------------------------------
  # Returns all recipes belonging to a family, ordered from Base upward.
  #-----------------------------------------------------------------------------
  def self.recipes_in_family(family)
    family = normalize_family_id(family)
    recipes = []

    GameData::CookingRecipe.each do |recipe|
      next unless recipe.family == family
      recipes.push(recipe)
    end

    recipes.sort_by!(&:tier_value)
    return recipes
  end

  #=============================================================================
  # Knowledge checks
  #=============================================================================

  #-----------------------------------------------------------------------------
  # Returns whether the player knows this recipe.
  #
  # Default recipes are always considered known and do not need to be stored in
  # the save file.
  #-----------------------------------------------------------------------------
  def self.recipe_known?(recipe)
    recipe_id = normalize_recipe_id(recipe)
    recipe_data = GameData::CookingRecipe.try_get(recipe_id)

    return false if !recipe_data
    return true if recipe_data.default?

    return learned_recipes.include?(recipe_id)
  end

  #-----------------------------------------------------------------------------
  # Returns every recipe currently known by the player.
  #-----------------------------------------------------------------------------
  def self.known_recipes
    ret = []

    GameData::CookingRecipe.each do |recipe|
      ret.push(recipe) if recipe_known?(recipe)
    end

    ret.sort_by! do |recipe|
      [
        recipe.family.to_s,
        recipe.tier_value,
        recipe.name
      ]
    end

    return ret
  end

  #-----------------------------------------------------------------------------
  # Returns every recipe the player has not yet learned.
  #-----------------------------------------------------------------------------
  def self.unknown_recipes
    ret = []

    GameData::CookingRecipe.each do |recipe|
      ret.push(recipe) unless recipe_known?(recipe)
    end

    ret.sort_by! do |recipe|
      [
        recipe.family.to_s,
        recipe.tier_value,
        recipe.name
      ]
    end

    return ret
  end

  #=============================================================================
  # Learning recipes
  #=============================================================================

  #-----------------------------------------------------------------------------
  # Teaches the player a recipe.
  #
  # By default, learning a higher-tier recipe also teaches every lower-tier
  # recipe in the same family.
  #
  # Examples:
  #
  #   Cooking.learn_recipe(:CHEESYPIZZA)
  #
  #   Cooking.learn_recipe(:ULTRACHEESYPIZZA)
  #     -> teaches Base, Great and Ultra
  #
  # To teach ONLY the exact recipe:
  #
  #   Cooking.learn_recipe(:ULTRACHEESYPIZZA, false)
  #
  # Returns an Array containing the IDs that were newly learned.
  #-----------------------------------------------------------------------------
  def self.learn_recipe(recipe, include_lower_tiers = true)
    recipe_id = normalize_recipe_id(recipe)
    recipe_data = GameData::CookingRecipe.try_get(recipe_id)

    return [] if !recipe_data

    recipes_to_learn = [recipe_data]

    if include_lower_tiers
      recipes_to_learn = recipes_in_family(recipe_data.family).select do |other|
        other.tier_value <= recipe_data.tier_value
      end
    end

    newly_learned = []

    recipes_to_learn.each do |other|
      # Default recipes are already known automatically.
      next if other.default?

      # Don't add duplicates.
      next if learned_recipes.include?(other.id)

      learned_recipes.push(other.id)
      newly_learned.push(other.id)
    end

    return newly_learned
  end

  #-----------------------------------------------------------------------------
  # Creative Mode discovery.
  #
  # Every Cooking Recipe is discoverable through experimentation, regardless
  # of its UnlockMethod.
  #
  # Discovering a higher tier also teaches all lower tiers in that family.
  #-----------------------------------------------------------------------------
  def self.discover_recipe(recipe)
    return learn_recipe(recipe, true)
  end

  #-----------------------------------------------------------------------------
  # Teaches every recipe in a family.
  #
  # Useful for NPCs, recipe books, quest rewards, debug events, etc.
  #
  # Example:
  #   Cooking.learn_recipe_family(:CHEESY_PIZZA)
  #
  # Returns an Array containing the IDs that were newly learned.
  #-----------------------------------------------------------------------------
  def self.learn_recipe_family(family)
    family = normalize_family_id(family)
    newly_learned = []

    recipes_in_family(family).each do |recipe|
      learned = learn_recipe(recipe, false)
      newly_learned.concat(learned)
    end

    return newly_learned
  end

  #-----------------------------------------------------------------------------
  # Teaches every Cooking Recipe.
  #
  # Mostly useful for Debug Mode.
  #-----------------------------------------------------------------------------
  def self.learn_all_recipes
    newly_learned = []

    GameData::CookingRecipe.each do |recipe|
      learned = learn_recipe(recipe, false)
      newly_learned.concat(learned)
    end

    return newly_learned
  end

  #=============================================================================
  # Forgetting recipes
  #=============================================================================

  #-----------------------------------------------------------------------------
  # Removes one learned recipe from the player's saved knowledge.
  #
  # Default recipes cannot truly be forgotten because recipe_known? always
  # considers them known.
  #
  # Returns true if a stored recipe was removed.
  #-----------------------------------------------------------------------------
  def self.forget_recipe(recipe)
    recipe_id = normalize_recipe_id(recipe)

    index = learned_recipes.index(recipe_id)
    return false if !index

    learned_recipes.delete_at(index)
    return true
  end

  #-----------------------------------------------------------------------------
  # Removes all learned recipes in a family.
  #-----------------------------------------------------------------------------
  def self.forget_recipe_family(family)
    family = normalize_family_id(family)
    removed = []

    recipes_in_family(family).each do |recipe|
      if forget_recipe(recipe)
        removed.push(recipe.id)
      end
    end

    return removed
  end

  #-----------------------------------------------------------------------------
  # Clears all stored recipe knowledge.
  #
  # Default recipes will still count as known.
  #-----------------------------------------------------------------------------
  def self.forget_all_recipes
    count = learned_recipes.length
    learned_recipes.clear
    return count
  end
end