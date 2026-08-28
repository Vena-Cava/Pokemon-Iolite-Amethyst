################################################################################
# 
# Battle::Move class changes.
# 
################################################################################


class Battle::Move
  unless method_defined?(:ia_pbContactMove_without_cleats?)
    alias ia_pbContactMove_without_cleats? pbContactMove?
  end

  def pbContactMove?(user)
    return false if user.hasActiveItem?(:CLEATS) && kickingMove?
    return ia_pbContactMove_without_cleats?(user)
  end
end