#=============================================================================
# Swdfm Utilites - Integer
# 2024-01-01
# 2024-04-16
#=============================================================================
class Integer
  # eg. 1 => [1]
  def to_array
    return [self]
  end
  
  # eg. 1 => 1, 2 => 3, 3 => 6 etc.
  def triangle
    ret = (self ** 2).to_f / 2 + (self.to_f / 2)
    return ret.to_i
  end
  
  # eg. 100.midpoint(200) => 150
  def midpoint(other_int)
    if self > other_int
      return other_int + (self - other_int) / 2
    else
      return self + (other_int - self) / 2
    end
  end
  
  # eg. 100.midpoint_graphics(60) => (512 / 100) + 100 - 30 = 326
  def midpoint_graphics(w, height = false)
    if height
      ret = self.midpoint(Graphics.height)
    else
      ret = self.midpoint(Graphics.width)
    end
    return ret - (w / 2)
  end
  
  def conveyor(max, backwards = false)
    ret = self
    if backwards
      ret -= 1
      return max - 1 if ret < 0
    else
      ret += 1
      return 0 if ret == max
    end
    return ret
  end
  
  def quot(div)
    return (self / div).floor
  end
  
  def rem(div)
    return [quot(div), self % div]
  end
  
  def remove_rem(div)
    return quot(div) * div
  end
  
  def last_of?(array)
    return self == array.length - 1
  end
  alias is_last? last_of?
end