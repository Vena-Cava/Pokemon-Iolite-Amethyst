#===============================================================================
# I&A - Cooking System
# Ingredient Group PBS Compiler
#===============================================================================

module Compiler
  module_function

  #=============================================================================
  # Compile Ingredient Group data
  #=============================================================================
  def compile_ingredient_groups(*paths)
    compile_PBS_file_generic(GameData::IngredientGroup, *paths) do |final_validate, hash|
      if final_validate
        validate_all_compiled_ingredient_groups
      else
        validate_compiled_ingredient_group(hash)
      end
    end
  end

  #=============================================================================
  # Validate one Ingredient Group
  #=============================================================================
  def validate_compiled_ingredient_group(hash)
    id = hash[:id]

    #---------------------------------------------------------------------------
    # Name
    #---------------------------------------------------------------------------
    if !hash[:name] || hash[:name].empty?
      raise _INTL(
        "The entry 'Name' is required in ingredient_groups.txt section {1}.\n{2}",
        id,
        FileLineData.linereport
      )
    end

    #---------------------------------------------------------------------------
    # SlotType
    #---------------------------------------------------------------------------
    if !hash[:slot_type]
      raise _INTL(
        "The entry 'SlotType' is required in ingredient_groups.txt section {1}.\n{2}",
        id,
        FileLineData.linereport
      )
    end

    slot_type = hash[:slot_type].to_s.strip.upcase.to_sym

    if !GameData::IngredientGroup::SLOT_TYPES.include?(slot_type)
      raise _INTL(
        "Invalid SlotType '{1}' in ingredient_groups.txt section {2}.\n" \
        "Valid SlotTypes are Ingredient and Condiment.\n{3}",
        hash[:slot_type],
        id,
        FileLineData.linereport
      )
    end

    hash[:slot_type] = slot_type

    #---------------------------------------------------------------------------
    # Items
    #---------------------------------------------------------------------------
    if !hash[:items] || hash[:items].empty?
      raise _INTL(
        "The entry 'Items' is required in ingredient_groups.txt section {1}.\n{2}",
        id,
        FileLineData.linereport
      )
    end

    # Convert all Item IDs to Symbols.
    hash[:items].map! do |item|
      item.to_s.strip.upcase.to_sym
    end

    #---------------------------------------------------------------------------
    # Reject duplicate members.
    #---------------------------------------------------------------------------
    duplicate_items = hash[:items].group_by { |item| item }
                                  .select { |_item, entries| entries.length > 1 }
                                  .keys

    if !duplicate_items.empty?
      raise _INTL(
        "The following item appears more than once in ingredient_groups.txt " \
        "section {1}: {2}.\n{3}",
        id,
        duplicate_items.join(", "),
        FileLineData.linereport
      )
    end

    #---------------------------------------------------------------------------
    # Validate each group member.
    #---------------------------------------------------------------------------
    hash[:items].each do |item|
      #-------------------------------------------------------------------------
      # It must exist as an ordinary item.
      #-------------------------------------------------------------------------
      if !GameData::Item.exists?(item)
        raise _INTL(
          "The item {1}, used by Ingredient Group {2}, does not exist in " \
          "items.txt.\n{3}",
          item,
          id,
          FileLineData.linereport
        )
      end

      #-------------------------------------------------------------------------
      # More importantly, it must have an ingredients.txt definition.
      #-------------------------------------------------------------------------
      if !GameData::Ingredient.exists?(item)
        raise _INTL(
          "The item {1}, used by Ingredient Group {2}, does not have an entry " \
          "in ingredients.txt.\n{3}",
          item,
          id,
          FileLineData.linereport
        )
      end

      ingredient = GameData::Ingredient.get(item)

      #-------------------------------------------------------------------------
      # Category must match the group's SlotType.
      #
      # An Ingredient and a Condiment can therefore never occupy the same group.
      #-------------------------------------------------------------------------
      if ingredient.category != slot_type
        raise _INTL(
          "The item {1} cannot be added to Ingredient Group {2}.\n" \
          "The group's SlotType is {3}, but {1} is defined as {4} in " \
          "ingredients.txt.\n{5}",
          item,
          id,
          slot_type,
          ingredient.category,
          FileLineData.linereport
        )
      end
    end
  end

  #=============================================================================
  # Final database-wide validation
  #=============================================================================
  def validate_all_compiled_ingredient_groups
  end

  #=============================================================================
  # Add ingredient_groups.txt to PBS compilation.
  #
  # Because this script loads after [003] Ingredient Compiler.rb, the previous
  # compile_pbs_files method first compiles ingredients.txt. Groups are compiled
  # afterward, which allows us to validate their members against Ingredient data.
  #=============================================================================
  class << self
    alias ia_cooking_compile_pbs_files_with_ingredients compile_pbs_files

    def compile_pbs_files
      ia_cooking_compile_pbs_files_with_ingredients

      text_files = get_all_pbs_files_to_compile
      group_files = text_files[:IngredientGroup]

      if group_files &&
         group_files[1] &&
         !group_files[1].empty?
        compile_ingredient_groups(*group_files[1])
      end
    end
  end
end