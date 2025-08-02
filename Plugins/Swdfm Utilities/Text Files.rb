#=============================================================================
# Swdfm Utilites - Text Filesv  
# Last Updated: 2023-12-04
#=============================================================================
module Swd
  # Ignores new lines, and any line with first significant character of "#"
  def self.format_line(line, flags = [])
    for a, b in [
      ["\r", ""],
      ["\n", ""],
      ["\t", "    "]
    ]
      line.gsub!(a, b)
    end
    if flags.include?(:STRICT)
      line = line.before_first("#")
    end
    return line if line == ""
    if flags.include?(:SANDWICH)
      line = line.sandwich
    end
    return line
  end
  
  # Reads all text in a .txt file
  def self.read_txt(path)
    path += ".txt" unless path.ends_with?(".txt")
    return File.readlines(path)
  end
  
  # Reads all text in a .txt file
  def self.read_txt_neat(path, strict = false)
    lines = self.read_txt(path)
    ret = []
    flags = strict ? [:STRICT, :SANDWICH] : [:SANDWICH]
    for line in lines
      f_line = self.format_line(line, flags)
      next if f_line == ""
      next if f_line.unblanked.starts_with?("#")
      ret.push(f_line)
    end
    return ret
  end
  
  # Reads all text in a PBS .txt file
  def self.read_pbs(path)
    path = "PBS/" + path unless path.starts_with?("PBS/")
    return self.read_txt(path)
  end
  
  def self.read_pbs_neat(path, strict = false)
    path = "PBS/" + path unless path.starts_with?("PBS/")
    return self.read_txt_neat(path, strict)
  end
  
  # Clears a text file. Makes one if needed.
  def self.clear_txt_file(file)
    file += ".txt" unless file.ends_with?(".txt")
    File.open(file, "wb") { |f|
      f.write("")
    }
  end
  
  # Writes a line and appends it to a file
  def self.write_line(line, file)
    file += ".txt" unless file.ends_with?(".txt")
    File.open(file, "ab") { |f|
      f.write(line + "\r\n")
    }
  end
  
  # Gets an array and dumps it in a .txt file
  def self.dump_txt(lines, file)
    file += ".txt" unless file.ends_with?(".txt")
    self.clear_txt_file(file)
    File.open(file, "wb") { |f|
      for line in lines
        f.write(line + "\n")
      end
    }
  end
  
  def self.lines
    return Swd.read_txt("infile")
  end
  
  def self.dump(t)
    dump_txt(t, "outfile")
  end
end