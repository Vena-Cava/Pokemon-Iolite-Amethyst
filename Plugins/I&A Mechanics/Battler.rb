#===============================================================================
# Battler
#===============================================================================
class Battle::Battler

#===============================================================================
# Removes Sandstorm Damage if Pokémon has Rock Body
#===============================================================================
  def takesSandstormDamage?
    return false if !takesIndirectDamage?
    return false if pbHasType?(:GROUND) || pbHasType?(:ROCK) || pbHasType?(:STEEL)
    return false if inTwoTurnAttack?("TwoTurnAttackInvulnerableUnderground",
                                     "TwoTurnAttackInvulnerableUnderwater")
    return false if hasActiveAbility?([:OVERCOAT, :SANDFORCE, :SANDRUSH, :SANDVEIL, :ROCKBODY])
    return false if hasActiveItem?(:SAFETYGOGGLES)
    return true
  end
  
#===============================================================================
# Adds Permafrost to Unstoppable and Ungainable Abilities
#===============================================================================
  alias :_ia_mechanics_unstoppableAbility? :unstoppableAbility?
  def unstoppableAbility?(abil = nil)
    ret = _ia_mechanics_unstoppableAbility?(abil)
    return true if ret
    abil = @ability_id if !abil
    abil = GameData::Ability.try_get(abil)
    return false if !abil
    new_blacklist = [:PERMAFROST, :PUFFEDOUT]
    return new_blacklist.include?(abil.id)
  end
  def ungainableAbility?(abil = nil)
    ret = _ia_mechanics_unstoppableAbility?(abil)
    return true if ret
    abil = @ability_id if !abil
    abil = GameData::Ability.try_get(abil)
    return false if !abil
    new_blacklist = [:PERMAFROST, :PUFFEDOUT]
    return new_blacklist.include?(abil.id)
  end
  
end

