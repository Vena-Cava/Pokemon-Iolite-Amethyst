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

