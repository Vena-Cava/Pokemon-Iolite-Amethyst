#===============================================================================
# I&A - Cooking System
# Ingredient Group Data
#
# Ingredient Groups are named collections of cooking Ingredients or Condiments.
# Recipes can require a Group rather than one exact item.
#
# Examples:
#   [SALTS]
#   [PIZZA_CHEESE]
#   [COOKING_HERBS]
#===============================================================================

module GameData
  class IngredientGroup
    attr_reader :id
    attr_reader :name
    attr_reader :slot_type
    attr_reader :items
    attr_reader :flags
    attr_reader :pbs_file_suffix

    DATA = {}
    DATA_FILENAME = "ingredient_groups.dat"
    PBS_BASE_FILENAME = "ingredient_groups"

    SLOT_TYPES = [
      :INGREDIENT,
      :CONDIMENT
    ]

    SCHEMA = {
      "SectionName" => [:id,              "m"],
      "Name"        => [:name,            "s"],
      "SlotType"    => [:slot_type,       "s"],
      "Items"       => [:items,           "*s"],
      "Flags"       => [:flags,           "*s"]
    }

    extend ClassMethodsSymbols
    include InstanceMethods

    def initialize(hash)
      @id              = hash[:id]
      @name            = hash[:name] || @id.to_s
      @slot_type       = hash[:slot_type] || :INGREDIENT
      @items           = hash[:items] || []
      @flags           = hash[:flags] || []
      @pbs_file_suffix = hash[:pbs_file_suffix] || ""
    end

    #---------------------------------------------------------------------------
    # Is this an Ingredient-slot group?
    #---------------------------------------------------------------------------
    def ingredient?
      return @slot_type == :INGREDIENT
    end

    #---------------------------------------------------------------------------
    # Is this a Condiment-slot group?
    #---------------------------------------------------------------------------
    def condiment?
      return @slot_type == :CONDIMENT
    end

    #---------------------------------------------------------------------------
    # Does this group contain the given Item ID?
    #---------------------------------------------------------------------------
    def includes?(item)
      item = item.id if item.respond_to?(:id)
      item = item.to_sym if item.is_a?(String)
      return @items.include?(item)
    end

    #---------------------------------------------------------------------------
    # Number of possible items in this group.
    #---------------------------------------------------------------------------
    def length
      return @items.length
    end

    def empty?
      return @items.empty?
    end

    #---------------------------------------------------------------------------
    # Returns the normal GameData::Item objects represented by this group.
    #---------------------------------------------------------------------------
    def item_data
      return @items.map { |item| GameData::Item.get(item) }
    end

    #---------------------------------------------------------------------------
    # Returns the GameData::Ingredient objects represented by this group.
    #---------------------------------------------------------------------------
    def ingredient_data
      return @items.map { |item| GameData::Ingredient.get(item) }
    end

    def has_flag?(flag)
      return @flags.any? { |f| f.downcase == flag.to_s.downcase }
    end
  end
end

#===============================================================================
# Ingredient convenience methods
#===============================================================================

module GameData
  class Ingredient
    #---------------------------------------------------------------------------
    # Is this Ingredient/Condiment contained in the given Ingredient Group?
    #
    # Example:
    #   GameData::Ingredient.get(:SALT).in_group?(:SALTS)
    #---------------------------------------------------------------------------
    def in_group?(group)
      group = GameData::IngredientGroup.try_get(group)
      return false if !group
      return group.includes?(@id)
    end
  end
end