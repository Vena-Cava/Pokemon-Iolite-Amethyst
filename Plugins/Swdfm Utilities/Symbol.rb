#=============================================================================
# Swdfm Utilites - Symbol
# 2023-12-04
# 2024-03-03
#=============================================================================
class Symbol
  # eg. :symbol.is?(:symbol) => true
  # eg. :symbol.is?(:not_symbol) => false
  def is?(is_what)
    return false unless is_what.is_a?(Symbol)
    return self == is_what
  end
  
  # eg. :symbol.push(:suffix) => :symbolsuffix
  def push(pushing)
    return "#{self}#{pushing}".to_sym
  end
  
  # eg. :symbol.push(:suffix) => :symbol_suffix
  def u_push(pushing)
    return "#{self}_#{pushing}".to_sym
  end
  
  # eg. :symbol.push(:suffix) => :symbol__suffix
  def w_push(pushing)
    return "#{self}__#{pushing}".to_sym
  end
  
  # Same as String
  # eg. :symbol.gsub(:b, :bar) =>
  #     :symbarol
  def gsub(replace_what, with_what)
    return self.to_s.gsub(replace_what.to_s, with_what.to_s).to_sym
  end
  
  # Same as String
  def upcase
    return self.to_s.upcase.to_sym
  end
  
  # Same as String
  def downcase
    return self.to_s.downcase.to_sym
  end
  
  # eg. :left_right => :left
  # eg. :nounderscores => :nounderscores
  def lhs(splitter = "_")
    return self.to_s.split(splitter)[0].to_sym
  end
  
  # eg. :left_right => nil
  # eg. :left_mid_right => :mid
  def mhs(splitter = "_")
    return nil unless self.to_s.after_first(splitter).include?(splitter)
    return self.to_s.split(splitter)[1].to_sym
  end
  
  # eg. :left_right => :right
  # eg. :nounderscores => nil
  # eg. :left_mid_right => :right
  def rhs(splitter = "_")
    return nil unless self.to_s.include?(splitter)
    return self.to_s.split(splitter)[-1].to_sym
  end
  
  # eg. :string => [:string]
  def to_array
    return [self]
  end
  
  # include, but works with symbol
  def include?(sub)
    return self.to_s.include?(sub.to_s)
  end
  
  def to_i
    return self.to_s.to_i
  end
end