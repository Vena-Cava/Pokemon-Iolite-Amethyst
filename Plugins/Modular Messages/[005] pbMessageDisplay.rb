#=============================================================================
# pbMessageDisplay Override
# By Swdfm
# As part of Modular Messages Pack
# 2024-11-02
#=============================================================================
# Overridden pbMessageDisplay method
# Ensure this is the dominant method!
# Otherwise, don't touch!
#-------------------------------
def pbMessageDisplay(msg_window, message, letter_by_letter = true, command_proc = nil, &block)
  hash = {
    "text" => message.clone,
    "msg_window" => msg_window,
    "let_by_let" => letter_by_letter,
    "command_proc" => command_proc
  }
  return Modular_Messages.run(hash, &block)
end