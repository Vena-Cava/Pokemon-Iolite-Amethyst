#=============================================================================
# Controls Methods
# By Swdfm
# As part of Modular Messages Pack
# 2024-11-02
#=============================================================================
# Methods dealing with the controls
# If you want to add your own controls with a
#  different trigger point, pay attention to these!
# Heavily involves regular expressions!
#-------------------------------
module Modular_Messages
  module_function
#-------------------------------
# Gathers Text Chunks and Commands for processing
# Text Chunks are the strings between commands
  def gather_text_chunks
    @@hash["controls"] = []
    @@hash["text_chunks"] = []
    cmds_0 = []
    cmds_1 = []
    Controls.each do |ctrl, c_hash|
      # Commands in the form \command[brackets]
      if !c_hash["solo"]
        cmds_0.push(ctrl)
      end
      # Commands just in the form \command
      if c_hash["solo"] || c_hash["both"]
        cmds_1.push(ctrl)
      end
    end
#-------------------------------
    # Forms Controls Regular Expression
    # vanilla: "f|ff|ts|cl|me|se|wt|wtnp|ch"
    # allows [] brackets
    cmds_0 = "\\\\(#{cmds_0.join("|")})\\[([^\\]]*)\\]"
    # vanilla: "g|cn|pt|wd|wm|op|cl|wu"
    # also allows .|!^
    cmds_1 += [".", "|", "!", "^"]
    cmds_1 = cmds_1.map { |cmd| Regexp.escape(cmd) }.join("|")
    cmds_1 = "\\\\(#{cmds_1})"
    # note: \i means not case sensitive!
    reg_exp = /(?:#{cmds_0}|#{cmds_1})/i
    while @@hash["text"][reg_exp]
      @@hash["text_chunks"].push($~.pre_match)
      if $~[1]
        @@hash["controls"].push([$~[1].downcase, $~[2], -1])
      else
        @@hash["controls"].push([$~[3].downcase, "", -1])
      end
      @@hash["text"] = $~.post_match
    end
    @@hash["text_chunks"].push(@@hash["text"])
    @@hash["text_chunks"].each do |chunk|
      chunk.gsub!(/\005/, "\\")
    end
  end
  
#-------------------------------
# Runs Controls to change @@hash["text"] chunks
  def controls_on_text_chunks
    text_len = 0
    @@hash["controls"].length.times do |i|
      control = @@hash["controls"][i][0]
      control = "wtnp" if [".", "|"].include?(control)
      # stops regexp being weird!
      control = "exclam" if ["!"].include?(control)
      @@hash["index"] = i
      @@hash["current_control"] = control
      Controls.trigger_sect(control, "on_text_chunks", @@hash)
      text_len += toUnformattedText(@@hash["text_chunks"][i]).scan(/./m).length
      @@hash["controls"][i][2] = text_len
    end
  end
  
#-------------------------------
# Runs Controls Before Window Appears
  def controls_before_appears
    @@hash["controls"].length.times do |i|
      control = @@hash["controls"][i][0]
      control = "wtnp" if control == "^"
      param = @@hash["controls"][i][1]
      @@hash["controls_args"] = @@hash["controls"][i]
      @@hash["current_control"] = control
      Controls.trigger_sect(control, "before_appears", @@hash, param)
      next unless @@hash["delete_control"]
      @@hash["controls"][i] = nil
      @@hash["delete_control"] = false
    end
  end

#-------------------------------
# Runs Controls in the loop
  def controls_during_loop
    @@hash["controls"].length.times do |i|
      next if !@@hash["controls"][i]
      if @@hash["controls"][i][2] > @@hash["msg_window"].position ||
         @@hash["msg_window"].waitcount != 0
        next
      end
      control = @@hash["controls"][i][0]
      control = "fstp" if control == "."
      control = "line" if control == "|"
      control = "wtnp" if control == "^"
      param = @@hash["controls"][i][1]
      param = "0" if control == "wtnp" && param == ""
      @@hash["controls_args"] = @@hash["controls"][i]
      @@hash["current_control"] = control
      Controls.trigger_sect(control, "during_loop", @@hash, param)
      @@hash["controls"][i] = nil
    end
  end
end