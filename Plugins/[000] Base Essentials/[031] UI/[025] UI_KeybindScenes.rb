#===============================================================================
# Keybind menu scene
#===============================================================================
class Window_KeybindList < Window_DrawableCommand
  BASE_COLOR              = Color.new(80, 80, 88)
  SHADOW_COLOR            = Color.new(160, 160, 168)
  SEL_NAME_BASE_COLOR    = Color.new(192, 120, 0)
  SEL_NAME_SHADOW_COLOR  = Color.new(248, 176, 80)
  SELECTED_VALUE_COLOR    = Color.new(248, 48, 24)
  SELECTED_VALUE_SHADOW   = Color.new(248, 136, 128)

  attr_accessor :device
  attr_accessor :slot_index
  attr_accessor :working_keyboard_buttons
  attr_accessor :working_gamepad_buttons

  def initialize(scene, commands, device, working_gamepad_buttons, working_keyboard_buttons, x, y, width, height)
    @scene = scene
    @commands = commands
    @slot_index = 0
    @device = device
    @working_gamepad_buttons = working_gamepad_buttons || {}
    @working_keyboard_buttons = working_keyboard_buttons || {}
    super(x, y, width, height)
  end

  def itemCount
    return @commands.length
  end
  
  def lineHeight
    return 34
  end

  def drawItem(index, _count, rect)
    rect = drawCursor(index, rect)
    rect.y += 2
    action_data = @commands[index]

    if !action_data.is_a?(Array)
      pbDrawShadowText(self.contents, rect.x, rect.y, rect.width, rect.height,
        action_data, BASE_COLOR, SHADOW_COLOR)
      return
    end

    action = action_data[0]
    name   = action_data[1]

    name_base   = (index == self.index) ? SEL_NAME_BASE_COLOR   : BASE_COLOR
    name_shadow = (index == self.index) ? SEL_NAME_SHADOW_COLOR : SHADOW_COLOR

    pbDrawShadowText(self.contents, rect.x, rect.y, 180, rect.height,
      name, name_base, name_shadow)

    if @device == :keyboard
      keys = @working_keyboard_buttons[action] || []
      x = rect.x + 190

      4.times do |i|
        key = keys[i] ? keys[i].to_s : "---"
        color  = (i == @slot_index && index == self.index) ? SELECTED_VALUE_COLOR : BASE_COLOR
        shadow = (i == @slot_index && index == self.index) ? SELECTED_VALUE_SHADOW : SHADOW_COLOR

        pbDrawShadowText(self.contents, x, rect.y, 80, rect.height, key, color, shadow)
        x += 88
      end
    else
      button_index = (@working_gamepad_buttons || {})[action]

      if button_index
        bitmap = RPG::Cache.load_bitmap("Graphics/UI/", "controller_buttons")

        src_rect = Rect.new(button_index * 32,$PokemonSystem.controller_layout * 32,32,32)

        draw_x = rect.x + 190
        draw_y = rect.y + ((rect.height - 32) / 2) + 2

        self.contents.blt(draw_x, draw_y, bitmap, src_rect)
      end
    end
  end
end

class KeybindListScene
  BASE_COLOR          = Color.new(248, 248, 248)
  SHADOW_COLOR        = Color.new(48, 48, 48)
  SEL_NAME_BASE_COLOR    = Color.new(192, 120, 0)
  SEL_NAME_SHADOW_COLOR  = Color.new(248, 176, 80)
  SELECTED_BASE_COLOR   = Color.new(248, 48, 24)
  SELECTED_SHADOW_COLOR = Color.new(248, 136, 128)
  
  ACTIONS = [
    [:use,     _INTL("Confirm")],
    [:back,    _INTL("Back")],
    [:action,  _INTL("Menu")],
    [:special, _INTL("Special")],
    [:up,      _INTL("Up")],
    [:down,    _INTL("Down")],
    [:left,    _INTL("Left")],
    [:right,   _INTL("Right")],
    [:jumpup,  _INTL("Page Up")],
    [:jumpdown,_INTL("Page Down")]
  ]

  def initialize(device)
    @device = device
  end

  def pbStartScene
    @input_lock = 0
    @slot_index = 0   # 0 = first key, 1 = second key
    @max_slots = 4
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
	  @working_gamepad_buttons = Keybinds::GAMEPAD_BUTTONS.clone
    @working_keyboard_buttons = Marshal.load(Marshal.dump(Keybinds::KEYBOARD_BUTTONS))

    title = (@device == :keyboard) ? _INTL("Keyboard Bindings") : _INTL("Controller Bindings")

    addBackgroundOrColoredPlane(@sprites, "bg", "optionsbg", Color.new(192, 200, 208), @viewport)

    @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
      title, 0, -16, Graphics.width, 64, @viewport
    )
    @sprites["title"].back_opacity = 0

    commands = ACTIONS.clone
    commands.push(_INTL("Reset to Defaults"))
    commands.push(_INTL("Confirm"))
    commands.push(_INTL("Close"))

    @sprites["cmds"] = Window_KeybindList.new(
      self, commands, @device, @working_gamepad_buttons, @working_keyboard_buttons,
      0, @sprites["title"].height - 16,
      Graphics.width, Graphics.height - (@sprites["title"].height - 16)
    )
    @sprites["cmds"].rowHeight = 34
    @sprites["cmds"].refresh
    @sprites["cmds"].slot_index = @slot_index
    @sprites["cmds"].working_keyboard_buttons = @working_keyboard_buttons
    @sprites["cmds"].x = 0
    @sprites["cmds"].y = @sprites["title"].height - 16
    @sprites["cmds"].width = Graphics.width
    @sprites["cmds"].height = Graphics.height - @sprites["cmds"].y
    @sprites["cmds"].viewport = @viewport

    pbFadeInAndShow(@sprites) { pbUpdate }
  end
    
  def set_working_controller_binding(action, new_button)
    old_button = @working_gamepad_buttons[action]

    other_action = nil
    @working_gamepad_buttons.each do |act, button|
      next if act == action
      if button == new_button
        other_action = act
        break
      end
    end

    @working_gamepad_buttons[other_action] = old_button if other_action
    @working_gamepad_buttons[action] = new_button
  end
  
  def show_rebind_prompt(text)
    @sprites["help"] ||= Window_UnformattedTextPokemon.newWithSize(
      "", 0, Graphics.height - 96, Graphics.width, 96, @viewport
    )
    @sprites["help"].viewport = @viewport
    @sprites["help"].visible = true
    @sprites["help"].text = text
  end

  def clear_rebind_prompt
    return if !@sprites["help"]

    @sprites["help"].dispose
    @sprites.delete("help")
  end

  def pbMain
    loop do
      Graphics.update
      Input.update
      Keybinds.update if defined?(Keybinds)

      if @input_lock > 0
        @input_lock -= 1
        pbUpdate
        next
      end

      if @device == :keyboard && @sprites["cmds"].index < ACTIONS.length
        if Keybinds.trigger?(:left)
          pbPlayDecisionSE
          @slot_index -= 1
          @slot_index = @max_slots - 1 if @slot_index < 0
          @sprites["cmds"].slot_index = @slot_index
          refresh_commands
          next
        elsif Keybinds.trigger?(:right)
          pbPlayDecisionSE
          @slot_index += 1
          @slot_index = 0 if @slot_index >= @max_slots
          @sprites["cmds"].slot_index = @slot_index
          refresh_commands
          next
        end
      end
      
      pbUpdate

      if Keybinds.trigger?(:back)
        break
      elsif Keybinds.trigger?(:use)
        index = @sprites["cmds"].index

        reset_index   = ACTIONS.length
        confirm_index = ACTIONS.length + 1
        close_index   = ACTIONS.length + 2

        if index == reset_index
          pbPlayDecisionSE

          if @device == :keyboard
            @working_keyboard_buttons = Marshal.load(
              Marshal.dump(Keybinds::DEFAULT_KEYBOARD_BUTTONS)
            )
          else
            @working_gamepad_buttons = Keybinds::DEFAULT_GAMEPAD_BUTTONS.clone
          end

          refresh_commands
          next
        end

        if index == confirm_index
          pbPlayDecisionSE

          if @device == :keyboard
            Keybinds::KEYBOARD_BUTTONS.clear

            @working_keyboard_buttons.each do |action, keys|
              Keybinds::KEYBOARD_BUTTONS[action] = keys
            end
          else
            Keybinds::GAMEPAD_BUTTONS.clear

            @working_gamepad_buttons.each do |action, button|
              Keybinds::GAMEPAD_BUTTONS[action] = button
            end
          end

          break
        end

        if index == close_index
          pbPlayCloseMenuSE
          break
        end

        action = ACTIONS[index][0]
        pbPlayDecisionSE

        if @device == :controller
          show_rebind_prompt(_INTL("Press a controller button for {1}.", ACTIONS[index][1]))
          button = Keybinds.wait_for_controller_button
          clear_rebind_prompt
          set_working_controller_binding(action, button)
          refresh_commands
          Input.update
          @input_lock = 30
        else
          show_rebind_prompt(_INTL("Press a keyboard key for {1}. Backspace clears. Escape cancels.", ACTIONS[index][1]))

          key = Keybinds.wait_for_keyboard_key

          clear_rebind_prompt

          if key == :BACKSPACE
            @working_keyboard_buttons[action] ||= []
            @working_keyboard_buttons[action][@slot_index] = nil
          elsif key != :ESC
            @working_keyboard_buttons[action] ||= []
            @working_keyboard_buttons[action][@slot_index] = key
          end

          refresh_commands
          Input.update
          @input_lock = 30
        end
      end
    end
  end

  def refresh_commands
    commands = ACTIONS.clone
    commands.push(_INTL("Reset to Defaults"))
    commands.push(_INTL("Confirm"))
    commands.push(_INTL("Close"))

    @sprites["cmds"].slot_index = @slot_index
    @sprites["cmds"].working_keyboard_buttons = @working_keyboard_buttons
    @sprites["cmds"].working_gamepad_buttons = @working_gamepad_buttons
    @sprites["cmds"].commands = commands if @sprites["cmds"].respond_to?(:commands=)
    @sprites["cmds"].refresh
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
# Screen wrapper
#===============================================================================
class KeybindListScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbMain
    @scene.pbEndScene
  end
end