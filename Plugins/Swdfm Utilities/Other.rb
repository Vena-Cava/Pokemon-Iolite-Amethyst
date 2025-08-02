#=============================================================================
# Swdfm Utilites - Other
# 2024-11-02
#=============================================================================
module Swd
  # Gets percentage based on numerator and denominator
  def self.get_percentage(num, denom)
    return num * 100 / denom
  end
  
  # Inserts Hash, with values of Integers.
  # Returns the key that corresponds to the right number
  def self.weighted_hash(hash, amount = 0)
    not_array = false
    if amount == 0
      amount = 1
      not_array = true
    end
    denom = 0
    for i in hash.values
      denom += i
    end
    nums = []
    ret  = []
    amount.times do
      nums.push(rand(denom))
      ret.push(nil)
    end
    for k in hash.keys.shuffle
      for n_i in 0...nums.length
        next if ret[n_i]
        num = n_i
        if num < hash[k]
          ret[n_i] = k
          break unless nums.include?(nil)
          next
        end
        nums[n_i] = num - hash[k]
      end
    end
    ret = ret[0] if not_array
    return ret
  end
  
  # Inputs a symbol, outputs the colour object
  def self.get_colour(symbol, opacity = 255)
    hash = {
      # Grayscale
      :COOL_BLACK => [ 57,  69,  81],
      :BLACK      => [  0,   0,   0],
      :DARK_GRAY  => [ 63,  63,  63],
      :GRAY       => [127, 127, 127],
      :LIGHT_GRAY => [191, 191, 191],
      :WHITE      => [255, 255, 255],
      :COOL_WHITE => [206, 206, 206],
      # Reds
      :RED         => [255,   0,   0],
      :COOL_RED    => [255,  63,  63],
      :PASTEL_RED  => [255, 127, 127],
      :PINK        => [255, 191, 191],
      :ROSE        => [255,   0, 110],
      :COOL_ROSE   => [255,  63, 146],
      :PASTEL_ROSE => [255, 127, 182],
      :SKIN_TONE   => [255, 191, 218],
      :BURGUNDY    => [127,   0,   0],
      # Oranges/Browns
      :ORANGE        => [255, 106,   0],
      :COOL_ORANGE   => [255, 140,  63],
      :PASTEL_ORANGE => [255, 178, 127],
      :PEACH         => [255, 216, 191],
      :BROWN         => [127,  51,   0],
      :COOL_BROWN    => [124,  68,  31],
      :PASTEL_BROWN  => [124,  87,  62],
      :MUD           => [124, 106,  93],
      # Yellow
      :YELLOW        => [255, 216,   0],
      :COOL_YELLOW   => [255, 223,  63],
      :PASTEL_YELLOW => [255, 233, 127],
      :APRICOT       => [255, 244, 191],
      # Greens
      :GREEN        => [  0, 127,   0],
      :COOL_GREEN   => [ 31, 124,  40],
      :SPRUCE       => [ 62, 124,  68],
      :DEEP_SPRUCE  => [ 93, 124,  96],
      :LIME_GREEN   => [182, 255,   0],
      :PASTEL_LIME  => [218, 255, 127],
      :LIGHT_GREEN  => [  0, 255,   0],
      :PASTEL_GREEN => [165, 255, 127],
      # Teals/Cyans
      :TEAL        => [  0, 255, 124],
      :COOL_TEAL   => [ 63, 255, 168],
      :PASTEL_TEAL => [127, 255, 197],
      :SNOW        => [191, 255, 226],
      :CYAN        => [  0, 255, 255],
      :COOL_CYAN   => [ 63, 255, 255],
      :PASTEL_CYAN => [127, 255, 255],
      :ICE         => [191, 255, 255],
      # Blues
      :MARINE        => [  0, 148, 255],
      :COOL_MARINE   => [ 63, 175, 255],
      :PASTEL_MARINE => [127, 201, 255],
      :CLOUD         => [191, 228, 255],
      :BLUE          => [  0,   0, 255],
      :COOL_BLUE     => [ 63,  63, 255],
      :PASTEL_BLUE   => [127, 127, 255],
      :LAVENDER      => [191, 191, 255],
      :INDIGO        => [ 72,   0, 255],
      :COOL_INDIGO   => [114,  63, 255],
      :PASTEL_INDIGO => [161, 127, 255],
      :LILAC         => [207, 191, 255],
      # Purples
      :PURPLE         => [178,   0, 255],
      :COOL_PURPLE    => [194,  63, 255],
      :PASTEL_PURPLE  => [214, 127, 255],
      :BURDOCK        => [234, 191, 255],
      :MAGENTA        => [255,   0, 255],
      :COOL_MAGENTA   => [255,  63, 255],
      :PASTEL_MAGENTA => [255, 127, 255],
      :PUCE           => [204, 136, 153],
      # Custom
    }
    col = hash[symbol.upcase] || hash[:BLACK]
    return Color.new(*col, opacity)
  end
  
  # eg. "one/two/three.txt" => ["one/two/", "three.txt"]
  # Used for Bitmaps
  def self.split_file(file)
    unless file.ends_with?("/") || file.ends_with?(".png")
      file += ".png"
    end
    p = file
    f = ""
    unless file.ends_with?("/") # Isn't just a directory
      split_file = file.split(/[\\\/]/)
      f = split_file.pop
      p = split_file.join("/") + "/"
    end
    return [p, f]
  end
  
  def self.save_data(f, data)
    f += ".dat" unless f.ends_with?(".dat")
    File.delete(f) if FileTest.exist?(f)
    save_data(f, data)
  end
  
  # Reads all files in directory
  def self.dir_files(directory, formats = "txt")
    unless formats.is_a?(Array)
      formats = "*." + formats
      formats = [formats]
    end
    count = 0
    files = []
    Dir.chdir(directory){
      for i in 0...formats.length
        Dir.glob(formats[i]){|f| files.push(f) }
      end
    }
    return files
  end
end

# Allows you to use eval without risking the game crashing
def secure_eval(str, return_if_fail = nil)
  if eval("defined?(#{str})")
    ret = eval(str)
    return ret
  end
  return return_if_fail
end

# Returns the correct case of the constant in a mod
# If no const defined, returns nil
def const_defined_nocase?(mod, const_name)
  for const in mod.constants
    next unless const.to_s.casecmp(const_name.to_s).zero?
    return const.to_s
  end
  return nil
end

# Slight Utilities for Handler Hashes
class HandlerHash_Swd < HandlerHash
  def trigger_sect(id, s, *args)
    return nil unless self[id]
    handler = self[id][s]
    return handler&.call(*args)
  end
end