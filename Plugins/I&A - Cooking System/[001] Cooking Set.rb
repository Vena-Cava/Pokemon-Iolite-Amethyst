#===============================================================================
# I&A - Cooking System
# Cooking Set
#
# The Cooking Set is a reusable Key Item which opens the cooking system from
# anywhere in the field.
#===============================================================================

module Cooking
  #-----------------------------------------------------------------------------
  # Main entry point for opening the cooking system.
  #
  # For now this is deliberately just a placeholder. Once the cooking scene is
  # implemented, this method will become the single place that launches it.
  #-----------------------------------------------------------------------------
  def self.open
    pbMessage(_INTL("You set up the Cooking Set."))

    # Temporary placeholder until the cooking UI is implemented.
    commands = [
      _INTL("Cook a Dish"),
      _INTL("Cancel")
    ]

    command = pbMessage(
      _INTL("What would you like to do?"),
      commands,
      commands.length - 1
    )

    case command
    when 0
      pbMessage(_INTL("The cooking menu hasn't been implemented yet."))
    end

    return true
  end
end

#===============================================================================
# Cooking Set item handlers
#===============================================================================

#-------------------------------------------------------------------------------
# Text displayed for the item's Bag command.
#-------------------------------------------------------------------------------
ItemHandlers::UseText.add(:COOKINGSET, proc { |item|
  next _INTL("Cook")
})

#-------------------------------------------------------------------------------
# Using it directly from the Bag.
#
# Return 2 so the Bag closes first. Essentials will then invoke the field-use
# handler for the item.
#-------------------------------------------------------------------------------
ItemHandlers::UseFromBag.add(:COOKINGSET, proc { |item|
  next 2
})

#-------------------------------------------------------------------------------
# Using it in the field, including when the Key Item is registered.
#-------------------------------------------------------------------------------
ItemHandlers::UseInField.add(:COOKINGSET, proc { |item|
  next Cooking.open
})