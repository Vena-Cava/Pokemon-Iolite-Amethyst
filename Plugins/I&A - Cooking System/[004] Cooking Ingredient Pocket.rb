#===============================================================================
# I&A - Cooking System
# Cooking Ingredients Bag Pocket
#===============================================================================

module Settings
  COOKING_INGREDIENT_BAG_POCKET_NAME = _INTL("Cooking Ingredients")
  COOKING_INGREDIENT_BAG_POCKET      = 11

  #-----------------------------------------------------------------------------
  # Preserve all existing Bag pockets, including custom ones added by other
  # plugins, then append Cooking Ingredients.
  #-----------------------------------------------------------------------------
  Settings.singleton_class.alias_method(
    :ia_cooking_original_bag_pocket_names,
    :bag_pocket_names
  )

  def self.bag_pocket_names
    names = ia_cooking_original_bag_pocket_names.clone

    pocket_index = COOKING_INGREDIENT_BAG_POCKET - 1

    if pocket_index >= names.length
      names.push(nil) while names.length <= pocket_index
    end

    names[pocket_index] = COOKING_INGREDIENT_BAG_POCKET_NAME

    return names
  end

  #-----------------------------------------------------------------------------
  # Convenience getter.
  #-----------------------------------------------------------------------------
  def self.get_cooking_ingredient_pocket
    bag_pocket_names.each_with_index do |name, i|
      next if name != COOKING_INGREDIENT_BAG_POCKET_NAME
      return i + 1
    end

    return COOKING_INGREDIENT_BAG_POCKET
  end

  #-----------------------------------------------------------------------------
  # Ensure Essentials' pocket settings arrays actually contain an entry for
  # Pocket 11.
  #
  # Using while here is intentional. Some of the existing custom-pocket code
  # checks the length of BAG_MAX_POCKET_SIZE after already modifying it, which
  # can leave BAG_POCKET_AUTO_SORT one entry short.
  #-----------------------------------------------------------------------------
  while BAG_MAX_POCKET_SIZE.length < COOKING_INGREDIENT_BAG_POCKET
    BAG_MAX_POCKET_SIZE.push(-1)
  end

  while BAG_POCKET_AUTO_SORT.length < COOKING_INGREDIENT_BAG_POCKET
    BAG_POCKET_AUTO_SORT.push(true)
  end
end