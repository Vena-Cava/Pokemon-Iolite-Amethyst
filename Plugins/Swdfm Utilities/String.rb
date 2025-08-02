#=============================================================================
# Swdfm Utilites - String
# 2023-12-04
# 2024-09-05
#=============================================================================
class String
  # eg. "firstpart".starts_with?("first") => => true
  #     "firstpart".starts_with?("part") => => false
  def starts_with?(sub_str)
    return false if sub_str.length > self.length
    return self[0, sub_str.length] == sub_str
  end
  
  # eg. "firstpart".ends_with?("first") => => false
  #     "firstpart".ends_with?("part") => => true
  def ends_with?(sub_str)
    return false if sub_str.length > self.length
    return self[self.length - sub_str.length, sub_str.length] == sub_str
  end
  
  # eg. "let me in" => "letmein"
  def unblanked
    return self.gsub(" ", "")
  end
  
  # eg. "    s p a c e    " => "s p a c e"
  def sandwich
    # Returns all text on and after the first sig. character and on and before the last
    return self if self.unblanked == ""
    first = self.unblanked[0, 1]
    last = self.unblanked[-1, 1]
    spaces_before = self.before_first(first).length
    spaces_after = self.after_last(last).length
    return self[spaces_before, self.length - spaces_after - spaces_before]
  end
  
  # eg. "before first".before_first(" ") => "before"
  def before_first(sub_str)
    return self unless self.include?(sub_str)
    return "" if self.starts_with?(sub_str)
    for c in 0..self.length - sub_str.length
      next unless self[c, sub_str.length] == sub_str
      return self[0, c]
    end
  end
  
  # "after first one".after_first(" ") => "first one"
  def after_first(sub_str)
    return self unless self.include?(sub_str)
    c = before_first(sub_str).length
    return self[c + sub_str.length, self.length - c - sub_str.length]
  end
  
  # eg. "the one before last".before_last(" ") => "the one before"
  def before_last(sub_str)
    str = self.clone
    c = str.after_last(sub_str).length
    return str if c == str.length
    c += 1
    return str[0, str.length - c]
  end
  
  # eg. "the one after last".after_last(" ") => "last"
  def after_last(sub_str)
    str = self.clone
    while str.include?(sub_str)
      str = str.after_first(sub_str)
    end
    return str
  end
  
  # eg. "pre_post".u_split => ["pre", "post"]
  def u_split
    return self.split("_")
  end
  
  # eg. "pre__post".w_split => ["pre", "post"]
  def w_split
    return self.split("__")
  end
  
  # eg. "string".u_push(3) => "string_3"
  def u_push(to_push)
    return self + "_#{to_push}"
  end
  
  # eg. "string".w_push(3) => "string__3"
  def w_push(to_push)
    return self + "__#{to_push}"
  end
  
  # eg. "string" => ["string"]
  def to_array
    return [self]
  end
  
  # eg. "foobar" => "Foobar"
  def first_cap
    str = self.gsub("_", " ").split(" ")
    ret = []
    for i in str
      ret.push(first_cap_internal(i))
    end
    return ret.join(" ")
  end
  
  def first_cap_internal(str)
    return str[0, 1].upcase + str[1, length - 1].downcase
  end
  
  # eg. "[foobar]".multi_delete("[", "]") => "foobar"
  def multi_delete(*args)
    ret = self
    for arg in args
      ret = ret.gsub(arg, "")
    end
    return ret
  end
  
#=============================================================================
  def is_all_numbers?
    for i in 0...self.length
      return false unless "0123456789".include?(self[i, 1])
    end
    return true
  end
  
  def starts_with_number?
    return self[0, 1].is_all_numbers?
  end
  
  # Removes all punctuation from a string (except spaces)
  def remove_puncts
    accepted = "qwertyuiopasdfghjklzxcvbnm"
    accepted += accepted.upcase
    accepted += "1234567890"
    accepted += " _"
    ret = ""
    for i in 0...self.length
      t_char = self[i, 1]
      t_char = "e" if t_char == "é"
      next unless accepted.include?(t_char)
      ret += t_char
    end
    return ret
  end
  
  # eg. "Daisy's House" => "DAISYS_HOUSE"
  def make_into_constant(used_consts = [], do_upcase = true)
    str = self.before_first("(")
    str = "x_#{str}" if str.starts_with_number?
    str = str.remove_puncts.sandwich.gsub(" ", "_")
	str = str.upcase if do_upcase
    str = "BLANK" if str == ""
    n_str = str
    count = 1
    # Avoids duplicated constants
    while used_consts.include?(n_str)
      n_str = str.u_push(count)
      count += 1
    end
    return n_str
  end
  
  def count(sub)
    r = 0
    ret = self
    while ret.include?(sub)
      r += 1
      ret = ret.after_first(sub)
    end
    return r
  end
  
  def palindrome?
    if self.length % 2 == 0
      iters = self.length / 2
    else
      iters = (self.length - 1) / 2
    end
    for i in 0...iters
      return false unless self[i, 1] == self[self.length - 1 - i, 1]
    end
    return true
  end
  
  def lhs(splitter = "_")
    return self.split(splitter)[0]
  end
  
  def mhs(splitter = "_")
    return self.split(splitter)[1] || self
  end
  
  def rhs(splitter = "_")
    return self.split(splitter)[-1]
  end
  
  def a
    if self.starts_with_vowel?
      return _INTL("an")
    else
      return _INTL("a")
    end
  end
  
  def s
    if self.ends_with?("s")
      return _INTL("{1}'", self)
    else
      return _INTL("{1}'s", self)
    end
  end
  
  def count_amount(sub_str)
    ret = 0
    t_self = self.clone
    while t_self.include?(sub_str)
      t_self = t_self.after_first(sub_str)
      ret += 1
    end
    return ret
  end
  
  def to_alphabet_int
    ret = 0
    strs = [
      "8NFH", "UIVJ", "2AQZ",
      "0TKM", "PRXE", "O79G",
      "B5CD", "S41L", "63WY"
    ]
    for s in 0...self.length
      c = self[s, 1]
      strs.each_with_index do |ss, i|
        next unless ss.include?(c)
        ret += i * (strs.length ** s)
        break
      end
    end
    return ret
  end
end