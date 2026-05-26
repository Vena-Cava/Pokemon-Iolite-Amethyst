################################################################################
# 
# Battle::Move class changes.
# 
################################################################################


class Battle::Move
  
  #-----------------------------------------------------------------------------
  # Adds Cleats effect to prevent contact for kicking moves.
  #-----------------------------------------------------------------------------
  alias paldea_pbContactMove? pbContactMove?
  def pbContactMove?(user)
    return false if user.hasActiveItem?(:CLEATS) && kickingMove?
    return paldea_pbContactMove?(user)
  end

end