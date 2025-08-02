#=============================================================================
# Swdfm Utilites - Scripts
# Last Updated: 2023-12-04
#=============================================================================
module Swd
  # Writes all RPG Maker Xp Scripts in one big .txt file
  def self.write_all_scripts
    scripts = []
    File.open("Data/Scripts_1.rxdata") do |file|
      scripts = Marshal.load(file)
    end
    path = "Outputs/"
    Dir.mkdir(path) rescue nil
    File.open("#{path}scripts_full.txt", "wb") { |f|
      for script in scripts
        f.write("#{self.bigline}\n")
        str = "#{script[1]}\n"
        f.write("# Script Page: " + str)
        f.write("#{self.bigline}\n")
        scr = Zlib::Inflate.inflate(script[2]).force_encoding(Encoding::UTF_8)
        f.write("#{scr.gsub("\t", "    ")}\n")
        # script[2] = Zlib::Deflate.deflate(code) #,   Zlib::FINISH)
      end
    }
  end
  
  # Writes All Plugins in one big .txt file
  def self.write_all_plugins
    path = "Outputs/"
    Dir.mkdir(path) rescue nil
    File.open("#{path}plugins_full.txt", "wb") { |f|
      plugin_scripts = load_data("Data/PluginScripts.rxdata")
      plugin_scripts.each do |plugin|
        plugin[2].each do |script|
          f.write("#{self.bigline}\n")
          str = "#{plugin[0]}/#{script[0]}\n"
          f.write("# Plugin Page: " + str)
          f.write("#{self.bigline}\n")
          scr = Zlib::Inflate.inflate(script[1]).force_encoding(Encoding::UTF_8)
          f.write("#{scr.gsub("\t", "    ")}\n")
        end
      end
    }
  end
  
  def self.pbsline
    return "#-------------------------------"
  end
  
  def self.bigline
    return "#==============================================================================="
  end
  
  def self.replace_scripts(hash, ins_hash = {})
    return unless $DEBUG
    scripts = []
    File.open("Data/Scripts.rxdata") do |file|
      scripts = Marshal.load(file)
    end
    File.open("Data/Scripts_Spare.rxdata", "wb") { |f|
      Marshal.dump(scripts, f)
    }
    for script in scripts
      code = Zlib::Inflate.inflate(script[2]).force_encoding(Encoding::UTF_8)
      for k, v in hash
        code.gsub!(k, v)
      end
      for k, v in ins_hash
        next if code.include?(v)
        code.gsub!(k, v)
      end
      script[2] = Zlib::Deflate.deflate(code) #, Zlib::FINISH)
    end
    # Save the script!
    File.open("Data/Scripts.rxdata", "wb") { |f|
      Marshal.dump(scripts, f) 
    }
    pbMessage("Scripts have all been replaced!")
  end
  
  def self.open_plugins(state = :neaten, param = nil)
    plugin_scripts = load_data("Data/PluginScripts.rxdata")
    p_hash = {}
    for p, v in PluginManager.getPluginOrder[1]
      p_hash[v[:name]] = v[:dir]
    end
    plugin_scripts.each do |plugin|
      plugin[2].each do |script|
        path = p_hash[plugin[0]].to_s + "/" + script[0].to_s
        File.open(path, "wb") { |f|
          scr = Zlib::Inflate.inflate(script[1]).force_encoding(Encoding::UTF_8)
          case state
          when :neaten
            scr.gsub!("\r\n", "\n")
            scr.gsub!("\t", "    ")
          when :replace
            param.keys.sort!{ |b, a|
              a.length <=> b.length
            }
            for k, v in param
              scr.gsub!(k, v)
            end
          end
          f.write(scr.to_s)
        }
      end
    end
  end
  
  def self.neaten_plugins
    open_plugins
  end
  
  def self.replace_plugins(hash)
    open_plugins(:replace, hash)
  end
end