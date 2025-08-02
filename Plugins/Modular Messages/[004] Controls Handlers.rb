#=============================================================================
# Controls Handlers
# By Swdfm
# As part of Modular Messages Pack
# 2024-11-02
#=============================================================================
# Controls Handlers
# To add your own control, add a handler
# Look at the readme.txt for more info!
#-------------------------------
# Wait X/20 seconds
Modular_Messages::Controls.add("wt", {
  "on_text_chunks" => proc { |hash|
    hash["text_chunks"][hash["index"]] += "\2"
  },
  "during_loop" => proc { |hash, param|
    param = param.sub(/\A\s+/, "").sub(/\s+\z/, "")
    hash["msg_window"].waitcount += param.to_i / 20.0
  }
})

#-------------------------------
# !/exclam
# Not sure what this does!
Modular_Messages::Controls.add("exclam", {
  "solo" => true,
  "on_text_chunks" => proc { |hash|
    hash["text_chunks"][hash["index"]] += "\1"
  }
})

#-------------------------------
# Appear Timer Start
Modular_Messages::Controls.add("op", {
  "solo" => true,
  "before_appears" => proc { |hash, param|
    hash["appear_timer_start"] = System.uptime
  }
})

#-------------------------------
# Special Close SE
Modular_Messages::Controls.add("cl", {
  "both" => true,
  "before_appears" => proc { |hash, param|
    # fix (vanilla): '$' can match end of line as well
    hash["text"] = hash["text"].sub(/\001\z/, "")
    hash["have_special_close"] = true
    hash["special_close_se"] = param
  }
})

#-------------------------------
# Summons Face Window (From Graphics/Pictures/)
Modular_Messages::Controls.add("f", {
  "before_appears" => proc { |hash, param|
    hash["windows_face"]&.dispose
    hash["windows_face"] = PictureWindow.new("Graphics/Pictures/#{param}")
  },
  "during_loop" => proc { |hash, param|
    hash["windows_face"]&.dispose
    hash["windows_face"] = PictureWindow.new("Graphics/Pictures/#{param}")
    pbPositionNearMsgWindow(hash["windows_face"], hash["msg_window"], :left)
    hash["windows_face"].viewport = hash["msg_window"].viewport
    hash["windows_face"].z        = hash["msg_window"].z
  }
})

#-------------------------------
# Summons Face Window (RPGVX)
Modular_Messages::Controls.add("ff", {
  "before_appears" => proc { |hash, param|
    hash["windows_face"]&.dispose
    hash["windows_face"] = FaceWindowVX.new(param)
  },
  "during_loop" => proc { |hash, param|
    hash["windows_face"]&.dispose
    hash["windows_face"] = FaceWindowVX.new(param)
    pbPositionNearMsgWindow(hash["windows_face"], hash["msg_window"], :left)
    hash["windows_face"].viewport = hash["msg_window"].viewport
    hash["windows_face"].z        = hash["msg_window"].z
  }
})

#-------------------------------
# Show Choices
Modular_Messages::Controls.add("ch", {
  "before_appears" => proc { |hash, param|
    cmds = param.clone
    # TODO Var can be a script constant
    hash["cmd_variable"] = pbCsvPosInt!(cmds)
    hash["cmd_if_cancel"] = pbCsvField!(cmds).to_i
    hash["commands"] = []
    while cmds.length > 0
      hash["commands"].push(pbCsvField!(cmds))
    end
  }
})

#-------------------------------
# Wait X/20 seconds, no pause
# NOTE: ^ is covered here too, but no waiting
Modular_Messages::Controls.add("wtnp", {
  "on_text_chunks" => proc { |hash|
    hash["text_chunks"][hash["index"]] += "\2"
  },
  "before_appears" => proc { |hash, param|
    # vanilla fix: '$'can match end of line as well
    hash["text"] = hash["text"].sub(/\001\z/, "")
  },
  "during_loop" => proc { |hash, param|
    param = param.sub(/\A\s+/, "").sub(/\s+\z/, "")
    hash["msg_window"].waitcount = param.to_i / 20.0
    hash["auto_resume"] = true
  }
})

#-------------------------------
# Play Sound Effect
Modular_Messages::Controls.add("se", {
  "before_appears" => proc { |hash, param|
     next unless hash["controls_args"][2] == 0
     hash["start_se"] = param
     hash["delete_control"] = true
  },
  "during_loop" => proc { |hash, param|
    pbSEPlay(pbStringToAudioFile(param))
  }
})

#-------------------------------
# Display gold window
Modular_Messages::Controls.add("g", {
  "solo" => true,
  "during_loop" => proc { |hash, param|
    hash["windows_gold"]&.dispose
    hash["windows_gold"] = pbDisplayGoldWindow(hash["msg_window"])
  }
})

#-------------------------------
# Display coins window
Modular_Messages::Controls.add("cn", {
  "solo" => true,
  "during_loop" => proc { |hash, param|
    hash["windows_coins"]&.dispose
    hash["windows_coins"] = pbDisplayCoinsWindow(hash["msg_window"], hash["windows_gold"])
  }
})

#-------------------------------
# Display battle points window
Modular_Messages::Controls.add("pt", {
  "solo" => true,
  "during_loop" => proc { |hash, param|
    hash["windows_bp"]&.dispose
    hash["windows_bp"] = pbDisplayBattlePointsWindow(hash["msg_window"])
  }
})

#-------------------------------
# Position Picture at top
Modular_Messages::Controls.add("wu", {
  "solo" => true,
  "during_loop" => proc { |hash, param|
    hash["at_top"] = true
    hash["msg_window"].y = 0
    pbPositionNearMsgWindow(hash["windows_face"], hash["msg_window"], :left)
    next unless hash["appear_timer_start"]
    hash["msg_window"].y = lerp(y_start, y_end,
    hash["appear_duration"],
    hash["appear_timer_start"],
    System.uptime)
  }
})

#-------------------------------
# Position Picture in middle
Modular_Messages::Controls.add("wm", {
  "solo" => true,
  "during_loop" => proc { |hash, param|
    hash["at_top"] = false
    hash["msg_window"].y = (Graphics.height - hash["msg_window"].height) / 2
    pbPositionNearMsgWindow(hash["windows_face"], hash["msg_window"], :left)
  }
})

#-------------------------------
# Position Picture at bottom
Modular_Messages::Controls.add("wd", {
  "solo" => true,
  "during_loop" => proc { |hash, param|
    hash["at_top"] = false
    hash["msg_window"].y = Graphics.height - hash["msg_window"].height
    pbPositionNearMsgWindow(hash["windows_face"], hash["msg_window"], :left)
    next unless hash["appear_timer_start"]
    hash["msg_window"].y = lerp(y_start, y_end,
       hash["appear_duration"],
       hash["appear_timer_start"],
       System.uptime)
  }
})

#-------------------------------
# Change text speed
Modular_Messages::Controls.add("ts", {
  "during_loop" => proc { |hash, param|
    hash["msg_window"].textspeed = (param == "") ? 0 : param.to_i / 80.0
  }
})

#-------------------------------
# Wait 0.25 seconds
Modular_Messages::Controls.add("fstp", {
  "solo" => true,
  "during_loop" => proc { |hash, param|
    hash["msg_window"].waitcount += 0.25
  }
})

#-------------------------------
# Wait 1 second
Modular_Messages::Controls.add("line", {
  "solo" => true,
  "during_loop" => proc { |hash, param|
    hash["msg_window"].waitcount += 1
  }
})

#-------------------------------
# Play ME
Modular_Messages::Controls.add("me", {
  "during_loop" => proc { |hash, param|
    pbMEPlay(pbStringToAudioFile(param))
  }
})