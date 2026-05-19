module Keybinds
  DEVICE_KEYBOARD = :keyboard
  DEVICE_GAMEPAD  = :gamepad

  @last_device = DEVICE_KEYBOARD

  @last_button_states = {}

  @repeat_count = {}

  ACTIONS = {}
  
  @consume_until_released = {}

  def self.consume_until_released(action)
    @consume_until_released[action] = true
  end
  
  GetAsyncKeyState = Win32API.new("user32", "GetAsyncKeyState", ["i"], "i")
  GetForegroundWindow = Win32API.new("user32", "GetForegroundWindow", [], "i")
  GetWindowThreadProcessId = Win32API.new("user32", "GetWindowThreadProcessId", ["i", "p"], "i")
  GetCurrentProcessId = Win32API.new("kernel32", "GetCurrentProcessId", [], "i")

  def self.game_window_focused?
    hwnd = GetForegroundWindow.call
    pid_buffer = [0].pack("L")
    GetWindowThreadProcessId.call(hwnd, pid_buffer)
    foreground_pid = pid_buffer.unpack("L")[0]
    return foreground_pid == GetCurrentProcessId.call
  end

  KEYBOARD_KEYS = {
    # Control keys
    :BACKSPACE => 0x08,
    :TAB       => 0x09,
    :ENTER     => 0x0D,
    :SHIFT     => 0x10,
    :CTRL      => 0x11,
    :ALT       => 0x12,
    :PAUSE     => 0x13,
    :CAPSLOCK  => 0x14,
    :ESC       => 0x1B,
    :SPACE     => 0x20,
    :PGUP      => 0x21,
    :PGDN      => 0x22,
    :END       => 0x23,
    :HOME      => 0x24,
    :LEFT      => 0x25,
    :UP        => 0x26,
    :RIGHT     => 0x27,
    :DOWN      => 0x28,
    :INSERT    => 0x2D,
    :DELETE    => 0x2E,

    # Number row
    :NUM0 => 0x30,
    :NUM1 => 0x31,
    :NUM2 => 0x32,
    :NUM3 => 0x33,
    :NUM4 => 0x34,
    :NUM5 => 0x35,
    :NUM6 => 0x36,
    :NUM7 => 0x37,
    :NUM8 => 0x38,
    :NUM9 => 0x39,

    # Letters
    :A => 0x41, :B => 0x42, :C => 0x43, :D => 0x44,
    :E => 0x45, :F => 0x46, :G => 0x47, :H => 0x48,
    :I => 0x49, :J => 0x4A, :K => 0x4B, :L => 0x4C,
    :M => 0x4D, :N => 0x4E, :O => 0x4F, :P => 0x50,
    :Q => 0x51, :R => 0x52, :S => 0x53, :T => 0x54,
    :U => 0x55, :V => 0x56, :W => 0x57, :X => 0x58,
    :Y => 0x59, :Z => 0x5A,

    # Windows keys
    :LWIN => 0x5B,
    :RWIN => 0x5C,

    # Numpad
    :NUMPAD0 => 0x60,
    :NUMPAD1 => 0x61,
    :NUMPAD2 => 0x62,
    :NUMPAD3 => 0x63,
    :NUMPAD4 => 0x64,
    :NUMPAD5 => 0x65,
    :NUMPAD6 => 0x66,
    :NUMPAD7 => 0x67,
    :NUMPAD8 => 0x68,
    :NUMPAD9 => 0x69,
    :MULTIPLY => 0x6A,
    :ADD      => 0x6B,
    :SUBTRACT => 0x6D,
    :DECIMAL  => 0x6E,
    :DIVIDE   => 0x6F,

    # Function keys
    :F1  => 0x70,
    :F2  => 0x71,
    :F3  => 0x72,
    :F4  => 0x73,
    :F5  => 0x74,
    :F6  => 0x75,
    :F7  => 0x76,
    :F8  => 0x77,
    :F9  => 0x78,
    :F10 => 0x79,
    :F11 => 0x7A,
    :F12 => 0x7B,

    # Symbols
    :SEMICOLON    => 0xBA,
    :PLUS         => 0xBB,
    :COMMA        => 0xBC,
    :MINUS        => 0xBD,
    :PERIOD       => 0xBE,
    :SLASH        => 0xBF,
    :TILDE        => 0xC0,
    :LBRACKET     => 0xDB,
    :BACKSLASH    => 0xDC,
    :RBRACKET     => 0xDD,
    :APOSTROPHE   => 0xDE
  }
  
  KEYBOARD_BUTTONS = {
    :use      => [:C, :SPACE, :ENTER],
    :back     => [:X, :ESC],
    :action   => [:Z],
    :special  => [:F],
    :up       => [:UP, :W],
    :down     => [:DOWN, :S],
    :left     => [:LEFT, :A],
    :right    => [:RIGHT, :D],
    :jumpup   => [:Q, :PGUP],
    :jumpdown => [:E, :PGDN]
  }

  DEFAULT_KEYBOARD_BUTTONS = KEYBOARD_BUTTONS.clone
  
  GAMEPAD_LT = 15
  GAMEPAD_RT = 16

  GAMEPAD_BUTTONS = {
    :use     => 0,   # A
    :back    => 1,   # B
    :action  => 6,   # Start
    :special => 3,   # Y
    :jumpup  => 9,   # LB
    :jumpdown=> 10,  # RB
    :up      => 11,
    :down    => 12,
    :left    => 13,
    :right   => 14
  }
  DEFAULT_GAMEPAD_BUTTONS = GAMEPAD_BUTTONS.clone
  
  GAMEPAD_BUTTON_NAMES = {
    # Xbox
    0 => {
      0 => "A",
      1 => "B",
      2 => "X",
      3 => "Y",
      4 => "View",
      6 => "Menu",
      7 => "LS",
      8 => "RS",
      9 => "LB",
      10 => "RB",
      11 => "D-Up",
      12 => "D-Down",
      13 => "D-Left",
      14 => "D-Right",
      15 => "LT",
      16 => "RT"
    },
    # PlayStation
    1 => {
      0 => "Cross",
      1 => "Circle",
      2 => "Square",
      3 => "Triangle",
      4 => "Share",
      6 => "Options",
      7 => "L3",
      8 => "R3",
      9 => "L1",
      10 => "R1",
      11 => "D-Up",
      12 => "D-Down",
      13 => "D-Left",
      14 => "D-Right",
      15 => "L2",
      16 => "R2"
    },
    # Nintendo
    2 => {
      0 => "B",
      1 => "A",
      2 => "Y",
      3 => "X",
      4 => "-",
      6 => "+",
      7 => "LS",
      8 => "RS",
      9 => "L",
      10 => "R",
      11 => "D-Up",
      12 => "D-Down",
      13 => "D-Left",
      14 => "D-Right",
      15 => "ZL",
      16 => "ZR"
    }
  }
  
  STICK_DEADZONE = 0.35

  KEYBOARD_NAMES = {
    :use     => "Z/Enter",
    :back    => "X/Esc",
    :action  => "Shift",
    :special => "D",
    :aux1    => "Q",
    :aux2    => "W",
    :jumpup  => "A",
    :jumpdown=> "S"
  }
  
  def self.keyboard_key_pressed?(key)
    return false if !game_window_focused?

    code = KEYBOARD_KEYS[key]
    return false if !code

    return (GetAsyncKeyState.call(code) & 0x8000) != 0
  end
  
  def self.wait_for_release(action)
    while press?(action)
      Graphics.update
      Input.update
    end

    @last_press_states[action] = false if defined?(@last_press_states)
    @consume_until_released.delete(action) if defined?(@consume_until_released)
  end
  
  def self.wait_for_all_released
    loop do
      Graphics.update
      Input.update

      any_pressed = false

      KEYBOARD_BUTTONS.each_key do |action|
        any_pressed = true if press?(action)
      end

      GAMEPAD_BUTTONS.each_key do |action|
        any_pressed = true if press?(action)
      end

      break if !any_pressed
    end

    @last_press_states.clear if defined?(@last_press_states)
    @repeat_count.clear if defined?(@repeat_count)
  end
  
  def self.keyboard_key_trigger?(key)
    @raw_key_last ||= {}

    current = keyboard_key_pressed?(key)
    last = @raw_key_last[key] || false

    @raw_key_last[key] = current

    return current && !last
  end
  
  def self.controller_button_pressed?(button)
    states = Input::Controller.raw_button_states rescue []
    return true if states[button]

    trigger = Input::Controller.axes_trigger rescue [0.0, 0.0]
    return true if button == GAMEPAD_LT && trigger[0].abs > 0.35
    return true if button == GAMEPAD_RT && trigger[1].abs > 0.35

    return false
  end
  
  def self.update
    # Detect controller buttons/sticks/triggers
    if defined?(Input::Controller) && Input::Controller.connected?
      buttons = Input::Controller.raw_button_states
      left    = Input::Controller.axes_left rescue [0.0, 0.0]
      right   = Input::Controller.axes_right rescue [0.0, 0.0]
      trigger = Input::Controller.axes_trigger rescue [0.0, 0.0]

      if buttons.any? { |b| b } ||
        left.any? { |v| v.abs > 0.25 } ||
        right.any? { |v| v.abs > 0.25 } ||
        trigger.any? { |v| v.abs > 0.25 }

        @last_device = DEVICE_GAMEPAD
        return
      end
    end

    # Detect keyboard
    if Input.dir4 != 0 ||
       Input.press?(Input::USE) ||
       Input.press?(Input::BACK) ||
       Input.press?(Input::ACTION) ||
       Input.press?(Input::SPECIAL)

      @last_device = DEVICE_KEYBOARD
    end
  end
  
  @input_locked = false

  def self.lock_input
    @input_locked = true
  end

  def self.unlock_input
    @input_locked = false
    @last_button_states.clear if defined?(@last_button_states)
    @last_press_states.clear if defined?(@last_press_states)
    @repeat_count.clear if defined?(@repeat_count)
    @last_repeat_states.clear if defined?(@last_repeat_states)
    Input.update
  end

  def self.input_locked?
    return @input_locked
  end

  def self.last_device
    return @last_device
  end

  def self.gamepad?
    return @last_device == DEVICE_GAMEPAD
  end
  
  def self.controller_layout
    return $PokemonSystem&.controller_layout || 0
  end

  def self.controller_button_name(button)
    names = GAMEPAD_BUTTON_NAMES[controller_layout] || GAMEPAD_BUTTON_NAMES[0]
    return names[button] || "Button #{button}"
  end

  def self.keyboard?
    return @last_device == DEVICE_KEYBOARD
  end
  
  def self.keyboard_button_name(action)
    keys = KEYBOARD_BUTTONS[action] || []
    return "?" if keys.empty?
    return keys.map { |key| key.to_s.gsub("_", " ") }.join("/")
  end

  def self.button_name(action)
    if gamepad?
      button = GAMEPAD_BUTTONS[action]
      return controller_button_name(button)
    end

    return keyboard_button_name(action)
  end
  
  def self.dir4
    return 2 if press?(:down)
    return 4 if press?(:left)
    return 6 if press?(:right)
    return 8 if press?(:up)

    return 0
  end

  def self.dir8
    down  = press?(:down)
    left  = press?(:left)
    right = press?(:right)
    up    = press?(:up)

    return 1 if down && left
    return 3 if down && right
    return 7 if up && left
    return 9 if up && right
    return 2 if down
    return 4 if left
    return 6 if right
    return 8 if up

    return 0
  end
  
  def self.press?(action)
    return false if @input_locked

    # Controller buttons + analog stick
    if defined?(Input::Controller) && Input::Controller.connected?
      left = Input::Controller.axes_left rescue [0.0, 0.0]

      case action
      when :left
        return true if left[0] < -STICK_DEADZONE
      when :right
        return true if left[0] > STICK_DEADZONE
      when :up
        return true if left[1] < -STICK_DEADZONE
      when :down
        return true if left[1] > STICK_DEADZONE
      end

      button = GAMEPAD_BUTTONS[action]
      if button
        return true if controller_button_pressed?(button)
      end
    end
    
    keys = KEYBOARD_BUTTONS[action] || []
    return true if keys.any? { |key| keyboard_key_pressed?(key) }

    # Keyboard fallback
    input = ACTIONS[action]
    return Input.press?(input) if input

    return false
  end

  def self.trigger?(action)
    return false if @input_locked

    @last_press_states ||= {}
    @consume_until_released ||= {}

    current = press?(action)

    if @consume_until_released[action]
      if current
        @last_press_states[action] = current
        return false
      else
        @consume_until_released.delete(action)
      end
    end

    last = @last_press_states[action] || false
    @last_press_states[action] = current

    if current && !last
      @consume_until_released[action] = true
      return true
    end

    return false
  end

  @repeat_count = {}

  def self.repeat?(action)
    return false if @input_locked

    @repeat_count ||= {}
    @last_repeat_states ||= {}

    current = press?(action)
    last    = @last_repeat_states[action] || false

    @last_repeat_states[action] = current

    if current && !last
      @repeat_count[action] = 0
      return true
    end

    if current
      @repeat_count[action] ||= 0
      @repeat_count[action] += 1
      return true if @repeat_count[action] >= 12 && @repeat_count[action] % 4 == 0
    else
      @repeat_count[action] = 0
    end

    return false
  end

  def self.set_controller_binding(action, new_button)
    old_button = GAMEPAD_BUTTONS[action]

    other_action = nil
    GAMEPAD_BUTTONS.each do |act, button|
      next if act == action
      if button == new_button
        other_action = act
        break
      end
    end

    if other_action
      GAMEPAD_BUTTONS[other_action] = old_button
    end

    GAMEPAD_BUTTONS[action] = new_button
  end

  def self.set_keyboard_binding(action, slot, key)
    KEYBOARD_BUTTONS[action] ||= []
    KEYBOARD_BUTTONS[action][slot] = key
  end
  
  def self.clear_keyboard_binding(action, slot)
    KEYBOARD_BUTTONS[action] ||= []
    KEYBOARD_BUTTONS[action][slot] = nil
  end
  
  def self.wait_for_keyboard_key
    lock_input
    chosen_key = nil

    begin
      # Wait for old keys to be released.
      loop do
        Graphics.update
        Input.update
        break if !KEYBOARD_KEYS.keys.any? { |key| keyboard_key_pressed?(key) }
      end

      # Wait for a fresh key.
      loop do
        Graphics.update
        Input.update

        KEYBOARD_KEYS.each_key do |key|
          if keyboard_key_pressed?(key)
            chosen_key = key
            break
          end
        end

        break if chosen_key
      end

      # Wait for chosen key to be released.
      loop do
        Graphics.update
        Input.update
        break if !keyboard_key_pressed?(chosen_key)
      end
    ensure
      unlock_input
    end

    return chosen_key
  end

  def self.wait_for_controller_button
    lock_input

    chosen_button = nil

    begin
      # 1. Wait for all old buttons to be released.
      loop do
        Graphics.update
        Input.update

        states = Input::Controller.raw_button_states rescue []
        break if !states.any? { |pressed| pressed }
      end

      # 2. Wait for a fresh button press.
      loop do
        Graphics.update
        Input.update

        states = Input::Controller.raw_button_states rescue []
        states.each_with_index do |pressed, i|
          if pressed
            chosen_button = i
            break
          end
        end
        
        trigger = Input::Controller.axes_trigger rescue [0.0, 0.0]

        if trigger[0].abs > 0.35
          chosen_button = GAMEPAD_LT
        elsif trigger[1].abs > 0.35
          chosen_button = GAMEPAD_RT
        end

        break if chosen_button
      end

      # 3. IMPORTANT: wait for that button to be released too.
      loop do
        Graphics.update
        Input.update

        states = Input::Controller.raw_button_states rescue []
        break if !controller_button_pressed?(chosen_button)
      end

    ensure
      @last_button_states.clear if defined?(@last_button_states)
      @repeat_count.clear if defined?(@repeat_count)
      Input.update
      unlock_input
    end

    return chosen_button
  end
end