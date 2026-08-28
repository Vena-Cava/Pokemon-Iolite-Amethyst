#===============================================================================
# Fluffy Sweater
#===============================================================================
Battle::ItemEffects::DamageCalcFromTarget.add(:FLUFFYSWEATER,
  proc { |item, user, target, move, mults, power, type|
    mults[:defense_multiplier] *= 1.5 if move.physicalMove?
  }
)

#===============================================================================
# Whetstone
#===============================================================================
Battle::ItemEffects::DamageCalcFromUser.add(:WHETSTONE,
  proc { |item, user, target, move, mults, baseDmg, type|
    mults[:power_multiplier] *= 1.2 if move.slicingMove?
  }
)

#===============================================================================
# Cleats
#===============================================================================
Battle::ItemEffects::DamageCalcFromUser.add(:CLEATS,
  proc { |item, user, target, move, mults, baseDmg, type|
    mults[:power_multiplier] *= 1.1 if move.kickingMove?
  }
)