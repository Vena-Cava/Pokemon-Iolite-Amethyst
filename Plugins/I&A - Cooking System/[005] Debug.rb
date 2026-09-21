#===============================================================================
# Cooking Debug Menu
#===============================================================================

MenuHandlers.add(:debug_menu, :cooking_menu, {
  "name"        => _INTL("Cooking options..."),
  "parent"      => :main,
  "description" => _INTL("Debug options for the Cooking system.")
})

#===============================================================================
# I&A - Cooking System
# Debug Tools
#===============================================================================

MenuHandlers.add(:debug_menu, :cooking_ingredient_test, {
  "name"        => _INTL("Test Cooking Ingredient"),
  "parent"      => :cooking_menu,
  "description" => _INTL("View the cooking data for an Ingredient or Condiment."),
  "effect"      => proc {
    item = pbListScreen(
      _INTL("Choose an item."),
      ItemLister.new(0, false)
    )

    next false if !item

    ingredient = GameData::Ingredient.try_get(item)

    if !ingredient
      pbMessage(_INTL("{1} has no cooking ingredient data.",
        GameData::Item.get(item).name))
      next false
    end

    item_data = GameData::Item.get(item)

    flavour_text = ingredient.flavours.map { |key, value|
      "#{key}: #{value}"
    }.join(", ")

    power_text = ingredient.powers.map { |key, value|
      "#{key}: #{value}"
    }.join(", ")

    type_text = ingredient.types.map { |key, value|
      "#{key}: #{value}"
    }.join(", ")

    stat_text = ingredient.stats.map { |key, value|
      "#{key}: #{value}"
    }.join(", ")

    pbMessage(_INTL(
      "{1}\nCategory: {2}",
      item_data.name,
      ingredient.category
    ))

    pbMessage(_INTL(
      "Flavours:\n{1}",
      flavour_text.empty? ? "None" : flavour_text
    ))

    pbMessage(_INTL(
      "Meal Powers:\n{1}",
      power_text.empty? ? "None" : power_text
    ))

    pbMessage(_INTL(
      "Types:\n{1}",
      type_text.empty? ? "None" : type_text
    ))

    pbMessage(_INTL(
      "Stats:\n{1}",
      stat_text.empty? ? "None" : stat_text
    ))

    next false
  }
})

#===============================================================================
# Ingredient Group Debug Viewer
#===============================================================================

MenuHandlers.add(:debug_menu, :cooking_ingredient_group_test, {
  "name"        => _INTL("Test Ingredient Group"),
  "parent"      => :cooking_menu,
  "description" => _INTL("View the members of a cooking Ingredient Group."),
  "effect"      => proc {
    groups = []

    GameData::IngredientGroup.each do |group|
      groups.push(group)
    end

    if groups.empty?
      pbMessage(_INTL("No Ingredient Groups are defined."))
      next false
    end

    groups.sort_by! { |group| group.name }

    commands = groups.map do |group|
      _INTL("{1} [{2}]", group.name, group.slot_type)
    end

    commands.push(_INTL("Cancel"))

    choice = pbMessage(
      _INTL("Choose an Ingredient Group."),
      commands,
      -1
    )

    next false if choice < 0 || choice >= groups.length

    group = groups[choice]

    member_names = group.items.map do |item|
      GameData::Item.get(item).name
    end

    pbMessage(_INTL(
      "{1}\nID: {2}\nSlot Type: {3}\nMembers: {4}",
      group.name,
      group.id,
      group.slot_type,
      group.length
    ))

    if member_names.empty?
      pbMessage(_INTL("This group has no members."))
    else
      pbMessage(_INTL(
        "Members:\n{1}",
        member_names.join(", ")
      ))
    end

    next false
  }
})

#===============================================================================
# Cooking Recipe Debug Viewer
#===============================================================================

MenuHandlers.add(:debug_menu, :cooking_recipe_test, {
  "name"        => _INTL("Test Cooking Recipe"),
  "parent"      => :cooking_menu,
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
      -1
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

#===============================================================================
# Recipe Matcher Debug Test
#===============================================================================

MenuHandlers.add(:debug_menu, :cooking_recipe_matcher_test, {
  "name"        => _INTL("Test Recipe Matcher"),
  "parent"      => :cooking_menu,
  "description" => _INTL("Run automatic tests against the Cooking Recipe matcher."),
  "effect"      => proc {
    #---------------------------------------------------------------------------
    # Make sure the Recipe Matcher has been loaded.
    #---------------------------------------------------------------------------
    if !defined?(Cooking::RecipeMatcher)
      pbMessage(_INTL("Cooking::RecipeMatcher is not defined."))
      next false
    end

    #---------------------------------------------------------------------------
    # Fetch one real item from each group needed by the Cheesy Pizza family.
    #
    # We deliberately fetch the items from the groups rather than hardcoding
    # particular cheeses, oils, salts, etc.
    #---------------------------------------------------------------------------
    required_groups = [
      :PIZZA_CHEESE,
      :OLIVE_OILS,
      :SALTS,
      :PIZZA_RAID_CONDIMENTS
    ]

    missing_groups = required_groups.select do |group_id|
      !GameData::IngredientGroup.exists?(group_id)
    end

    if !missing_groups.empty?
      pbMessage(_INTL(
        "Missing Ingredient Groups:\n{1}",
        missing_groups.join(", ")
      ))
      next false
    end

    pizza_cheese_group = GameData::IngredientGroup.get(:PIZZA_CHEESE)
    olive_oils_group   = GameData::IngredientGroup.get(:OLIVE_OILS)
    salts_group        = GameData::IngredientGroup.get(:SALTS)
    raid_group         = GameData::IngredientGroup.get(:PIZZA_RAID_CONDIMENTS)

    if pizza_cheese_group.empty? ||
       olive_oils_group.empty? ||
       salts_group.empty? ||
       raid_group.empty?
      pbMessage(_INTL(
        "One or more Ingredient Groups used by this test are empty."
      ))
      next false
    end

    cheese    = pizza_cheese_group.items[0]
    olive_oil = olive_oils_group.items[0]
    salt      = salts_group.items[0]
    raid      = raid_group.items[0]

    #---------------------------------------------------------------------------
    # Define the automatic tests.
    #
    # Each selected item in these arrays represents ONE physical copy.
    # Therefore two entries containing the same cheese ID represent two copies
    # of that cheese.
    #---------------------------------------------------------------------------
    tests = [
      {
        :name        => "Base requirements",
        :ingredients => [
          :WHITEFLOUR,
          :TOMATO,
          cheese
        ],
        :condiments  => [],
        :expected    => :CHEESYPIZZA
      },
      {
        :name        => "Great requirements",
        :ingredients => [
          :WHITEFLOUR,
          :TOMATO,
          cheese
        ],
        :condiments  => [
          olive_oil
        ],
        :expected    => :GREATCHEESYPIZZA
      },
      {
        :name        => "Great + extra Cheese",
        :ingredients => [
          :WHITEFLOUR,
          :TOMATO,
          cheese,
          cheese
        ],
        :condiments  => [
          olive_oil
        ],
        :expected    => :GREATCHEESYPIZZA
      },
      {
        :name        => "Great + Salt",
        :ingredients => [
          :WHITEFLOUR,
          :TOMATO,
          cheese
        ],
        :condiments  => [
          olive_oil,
          salt
        ],
        :expected    => :GREATCHEESYPIZZA
      },
      {
        :name        => "Great + Cheese + Salt",
        :ingredients => [
          :WHITEFLOUR,
          :TOMATO,
          cheese,
          cheese
        ],
        :condiments  => [
          olive_oil,
          salt
        ],
        :expected    => :ULTRACHEESYPIZZA
      },
      {
        :name        => "Ultra + Raid Condiment",
        :ingredients => [
          :WHITEFLOUR,
          :TOMATO,
          cheese,
          cheese
        ],
        :condiments  => [
          olive_oil,
          salt,
          raid
        ],
        :expected    => :MASTERCHEESYPIZZA
      }
    ]

    #---------------------------------------------------------------------------
    # Run the tests.
    #---------------------------------------------------------------------------
    results = []
    passed = 0

    tests.each do |test|
      result = Cooking::RecipeMatcher.match_family(
        :CHEESY_PIZZA,
        test[:ingredients],
        test[:condiments]
      )

      actual = result ? result.id : nil
      success = (actual == test[:expected])

      passed += 1 if success

      results.push({
        :name     => test[:name],
        :expected => test[:expected],
        :actual   => actual,
        :success  => success
      })
    end

    #---------------------------------------------------------------------------
    # Show the ingredients chosen automatically for the test.
    #---------------------------------------------------------------------------
    pbMessage(_INTL(
      "Test Items:\nCheese: {1}\nOlive Oil: {2}\nSalt: {3}\nRaid Condiment: {4}",
      GameData::Item.get(cheese).name,
      GameData::Item.get(olive_oil).name,
      GameData::Item.get(salt).name,
      GameData::Item.get(raid).name
    ))

    #---------------------------------------------------------------------------
    # Display each result individually.
    #---------------------------------------------------------------------------
    results.each_with_index do |result, index|
      status = result[:success] ? "PASS" : "FAIL"
      actual = result[:actual] || "No Match"

      pbMessage(_INTL(
        "Test {1}/{2}: {3}\n\n{4}\nExpected: {5}\nActual: {6}",
        index + 1,
        results.length,
        status,
        result[:name],
        result[:expected],
        actual
      ))
    end

    #---------------------------------------------------------------------------
    # Final summary.
    #---------------------------------------------------------------------------
    pbMessage(_INTL(
      "Recipe Matcher Tests Complete.\n\nPassed: {1}/{2}\nFailed: {3}/{2}",
      passed,
      tests.length,
      tests.length - passed
    ))

    next false
  }
})

#===============================================================================
# Recipe Knowledge Debug Test
#===============================================================================

MenuHandlers.add(:debug_menu, :cooking_recipe_knowledge_test, {
  "name"        => _INTL("Test Recipe Knowledge"),
  "parent"      => :cooking_menu,
  "description" => _INTL("Test learning and forgetting Cooking Recipes."),
  "effect"      => proc {
    commands = [
      _INTL("Show Known Recipes"),
      _INTL("Learn Cheesy Pizza"),
      _INTL("Learn Ultra Cheesy Pizza"),
      _INTL("Discover Master Cheesy Pizza"),
      _INTL("Learn Cheesy Pizza Family"),
      _INTL("Forget Cheesy Pizza Family"),
      _INTL("Forget All Recipes"),
      _INTL("Cancel")
    ]

    loop do
      command = pbMessage(
        _INTL("Recipe Knowledge Test"),
        commands,
        -1
      )

      # Either backing out of the command window or choosing the visible
      # Cancel command closes this menu.
      break if command < 0
      break if command >= commands.length - 1

      case command
      when 0
        known = Cooking.known_recipes

        if known.empty?
          pbMessage(_INTL("No recipes are currently known."))
        else
          names = known.map do |recipe|
            "#{recipe.name} [#{recipe.id}]"
          end

          pbMessage(_INTL(
            "Known Recipes ({1}):\n{2}",
            known.length,
            names.join("\n")
          ))
        end

      when 1
        learned = Cooking.learn_recipe(:CHEESYPIZZA)

        pbMessage(_INTL(
          "Newly learned:\n{1}",
          learned.empty? ? "None" : learned.join("\n")
        ))

      when 2
        learned = Cooking.learn_recipe(:ULTRACHEESYPIZZA)

        pbMessage(_INTL(
          "Newly learned:\n{1}",
          learned.empty? ? "None" : learned.join("\n")
        ))

      when 3
        learned = Cooking.discover_recipe(:MASTERCHEESYPIZZA)

        pbMessage(_INTL(
          "Newly discovered:\n{1}",
          learned.empty? ? "None" : learned.join("\n")
        ))

      when 4
        learned = Cooking.learn_recipe_family(:CHEESY_PIZZA)

        pbMessage(_INTL(
          "Newly learned:\n{1}",
          learned.empty? ? "None" : learned.join("\n")
        ))

      when 5
        removed = Cooking.forget_recipe_family(:CHEESY_PIZZA)

        pbMessage(_INTL(
          "Forgotten:\n{1}",
          removed.empty? ? "None" : removed.join("\n")
        ))

      when 6
        count = Cooking.forget_all_recipes

        pbMessage(_INTL(
          "Forgot {1} stored recipe(s).",
          count
        ))
      end
    end

    next false
  }
})

#===============================================================================
# Learn Cooking Recipe
#===============================================================================

MenuHandlers.add(:debug_menu, :cooking_learn_recipe, {
  "name"        => _INTL("Learn Cooking Recipe"),
  "parent"      => :cooking_menu,
  "description" => _INTL("Learn any Cooking Recipe."),
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
      known = Cooking.recipe_known?(recipe)

      if known
        _INTL("{1} [{2}] (Known)", recipe.name, recipe.tier)
      else
        _INTL("{1} [{2}]", recipe.name, recipe.tier)
      end
    end

    commands.push(_INTL("Cancel"))

    choice = pbMessage(
      _INTL("Choose a Cooking Recipe to learn."),
      commands,
      -1
    )

    next false if choice < 0 || choice >= recipes.length

    recipe = recipes[choice]

    learned = Cooking.learn_recipe(recipe)

    if learned.empty?
      pbMessage(_INTL(
        "{1} is already known.",
        recipe.name
      ))
    else
      learned_names = learned.map do |recipe_id|
        learned_recipe = GameData::CookingRecipe.get(recipe_id)
        learned_recipe.name
      end

      pbMessage(_INTL(
        "Learned:\n{1}",
        learned_names.join("\n")
      ))
    end

    next false
  }
})

#===============================================================================
# Forget Cooking Recipe
#===============================================================================

MenuHandlers.add(:debug_menu, :cooking_forget_recipe, {
  "name"        => _INTL("Forget Cooking Recipe"),
  "parent"      => :cooking_menu,
  "description" => _INTL("Forget a learned Cooking Recipe."),
  "effect"      => proc {
    recipes = Cooking.known_recipes

    # Default recipes can't truly be forgotten, so don't show them here.
    recipes = recipes.reject { |recipe| recipe.default? }

    if recipes.empty?
      pbMessage(_INTL("There are no learned Cooking Recipes to forget."))
      next false
    end

    commands = recipes.map do |recipe|
      _INTL("{1} [{2}]", recipe.name, recipe.tier)
    end

    commands.push(_INTL("Cancel"))

    choice = pbMessage(
      _INTL("Choose a Cooking Recipe to forget."),
      commands,
      -1
    )

    next false if choice < 0 || choice >= recipes.length

    recipe = recipes[choice]

    if Cooking.forget_recipe(recipe)
      pbMessage(_INTL(
        "Forgot {1}.",
        recipe.name
      ))
    else
      pbMessage(_INTL(
        "{1} could not be forgotten.",
        recipe.name
      ))
    end

    next false
  }
})

#===============================================================================
# Test Cooking Selection
#===============================================================================

MenuHandlers.add(:debug_menu, :cooking_selection_test, {
  "name"        => _INTL("Test Cooking Selection"),
  "parent"      => :cooking_menu,
  "description" => _INTL("Tests Creative Mode ingredient and condiment selection."),
  "effect"      => proc {
    selection = Cooking::Selection.new(:CREATIVE)

    loop do
      stage_name = case selection.stage
                   when :INGREDIENTS then "Ingredients"
                   when :CONDIMENTS  then "Condiments"
                   when :CONFIRM     then "Confirmation"
                   else selection.stage.to_s
                   end

      commands = []

      if selection.choosing_ingredients?
        selection.available_ingredients.each do |item_id|
          item = GameData::Item.get(item_id)
          qty  = selection.available_quantity(item_id)

          commands.push(
            _INTL("{1} x{2}", item.name, qty)
          )
        end

        commands.push(_INTL("Next")) if selection.can_continue?
      elsif selection.choosing_condiments?
        selection.available_condiments.each do |item_id|
          item = GameData::Item.get(item_id)
          qty  = selection.available_quantity(item_id)

          commands.push(
            _INTL("{1} x{2}", item.name, qty)
          )
        end

        commands.push(_INTL("Next")) if selection.can_continue?
      else
        commands.push(_INTL("Confirm"))
      end

      commands.push(_INTL("Back"))

      ingredient_text = selection.selected_ingredients.map do |item_id|
        GameData::Item.get(item_id).name
      end

      condiment_text = selection.selected_condiments.map do |item_id|
        GameData::Item.get(item_id).name
      end

      message = _INTL(
        "Stage: {1}\nIngredients ({2}/6): {3}\nCondiments ({4}/4): {5}",
        stage_name,
        selection.ingredient_count,
        ingredient_text.empty? ? "None" : ingredient_text.join(", "),
        selection.condiment_count,
        condiment_text.empty? ? "None" : condiment_text.join(", ")
      )

      command = pbMessage(message, commands, -1)

      # Pressing the physical Cancel/Back button behaves exactly like choosing
      # the Back command.
      if command < 0
        result = selection.back
        break if result == :EXIT
        next
      end

      chosen_text = commands[command]

      #-------------------------------------------------------------------------
      # Back
      #-------------------------------------------------------------------------
      if chosen_text == _INTL("Back")
        result = selection.back
        break if result == :EXIT
        next
      end

      #-------------------------------------------------------------------------
      # Next
      #-------------------------------------------------------------------------
      if chosen_text == _INTL("Next")
        selection.next_stage
        next
      end

      #-------------------------------------------------------------------------
      # Confirmation
      #-------------------------------------------------------------------------
      if chosen_text == _INTL("Confirm")
        recipe = selection.matched_recipe

        if recipe
          pbMessage(
            _INTL(
              "The Recipe Matcher identifies this as:\n{1} [{2}]",
              recipe.name,
              recipe.id
            )
          )
        else
          pbMessage(
            _INTL("This combination doesn't match a Cooking Recipe.")
          )
        end

        next
      end

      #-------------------------------------------------------------------------
      # An Ingredient/Condiment was selected.
      #-------------------------------------------------------------------------
      available_items = if selection.choosing_ingredients?
                          selection.available_ingredients
                        else
                          selection.available_condiments
                        end

      # The item commands occur before Next/Back, so the command index maps
      # directly to the available-item array.
      item_id = available_items[command]

      selection.add(item_id) if item_id
    end
  }
})