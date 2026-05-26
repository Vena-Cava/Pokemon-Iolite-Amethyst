#===============================================================================
# Individual Size
#===============================================================================

#-------------------------------------------------------------------------------
# Pokemon data.
#-------------------------------------------------------------------------------
class Pokemon

  def scale; return @scale || 100; end
  def scale=(value); @scale = value.clamp(0, 255); end
  
  alias scale_initialize initialize  
  def initialize(*args)
	scale_initialize(*args)
    @scale = rand(256)
  end
  
end



