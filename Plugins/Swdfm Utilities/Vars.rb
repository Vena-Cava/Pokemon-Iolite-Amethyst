module Swd
  def self.set_var(var, set_to)
    $SWDFM = Swdfm_Vars.new unless $SWDFM
    $SWDFM.set(var, set_to)
  end
  
  def self.get_var(var)
    return nil unless $SWDFM
    return $SWDFM.get(var)
  end
end

class Swdfm_Vars
  def initialize
    @vars = {}
  end
  
  def set(var, set_to)
    @vars[var] = set_to
  end
  
  def get(var)
    return @vars[var]
  end
end

