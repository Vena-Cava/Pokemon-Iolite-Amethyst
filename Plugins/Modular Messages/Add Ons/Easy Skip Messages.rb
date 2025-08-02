#=============================================================================
# Easy Skip Script
# Originally By Amethyst & Kurotsune
# Adjusted for Modular Messages
# ~Swdfm 2024-11-03
#=============================================================================
EASY_SKIP_MESSAGES = false
module Modular_Messages
  alias es_upon_trigger upon_trigger
  def upon_trigger
	if EASY_SKIP_MESSAGES
      if Input.press?(Input::BACK)
	    unless @@hash["msg_window"].textspeed == -999
          @@hash["old_txt_speed"] = @@hash["msg_window"].textspeed
	    end
        @@hash["msg_window"].textspeed = -999
        @@hash["msg_window"].update
	    return es_upon_trigger(true)
	  elsif @@hash["old_txt_speed"]
	    @@hash["msg_window"].textspeed = @@hash["old_txt_speed"]
      end
    end
	es_upon_trigger
  end
  module_function :es_upon_trigger, :upon_trigger
end
