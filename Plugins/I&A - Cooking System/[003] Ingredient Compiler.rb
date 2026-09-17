#===============================================================================
# I&A - Cooking System
# Ingredient PBS Compiler
#===============================================================================

module Compiler
  module_function

  #-----------------------------------------------------------------------------
  # Converts:
  #
  #   Sweet,4,Sour,2
  #
  # into:
  #
  #   {
  #     :SWEET => 4,
  #     :SOUR  => 2
  #   }
  #-----------------------------------------------------------------------------
  def compile_ingredient_value_pairs(values, field_name, ingredient_id)
    ret = {}
    values ||= []

    if values.length.odd?
      raise _INTL(
        "The entry '{1}' in ingredients.txt section {2} must contain " \
        "name/value pairs.\n{3}",
        field_name,
        ingredient_id,
        FileLineData.linereport
      )
    end

    values.each_slice(2) do |name, value|
      key = name.to_s.strip.upcase.to_sym

      begin
        number = Integer(value)
      rescue
        raise _INTL(
          "The value '{1}' in the entry '{2}' in ingredients.txt section {3} " \
          "is not a valid integer.\n{4}",
          value,
          field_name,
          ingredient_id,
          FileLineData.linereport
        )
      end

      if ret.key?(key)
        raise _INTL(
          "The value '{1}' appears more than once in the entry '{2}' in " \
          "ingredients.txt section {3}.\n{4}",
          key,
          field_name,
          ingredient_id,
          FileLineData.linereport
        )
      end

      ret[key] = number
    end

    return ret
  end

  #=============================================================================
  # Compile Ingredient data
  #=============================================================================
  def compile_ingredients(*paths)
    compile_PBS_file_generic(GameData::Ingredient, *paths) do |final_validate, hash|
      if final_validate
        validate_all_compiled_ingredients
      else
        validate_compiled_ingredient(hash)
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Validates one Ingredient entry.
  #-----------------------------------------------------------------------------
  def validate_compiled_ingredient(hash)
    id = hash[:id]

    #-------------------------------------------------------------------------
    # The Ingredient must also exist as an ordinary Essentials item.
    #-------------------------------------------------------------------------
    if !GameData::Item.exists?(id)
      raise _INTL(
        "The ingredient {1} does not exist in items.txt.\n{2}",
        id,
        FileLineData.linereport
      )
    end

    #-------------------------------------------------------------------------
    # Category
    #-------------------------------------------------------------------------
    category = hash[:category].to_s.strip.upcase.to_sym

    if !GameData::Ingredient::CATEGORIES.include?(category)
      raise _INTL(
        "Invalid Category '{1}' in ingredients.txt section {2}.\n" \
        "Valid categories are Ingredient and Condiment.\n{3}",
        hash[:category],
        id,
        FileLineData.linereport
      )
    end

    hash[:category] = category

    #-------------------------------------------------------------------------
    # Convert the various name/value lists to hashes.
    #-------------------------------------------------------------------------
    hash[:flavours] = compile_ingredient_value_pairs(
      hash[:flavours],
      "Flavours",
      id
    )

    hash[:powers] = compile_ingredient_value_pairs(
      hash[:powers],
      "Powers",
      id
    )

    hash[:types] = compile_ingredient_value_pairs(
      hash[:types],
      "Types",
      id
    )

    hash[:stats] = compile_ingredient_value_pairs(
      hash[:stats],
      "Stats",
      id
    )

    #-------------------------------------------------------------------------
    # Validate Flavours.
    #-------------------------------------------------------------------------
    hash[:flavours].each_key do |flavour|
      next if GameData::Ingredient::FLAVOURS.include?(flavour)

      raise _INTL(
        "Invalid flavour '{1}' in ingredients.txt section {2}.\n" \
        "Valid flavours are Sweet, Sour, Salty, Bitter and Spicy.\n{3}",
        flavour,
        id,
        FileLineData.linereport
      )
    end

    #-------------------------------------------------------------------------
    # Validate Meal Powers.
    #-------------------------------------------------------------------------
    hash[:powers].each_key do |power|
      next if MealPowers::POWERS.key?(power)

      raise _INTL(
        "Invalid Meal Power '{1}' in ingredients.txt section {2}.\n{3}",
        power,
        id,
        FileLineData.linereport
      )
    end

    #-------------------------------------------------------------------------
    # Validate Types.
    #-------------------------------------------------------------------------
    hash[:types].each_key do |type|
      next if GameData::Type.exists?(type)

      raise _INTL(
        "Invalid Pokémon type '{1}' in ingredients.txt section {2}.\n{3}",
        type,
        id,
        FileLineData.linereport
      )
    end

    #-------------------------------------------------------------------------
    # Validate Stats.
    #-------------------------------------------------------------------------
    hash[:stats].each_key do |stat|
      next if GameData::Ingredient::STATS.include?(stat)

      raise _INTL(
        "Invalid stat '{1}' in ingredients.txt section {2}.\n" \
        "Valid stats are HP, Attack, Defense, Special_Attack, " \
        "Special_Defense and Speed.\n{3}",
        stat,
        id,
        FileLineData.linereport
      )
    end
  end

  #-----------------------------------------------------------------------------
  # Final database-wide checks.
  #-----------------------------------------------------------------------------
  def validate_all_compiled_ingredients
  end

  #=============================================================================
  # Hook ingredients.txt into the normal PBS compilation process.
  #
  # This deliberately happens AFTER the existing compiler has run, because
  # Ingredient definitions depend on items.txt and Types already being compiled.
  #=============================================================================
  class << self
    alias ia_cooking_compile_pbs_files compile_pbs_files

    def compile_pbs_files
      ia_cooking_compile_pbs_files

      text_files = get_all_pbs_files_to_compile
      ingredient_files = text_files[:Ingredient]

      if ingredient_files &&
         ingredient_files[1] &&
         !ingredient_files[1].empty?
        compile_ingredients(*ingredient_files[1])
      end
    end
  end
end