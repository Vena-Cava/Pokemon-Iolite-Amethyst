#=============================================================================
# Text Replacement
# By Swdfm
# As part of Modular Messages Pack
# 2024-11-02
#=============================================================================
# Methods dealing with text formatting
# Order of run methods is important!
# Be careful modifying, as some lines important!
#-------------------------------
module Modular_Messages
  module_function
#-------------------------------
# Main Text Replacement Function
  def replace_text
    replace_initial
    replace_game_data # new!
    replace_scripts # new!
    replace_player_name
    replace_player_money
    # \n
    @@hash["text"].gsub!(/\\n/i, "\n")
    replace_colours_direct
    replace_player_gender
    replace_windowskin
    replace_colours_id
    replace_variables
    replace_lines
    replace_colours_final
  end
  
#-------------------------------
# Initial Text Replacement Method
  def replace_initial
    # \sign[something] gets turned into
    @@hash["text"].gsub!(/\\sign\[([^\]]*)\]/i) do
      # \op\cl\ts[]\w[something]
      next "\\op\\cl\\ts[]\\w[" + $1 + "]"
    end
    @@hash["text"].gsub!(/\\\\/, "\5")
    @@hash["text"].gsub!(/\\1/, "\1")
    if $game_actors
      @@hash["text"].gsub!(/\\n\[([1-8])\]/i) { next $game_actors[$1.to_i].name }
    end
  end
  
#-------------------------------
# Player Name
  def replace_player_name
    @@hash["text"].gsub!(/\\pn/i,  $player.name) if $player
  end
  
#-------------------------------
# Player Money
  def replace_player_money
    @@hash["text"].gsub!(/\\pm/i,  _INTL("${1}", $player.money.to_s_formatted)) if $player
  end
  
#-------------------------------
# Specific colours
  def replace_colours_direct
    @@hash["text"].gsub!(/\\\[([0-9a-f]{8,8})\]/i) { "<c2=" + $1 + ">" }
  end
  
#-------------------------------
# Player Gender
# \pg, \pog, \b, \r
  def replace_player_gender
    @@hash["text"].gsub!(/\\pg/i,  "\\b") if $player&.male?
    @@hash["text"].gsub!(/\\pg/i,  "\\r") if $player&.female?
    @@hash["text"].gsub!(/\\pg/i,  "\\g") if !$player&.female? && !$player&.male?
    @@hash["text"].gsub!(/\\pog/i, "\\r") if $player&.male?
    @@hash["text"].gsub!(/\\pog/i, "\\b") if $player&.female?
    @@hash["text"].gsub!(/\\pog/i, "\\g") if !$player&.female? && !$player&.male?
    @@hash["text"].gsub!(/\\pg/i,  "")
    @@hash["text"].gsub!(/\\pog/i, "")
    male_text_tag = shadowc3tag(MessageConfig::MALE_TEXT_MAIN_COLOR, MessageConfig::MALE_TEXT_SHADOW_COLOR)
    female_text_tag = shadowc3tag(MessageConfig::FEMALE_TEXT_MAIN_COLOR, MessageConfig::FEMALE_TEXT_SHADOW_COLOR)
    nb_text_tag = shadowc3tag(MessageConfig::NB_TEXT_MAIN_COLOR, MessageConfig::NB_TEXT_SHADOW_COLOR)
    @@hash["text"].gsub!(/\\b/i, male_text_tag)
    @@hash["text"].gsub!(/\\r/i, female_text_tag)
    @@hash["text"].gsub!(/\\g/i, nb_text_tag)
  end
  
#-------------------------------
# Windowskins
# \w[WINDOWSKIN_NAME]
  def replace_windowskin
    @@hash["text"].gsub!(/\\[Ww]\[([^\]]*)\]/) do
      w = $1.to_s
      if w == ""
        @@hash["msg_window"].windowskin = nil
      else
        @@hash["msg_window"].setSkin("Graphics/Windowskins/#{w}", false)
      end
      next ""
    end
  end
  
#-------------------------------
# \c[0]... etc.
  def replace_colours_id
    @@hash["text"].gsub!(/\\c\[([0-9]+)\]/i) do
      next getSkinColor(@@hash["msg_window"].windowskin, $1.to_i, @@hash["dark_skin"])
    end
  end
  
#-------------------------------
# Variables in @@hash["text"]
# \v[1] etc.
# new: Works with script constants
# \v[VARIABLE_CONSTANT]
# NOTE: Also works with constants within a module
  def replace_variables
    loop do
      last_text = @@hash["text"].clone
      @@hash["text"].gsub!(/\\[Vv]\[([^\]]*)\]/) do
        w = $1.to_s
        v = ""
        if w.is_all_numbers?
           v = $game_variables[w.to_i]
        else
          if Object.const_defined?(w) &&
             eval(w).is_a?(Integer)
            v = $game_variables[eval(w)]
          end
        end
        next v.to_s
      end
      break if @@hash["text"] == last_text
    end
  end
  
#-------------------------------
# Scripts in Text!
# eg. \sc[$player.badge_count] -> "0"
# NOTE: Any script with [] in will not work!
# eg. \sc[$player.badges[0]] -> ERROR!
  def replace_scripts
    loop do
      last_text = @@hash["text"].clone
      echoln last_text
      @@hash["text"].gsub!(/\\sc\[([^\]]*)\]/i) do
        v = $1.to_s
        v = secure_eval(v, "")
        next v.to_s
      end
      break if @@hash["text"] == last_text
    end
  end
  
#-------------------------------
# GameData in Text!
  # eg. \species[castform] -> Castform
  # eg. \type[fire] -> Fire
  # eg. \itemplural[charcoal] -> Charcoals
  def replace_game_data
    loop do
      last_text = @@hash["text"].clone
      @@hash["text"].gsub!(/\\([a-zA-Z0-9_]+)\[([^\]]*)\]/) do
        lhs_init = $1.to_s
        rhs_init = $2.to_s
        lhs = lhs_init.downcase
        rhs = rhs_init.downcase
        cdn = const_defined_nocase?(GameData, lhs)
        if lhs.gsub("_", "").downcase.starts_with?("itemplural")
          # Item Plurals
          real_key = nil
          for k in GameData::Item.keys
            real_key = k if k.to_s.downcase == rhs
          end
          if real_key && GameData::Item.exists?(real_key)
            next GameData::Item.get(real_key).name_plural
          end
		  next ""
        elsif cdn # eg. GameData::Type
          gds = "GameData::#{cdn}"
          gd = eval(gds)
          if eval(gds + ".respond_to?(:get)")
            # Gets real case of key
            real_key = nil
            for k in gd.keys
              real_key = k if k.to_s.downcase == rhs
            end
            if real_key &&
              eval(gds + ".exists?(:#{real_key})")
              t_gds = gds + ".get(:#{real_key})"
              t_gd = eval(t_gds)
              if t_gd.respond_to?("name")
                # Finally confirmed as existing!
                next t_gd.name
              end
            end
          end
		  next ""
        end
        next "\\" + lhs_init + "[" + rhs_init + "]"
      end
      break if @@hash["text"] == last_text
    end
  end
  
#-------------------------------
# Sets number of lines of box
# eg. \l[5]
  def replace_lines
    loop do
      last_text = @@hash["text"].clone
      @@hash["text"].gsub!(/\\l\[([0-9]+)\]/i) do
        @@hash["line_count"] = [1, $1.to_i].max
        next ""
      end
      break if @@hash["text"] == last_text
    end
  end
  
#-------------------------------
# Chooses actual colour of message @@hash["text"]
  def replace_colours_final
    colortag = ""
    if $game_system && $game_system.message_frame != 0
      colortag = getSkinColor(@@hash["msg_window"].windowskin, 0, true)
    else
      colortag = getSkinColor(@@hash["msg_window"].windowskin, 0, @@hash["dark_skin"])
    end
    @@hash["text"] = colortag + @@hash["text"]
  end
end