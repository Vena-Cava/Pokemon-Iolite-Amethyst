#=============================================================================
# Initial Hashes
# By Swdfm
# As part of Modular Messages Pack
# 2024-11-02
#=============================================================================
# Sets up initial variables in the hash
# Can be added later, but here to save clutter!
# Don't touch unless you know your stuff!
#-------------------------------
module Modular_Messages
#-------------------------------
# Initial hash
  INITIAL_HASH = {
    "appear_duration" => 0.5,
    "appear_timer_start" => nil,
    "disappear_duration" => 0.5,
    "have_special_close" => false,
    "special_close_se" => "",
    "commands" => nil,
    "cmd_variable" => 0,
    "cmd_if_cancel" => 0,
    "delete_control" => false,
    "start_se" => nil,
    "auto_resume" => false,
    "result" => nil,
    "break_loop" => false
  }
  
  module_function
#-------------------------------
# Second Initial Hash
# For variables that are movable through script!
  def merge_init_hash
    @@hash.merge!({
      "line_count" => (Graphics.height > 400 ? 3 : 2),
      "dark_skin" => isDarkWindowskin(@@hash["msg_window"].windowskin)
    })
  end
end