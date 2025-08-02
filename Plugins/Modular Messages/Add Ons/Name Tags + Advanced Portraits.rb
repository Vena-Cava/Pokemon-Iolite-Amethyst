#=============================================================================
# Name Tags/Advanced Portraits
# Modified and Ported to v21 By Swdfm
# Originally By Mr.Gela
# With help from Golisopod User, mej71 and battlelegendblue
#-------------------------------
# How to use:
#-------------------------------
# = Install Swdfm's Modular Messages Plugin
#   - This should already be on there anyway
# - Ensure FaceWindowVX is not used in any other Plugin
#   - Would be surprised if it was, but worth checking!
#-------------------------------
# Changes made to v20 port of Mr. Gela's script:
#-------------------------------
# - Moved all settings to a module called Gela_Settings
# - Following settings now work:
#   - Default Alignment
#   - Default Windowskin
#   - Default Windowskin Dark
#   - Minimum Name Tag Window Width
# - Added following settings:
#   - Horizontal Gap Between Portrait and Screen Edges
#   - Vertical Gap Between Portrait and Message Box
#   - The size of the portraits (border and picture)
# - Removed the following redundant settings:
#   - Default Font
#   - Default Font Size
# - Removed all unnecessary methods from page
# - Slightly adjusted default portrait window sizes
# - Made compatible with v21
# ~Swdfm 2024-11-02
#-------------------------------
# Control Names
#-------------------------------
# - \ml[PORTRAIT_FILE] shows a portrait on the left
#   with the given path
# - \ml on its own shows a portrait on the left
#   with the previous left PORTRAIT_FILE
# - \mr[PORTRAIT_FILE] and \mr are as above, but with the right
# PORTRAIT_FILE is found in Graphics/Pictures/
#  or a new folder called Graphics/Faces/
# - \xn[NAME] shows a name tag with NAME as the text on it
# - \xn on its own shows a name tag with the
#    previous defined NAME as its text
# - \dxn[NAME] and \dxn are as above, but with the defined DEFAULT_WINDOWSKIN_DARK if applicable
#-------------------------------
# Settings
#-------------------------------
module Gela_Settings
#-------------------------------
# Shift to name tag window x in positive pixels
# Only done when creating window
  OFFSET_NAME_X = 0
#-------------------------------
# As above, but with y
  OFFSET_NAME_Y = 0 #
#-------------------------------
# Text Alignment for Name Tag
#   left align is 0 or left
#   center align is 1 or center or centre
#   right align is 2 or right
#   symbol or string is allowed
# new: this setting now works!
# new: allowed for non ints ~Swdfm
  DEFAULT_ALIGNMENT = :centre
#-------------------------------
# The windowskin used for name tags
# Path is Graphics/Windowskins/
# Set to nil for standard text windowskin
# NOTE: Apparently Gela has the windowskins
#  in his old script, but I don't have them ~Swdfm
  DEFAULT_WINDOWSKIN = nil # "nmbx"
  DEFAULT_WINDOWSKIN_DARK = nil # "xndark"
#-------------------------------
# Set for the minimum width of the name tag window
  NAME_TAG_MIN_WIDTH = 180
#-------------------------------
# The gap (px) between the edge of the screen and
#  the edge of the portraits
#  Symmetrical
  PORTRAIT_GAP_EDGE = 16
#-------------------------------
# The gap (px) between the top of the messagebox and
#  the bottom of the portraits
  PORTRAIT_GAP_HEIGHT = 0
#-------------------------------
# The size of the portrait window and picture
# [width of window, height of window, width of picture, height of window]
  PORTRAIT_SIZES = [224, 224, 192, 192]
  
  module_function
#-------------------------------
# Allows multiple options to be entered for DEFAULT_ALIGNMENT
  def default_align
    ret = DEFAULT_ALIGNMENT
    return ret if ret.is_a?(Integer)
    case ret.to_s.downcase
    when "left" then return 0
    when "right" then return 2
    end
    return 1
  end
end

#-------------------------------
# "New" Method to display name tag window
def pbDisplayNameWindow(msgwindow, dark, param)
  a_str = ["al>", "ac>", "ar>"][Gela_Settings.default_align]
  name_window = Window_AdvancedTextPokemon.new("<" + a_str + param.to_s + "</" + a_str)
  w_str = dark ? Gela_Settings::DEFAULT_WINDOWSKIN_DARK : Gela_Settings::DEFAULT_WINDOWSKIN
  if w_str
    name_window.setSkin("Graphics/Windowskins/" + w_str)
  end
  # colortag = getSkinColor(msgwindow.windowskin, 0, true)
  # name_window.text = colortag + name_window.text
  name_window.resizeToFit(name_window.text, Graphics.width)
  m_width = Gela_Settings::NAME_TAG_MIN_WIDTH
  name_window.width = m_width if name_window.width < m_width
  name_window.y = msgwindow.y - name_window.height
  if name_window.y + name_window.height > msgwindow.y + msgwindow.height
    # msgwindow at top. puts name tag underneath
    name_window.y = msgwindow.y + msgwindow.height
  end
  name_window.x += Gela_Settings::OFFSET_NAME_X
  name_window.y += Gela_Settings::OFFSET_NAME_Y
  name_window.viewport = msgwindow.viewport
  name_window.z = msgwindow.z + 20
  return name_window
end

#-------------------------------
# FaceWindowVX Class Override
class FaceWindowVX < SpriteWindow_Base
  def initialize(face, sizes = nil)
    @sizes = sizes || [128, 128, 96, 96]
    # self.windowskin = nil
    super(0, 0, @sizes[0], @sizes[1])
    faceinfo = face.split(",")
    facefile = pbResolveBitmap("Graphics/Faces/" + faceinfo[0])
    facefile = pbResolveBitmap("Graphics/Pictures/" + faceinfo[0]) if !facefile
    self.contents&.dispose
    @faceIndex = faceinfo[1].to_i
    @facebitmaptmp = AnimatedBitmap.new(facefile)
    @facebitmap = Bitmap.new(@sizes[2], @sizes[3])
    @facebitmap.blt(
      0, 0, @facebitmaptmp.bitmap,
      Rect.new(
        (@faceIndex % 4) * @sizes[2],
        (@faceIndex / 4) * @sizes[3],
        @sizes[2], @sizes[3]
      )
    )
    self.contents = @facebitmap
  end
  
  def update
    super
    if @facebitmaptmp.totalFrames > 1 # was 77
      @facebitmaptmp.update
      @facebitmap.blt(
        0, 0, @facebitmaptmp.bitmap,
        Rect.new(
          (@faceIndex % 4) * @sizes[2],
          (@faceIndex / 4) * @sizes[3],
          @sizes[2], @sizes[3]
        )
      )
    end
  end
end

#-------------------------------
# New FaceWindowVX Class for Advanced Portraits
class FaceWindowVXNew < FaceWindowVX
  def initialize(face)
    sizes = Gela_Settings::PORTRAIT_SIZES
    super(face, sizes)
  end
end

#-------------------------------
# GameTemp
# Stores name within name tag
#  in case of next time
class Game_Temp
  attr_accessor :name_tag
  attr_accessor :port_path_left
  attr_accessor :port_path_right
end

#-------------------------------
# Gets last stored name tag
#  or stores name tag name
def pbAdjustNameTag(param)
  if param == ""
    return $game_temp.name_tag || param
  end
  $game_temp.name_tag = param
  return param
end

#-------------------------------
# Gets last stored portrait path
#  or stores portrait path name
def pbAdjustPortrait(param, is_right = false)
  if param == ""
    if is_right ; return $game_temp.port_path_right || param
    else ; return $game_temp.port_path_left || param
    end
  end
  if is_right ; $game_temp.port_path_right = param
  else ; $game_temp.port_path_left = param
  end
  return param
end

#=============================================================================
# For Modular Messages
#-------------------------------
# Control Handlers: Name Tags
Modular_Messages::Controls.add("xn", {
  "both" => true,
  "before_appears" => proc { |hash, param|
    param = pbAdjustNameTag(param)
    hash["windows_name"]&.dispose
    hash["windows_name"] = pbDisplayNameWindow(hash["msg_window"],
          hash["current_control"] == "dxn", param)
    hash["windows_name"].z = hash["msg_window"].z + 20
  },
  "during_loop" => proc { |hash, param|
    param = pbAdjustNameTag(param)
    hash["windows_name"]&.dispose
    hash["windows_name"] = pbDisplayNameWindow(hash["msg_window"],
          hash["current_control"] == "dxn", param)
    hash["windows_name"].viewport = hash["msg_window"].viewport
    hash["windows_name"].z        = hash["msg_window"].z + 20
  }
})

Modular_Messages::Controls.copy("xn", "dxn")

#-------------------------------
# Control Handlers: Advanced Portraits
Modular_Messages::Controls.add("ml", {
  "both" => true,
  "before_appears" => proc { |hash, param|
    d = hash["current_control"] == "ml" ? "left" : "right"
    param = pbAdjustPortrait(param, d == "right")
      s = "windows_face_" + d
    hash[s]&.dispose
    hash[s] = FaceWindowVXNew.new(param)
    gap = Gela_Settings::PORTRAIT_GAP_EDGE
    hash[s].x = d == "left" ? gap : Graphics.width - hash[s].width - gap
    hash[s].y = hash["msg_window"].y - hash[s].height
    hash[s].y -= Gela_Settings::PORTRAIT_GAP_HEIGHT
    hash[s].viewport = hash["msg_window"].viewport
    hash[s].z = hash["msg_window"].z + 10
  },
  "during_loop" => proc { |hash, param|
    d = hash["current_control"] == "ml" ? "left" : "right"
    param = pbAdjustPortrait(param, d == "right")
      s = "windows_face_" + d
    hash[s]&.dispose
    hash[s] = FaceWindowVXNew.new(param)
    pbPositionNearMsgWindow(hash[s], hash["msg_window"], :left)
    gap = Gela_Settings::PORTRAIT_GAP_EDGE
    hash[s].x = d == "left" ? gap : Graphics.width - hash[s].width - gap
    hash[s].y = hash["msg_window"].y - hash[s].height
    hash[s].y -= Gela_Settings::PORTRAIT_GAP_HEIGHT
    hash[s].viewport = hash["msg_window"].viewport
    hash[s].z = hash["msg_window"].z + 10
  }
})

Modular_Messages::Controls.copy("ml", "mr")