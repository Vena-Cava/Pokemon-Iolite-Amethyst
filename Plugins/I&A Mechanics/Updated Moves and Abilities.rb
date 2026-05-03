#===============================================================================
# Updated Move
#===============================================================================
#===============================================================================
# Uses the last move that was used. (Copycat)
#===============================================================================
class Battle::Move::UseLastMoveUsed
  alias IAMechanicsinitialize initialize unless private_method_defined?(:IAMechanicsinitialize)
  def initialize(*args)
    IAMechanicsinitialize(*args)
    @moveBlacklist.push("ProtectUserSideFromSpecialMoves") # Chi Block
  end
end

#===============================================================================
# Updated Ability
#===============================================================================
#===============================================================================
# Honey Gather
#===============================================================================
Battle::AbilityEffects::OnSwitchIn.add(:HONEYGATHER,
  proc { |ability, battler, battle, switch_in|
    next if battler.ability_triggered?
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("A sweet aroma is wafting from the honey covering {1}!", battler.pbThis(true)))
    battle.allOtherSideBattlers(battler.index).each do |b|
      next if !b.near?(battler) || b.fainted?
      if b.itemActive? && !b.hasActiveAbility?(:CONTRARY) && b.effects[PBEffects::Substitute] == 0
        next if Battle::ItemEffects.triggerStatLossImmunity(b.item, b, :EVASION, battle, true)
      end
      b.pbLowerStatStageByAbility(:EVASION, 1, battler, false)
    end
    battle.pbHideAbilitySplash(battler)
    battle.pbSetAbilityTrigger(battler)
  }
)