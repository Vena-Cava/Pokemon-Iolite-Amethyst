#===============================================================================
# I&A - Cooking System
# Ingredient Data
#===============================================================================

module GameData
  class Ingredient
    attr_reader :id
    attr_reader :category
    attr_reader :flavours
    attr_reader :powers
    attr_reader :types
    attr_reader :stats
    attr_reader :flags
    attr_reader :pbs_file_suffix

    DATA = {}
    DATA_FILENAME = "ingredients.dat"
    PBS_BASE_FILENAME = "ingredients"

    CATEGORIES = [
      :INGREDIENT,
      :CONDIMENT
    ]

    FLAVOURS = [
      :SWEET,
      :SOUR,
      :SALTY,
      :BITTER,
      :SPICY
    ]

    STATS = [
      :HP,
      :ATTACK,
      :DEFENSE,
      :SPECIAL_ATTACK,
      :SPECIAL_DEFENSE,
      :SPEED
    ]

    SCHEMA = {
      "SectionName" => [:id,              "m"],
      "Category"    => [:category,        "s"],
      "Flavours"    => [:flavours,        "*s"],
      "Powers"      => [:powers,          "*s"],
      "Types"       => [:types,           "*s"],
      "Stats"       => [:stats,           "*s"],
      "Flags"       => [:flags,           "*s"]
    }

    extend ClassMethodsSymbols
    include InstanceMethods

    def initialize(hash)
      @id              = hash[:id]
      @category        = hash[:category] || :INGREDIENT
      @flavours        = hash[:flavours] || {}
      @powers          = hash[:powers]   || {}
      @types           = hash[:types]    || {}
      @stats           = hash[:stats]    || {}
      @flags           = hash[:flags]    || []
      @pbs_file_suffix = hash[:pbs_file_suffix] || ""
    end

    #---------------------------------------------------------------------------
    # Returns the underlying ordinary GameData::Item.
    #---------------------------------------------------------------------------
    def item
      return GameData::Item.get(@id)
    end

    #---------------------------------------------------------------------------
    # Category helpers.
    #---------------------------------------------------------------------------
    def ingredient?
      return @category == :INGREDIENT
    end

    def condiment?
      return @category == :CONDIMENT
    end

    #---------------------------------------------------------------------------
    # Flavour helpers.
    #---------------------------------------------------------------------------
    def flavour(flavour)
      flavour = flavour.to_sym
      return @flavours[flavour] || 0
    end

    def sweet
      return flavour(:SWEET)
    end

    def sour
      return flavour(:SOUR)
    end

    def salty
      return flavour(:SALTY)
    end

    def bitter
      return flavour(:BITTER)
    end

    def spicy
      return flavour(:SPICY)
    end

    #---------------------------------------------------------------------------
    # Meal Power value.
    #---------------------------------------------------------------------------
    def power(power)
      power = power.to_sym
      return @powers[power] || 0
    end

    #---------------------------------------------------------------------------
    # Type value.
    #---------------------------------------------------------------------------
    def type_value(type)
      type = type.to_sym
      return @types[type] || 0
    end

    #---------------------------------------------------------------------------
    # Stat value.
    #---------------------------------------------------------------------------
    def stat_value(stat)
      stat = stat.to_sym
      return @stats[stat] || 0
    end

    #---------------------------------------------------------------------------
    # Ingredient-specific flags.
    #---------------------------------------------------------------------------
    def has_flag?(flag)
      return @flags.any? { |f| f.downcase == flag.to_s.downcase }
    end
  end
end

#===============================================================================
# Convenience methods for ordinary Items.
#===============================================================================

module GameData
  class Item
    #---------------------------------------------------------------------------
    # Is this item defined in PBS/ingredients.txt?
    #---------------------------------------------------------------------------
    def ingredient?
      return GameData::Ingredient.exists?(@id)
    end

    #---------------------------------------------------------------------------
    # Returns the ingredient data, or nil if this isn't a cooking ingredient.
    #---------------------------------------------------------------------------
    def ingredient_data
      return GameData::Ingredient.try_get(@id)
    end
  end
end