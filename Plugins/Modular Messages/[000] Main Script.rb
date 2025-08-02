#=============================================================================
# Main Script
# By Swdfm
# As part of Modular Messages Pack
# 2024-11-01
#=============================================================================
# The main method
# Includes the loop
# Don't touch unless you know your stuff!
#-------------------------------
module Modular_Messages
  Controls = HandlerHash_Swd.new
  module_function
  
#-------------------------------
# The main method
  def run(hash)
    @@hash = hash.merge(INITIAL_HASH.clone)
    return nil unless @@hash["msg_window"]
    merge_init_hash
    upon_starting
#-------------------------------
# Text replacement
    replace_text
    gather_text_chunks
    controls_on_text_chunks
    @@hash["text"] = @@hash["text_chunks"].join
    controls_before_appears
#-------------------------------
# SE/Timers
    if @@hash["start_se"]
      pbSEPlay(pbStringToAudioFile(@@hash["start_se"]))
    elsif !@@hash["appear_timer_start"] && @@hash["let_by_let"]
      pbPlayDecisionSE
    end
    position_windows
#-------------------------------
    loop do
      move_msg_window
      controls_during_loop
      break if !@@hash["let_by_let"]
      Graphics.update
      Input.update
      update_loop
      break if @@hash["break_loop"]
      upon_trigger
      break if @@hash["break_loop"]
      pbUpdateSceneMap
      @@hash["msg_window"].update
      yield if block_given?
      check_break
      break if @@hash["break_loop"]
    end
#-------------------------------
    # Must call Input.update again to avoid extra triggers
    Input.update
    upon_after_loop
    dispose_windows
    upon_special_close
    return @@hash["result"]
  end
  
#-------------------------------
# Runs just after the hash being created
  def upon_starting
    @@hash["old_let_by_let"] = @@hash["msg_window"].letterbyletter
    @@hash["msg_window"].letterbyletter = (@@hash["let_by_let"]) ? true : false
    @@hash["msg_window"].waitcount = 0
  end
  
#-------------------------------
# Positions window(s)
  def position_windows
    pbRepositionMessageWindow(@@hash["msg_window"], @@hash["line_count"])
    if @@hash["windows_face"]
      pbPositionNearMsgWindow(@@hash["windows_face"], @@hash["msg_window"], :left)
      @@hash["windows_face"].viewport = @@hash["msg_window"].viewport
      @@hash["windows_face"].z = @@hash["msg_window"].z
    end
    @@hash["at_top"] = @@hash["msg_window"].y == 0
    @@hash["msg_window"].text = @@hash["text"]
  end

#-------------------------------
# Slightly Moves Message Window In During The Loop
  def move_msg_window
    return unless @@hash["appear_timer_start"]
    y_start = (@@hash["at_top"]) ? -@@hash["msg_window"].height : Graphics.height
    y_end = (@@hash["at_top"]) ? 0 : Graphics.height - @@hash["msg_window"].height
    @@hash["msg_window"].y = lerp(y_start, y_end,
       @@hash["appear_duration"],
       @@hash["appear_timer_start"],
       System.uptime)
    @@hash["appear_timer_start"] = nil if @@hash["msg_window"].y == y_end
  end
  
#-------------------------------
# Runs just after the graphical update in the loop
  def update_loop
    @@hash["windows_face"]&.update
    return unless @@hash["auto_resume"] && @@hash["msg_window"].waitcount == 0
    @@hash["msg_window"].resume if @@hash["msg_window"].busy?
    @@hash["break_loop"] = true unless @@hash["msg_window"].busy?
  end
  
#-------------------------------
# Checks to see if a trigger has been pressed
  def upon_trigger(allow_anyway = false)
    return unless Input.trigger?(Input::USE) ||
	   Input.trigger?(Input::BACK) ||
	   allow_anyway
    if @@hash["msg_window"].busy?
      pbPlayDecisionSE if @@hash["msg_window"].pausing?
      @@hash["msg_window"].resume
    elsif !@@hash["appear_timer_start"]
      @@hash["break_loop"] = true
    end
  end
  
#-------------------------------
# Checks at end of loop to see if it will break
  def check_break
    return if @@hash["msg_window"].busy?
    return unless !@@hash["let_by_let"] ||
       @@hash["command_proc"] ||
       @@hash["commands"]
    @@hash["break_loop"] = true
  end
  
#-------------------------------
# Makes internal changes before the end
  def upon_after_loop
    @@hash["msg_window"].letterbyletter = @@hash["old_let_by_let"]
    if @@hash["commands"]
      $game_variables[
        @@hash["cmd_variable"]
      ] = pbShowCommands(
         @@hash["msg_window"],
         @@hash["commands"],
         @@hash["cmd_if_cancel"])
      $game_map.need_refresh = true if $game_map
    end
    if @@hash["command_proc"]
      @@hash["result"] = @@hash["command_proc"].call(@@hash["msg_window"])
    end
  end
  
#-------------------------------
# Disposes Gold Windows etc.
  def dispose_windows
    for k, v in @@hash
      next unless k.starts_with?("windows")
      v&.dispose
    end
  end
  
#-------------------------------
# Runs upon closing the Message via special close
  def upon_special_close
    return unless @@hash["have_special_close"]
    pbSEPlay(pbStringToAudioFile(@@hash["special_close_se"]))
    @@hash["at_top"] = (@@hash["msg_window"].y == 0)
    y_start = (@@hash["at_top"]) ? 0 : Graphics.height - @@hash["msg_window"].height
    y_end = (@@hash["at_top"]) ? - @@hash["msg_window"].height : Graphics.height
    @@hash["disappear_timer_start"] = System.uptime
    loop do
      @@hash["msg_window"].y = lerp(y_start, y_end,
          @@hash["disappear_duration"],
         @@hash["disappear_timer_start"], 
         System.uptime)
      Graphics.update
      Input.update
      pbUpdateSceneMap
      @@hash["msg_window"].update
      break if @@hash["msg_window"].y == y_end
    end
  end
end