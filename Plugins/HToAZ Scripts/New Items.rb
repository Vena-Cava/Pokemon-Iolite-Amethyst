#===============================================================================
# Masks
#===============================================================================
Battle::ItemEffects::DamageCalcFromUser.add(:HEARTHFLAMEMASK,
  proc { |item, user, target, move, mults, power, type|
    if user.isSpecies?(:OGERPON)
      mults[:power_multiplier] *= 1.2
    end
  }
)

Battle::ItemEffects::DamageCalcFromUser.add(:CORNERSTONEMASK,
  proc { |item, user, target, move, mults, power, type|
    if user.isSpecies?(:OGERPON)
      mults[:power_multiplier] *= 1.2
    end
  }
)

Battle::ItemEffects::DamageCalcFromUser.add(:WELLSPRINGMASK,
  proc { |item, user, target, move, mults, power, type|
    if user.isSpecies?(:OGERPON)
      mults[:power_multiplier] *= 1.2
    end
  }
)


