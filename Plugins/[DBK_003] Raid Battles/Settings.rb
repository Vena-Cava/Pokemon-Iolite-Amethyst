#===============================================================================
# Message types.
#===============================================================================
# Adds Adventure Map data to the list of message types. Renumber if necessary.
#-------------------------------------------------------------------------------
module MessageTypes
  ADVENTURE_MAP_NAMES        = 33
  ADVENTURE_MAP_DESCRIPTIONS = 34
end

#===============================================================================
# Settings.
#===============================================================================
module Settings
  #-----------------------------------------------------------------------------
  # Stores the path name for the graphics utilized by this plugin.
  #-----------------------------------------------------------------------------
  RAID_GRAPHICS_PATH = "Graphics/Plugins/Raid Battles/"
  
  #-----------------------------------------------------------------------------
  # Pastebin URL for online raid distributions. Enter your URL in the string.
  #-----------------------------------------------------------------------------
  LIVE_RAID_EVENT_URL = ""
  
  #-----------------------------------------------------------------------------
  # Base values for Raid Battles.
  #-----------------------------------------------------------------------------
  RAID_BASE_PARTY_SIZE = 3
  RAID_BASE_TURN_LIMIT = 10
  RAID_BASE_KNOCK_OUTS = 4
end