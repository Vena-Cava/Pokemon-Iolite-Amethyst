module GameData
  class CookingRecipe
    attr_reader :id
    attr_reader :real_name
    attr_reader :family
    attr_reader :tier
    attr_reader :category
    attr_reader :sprite
    attr_reader :unlock_method
    attr_reader :default_recipe
    attr_reader :required_ingredients
    attr_reader :optional_ingredients
    attr_reader :required_condiments
    attr_reader :optional_condiments
    attr_reader :description
    attr_reader :pbs_file_suffix

    DATA = {}
    DATA_FILENAME = "cooking_recipes.dat"
    PBS_BASE_FILENAME = "cooking_recipes"

    TIER_ORDER = {
      :BASE   => 0,
      :GREAT  => 1,
      :ULTRA  => 2,
      :MASTER => 3
    }

    CATEGORIES = [
      :BREAKFAST,
      :MAINCOURSE,
      :DESSERT
    ]

    SCHEMA = {
      "SectionName"         => [:id,                    "m"],
      "Name"                => [:real_name,             "s"],
      "Family"              => [:family,                "m"],
      "Tier"                => [:tier,                  "m"],
      "Category"            => [:category,              "m"],
      "Sprite"              => [:sprite,                "s"],
      "UnlockMethod"        => [:unlock_method,         "m"],
      "Default"             => [:default_recipe,        "b"],
      "RequiredIngredients" => [:required_ingredients,  "*s"],
      "OptionalIngredients" => [:optional_ingredients,  "*s"],
      "RequiredCondiments"  => [:required_condiments,   "*s"],
      "OptionalCondiments"  => [:optional_condiments,   "*s"],
      "Description"         => [:description,           "s"]
    }

    extend ClassMethodsSymbols
    include InstanceMethods

    def initialize(hash)
      @id                   = hash[:id]
      @real_name            = hash[:real_name] || "Unnamed"
      @family               = hash[:family] || @id
      @tier                 = hash[:tier] || :BASE
      @category             = hash[:category] || :MAINCOURSE
      @sprite               = hash[:sprite]
      @unlock_method        = hash[:unlock_method]
      @default_recipe       = hash[:default_recipe] || false
      @required_ingredients = hash[:required_ingredients] || []
      @optional_ingredients = hash[:optional_ingredients] || []
      @required_condiments  = hash[:required_condiments] || []
      @optional_condiments  = hash[:optional_condiments] || []
      @description          = hash[:description] || ""
      @pbs_file_suffix      = hash[:pbs_file_suffix] || ""
    end

    def name
      return _INTL(@real_name)
    end

    def default?
      return @default_recipe
    end

    def tier_value
      return TIER_ORDER[@tier] || 0
    end

    def base?
      return @tier == :BASE
    end

    def great?
      return @tier == :GREAT
    end

    def ultra?
      return @tier == :ULTRA
    end

    def master?
      return @tier == :MASTER
    end
  end
end