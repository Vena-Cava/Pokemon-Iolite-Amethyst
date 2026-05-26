#===============================================================================
# Global Inverse Battle Switch
#===============================================================================

module GlobalInverseBattle
  SWITCH_ID = 127
end

EventHandlers.add(:on_start_battle, :global_inverse_battle_switch,
  proc {
    if $game_switches[GlobalInverseBattle::SWITCH_ID]
      $game_temp.inverse_battle = true
    end
  }
)