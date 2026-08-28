#===============================================================================
# Meal Powers
#===============================================================================

module MealPowers
  MAX_ACTIVE = 3
  DEFAULT_DURATION = 30 * 60
  DEBUG = true

  # Types that should never appear as Meal Power options.
  EXCLUDED_TYPES = [
    :QMARKS,
    :STELLAR
  ]

  POWERS = {
    :ENCOUNTER   => "Encounter Power",
    :REPEL       => "Repel Power",
    :CATCHING    => "Catching Power",
    :EXP         => "Exp. Point Power",
    :BASEPOINT   => "Base Point Power",
    :STRENGTH    => "Strength Power",
    :ABILITY     => "Ability Power",
    :FRIENDSHIP  => "Friendship Power",
    :HATCHING    => "Hatching Power",
    :DAYCARE     => "Daycare Power",
    :LUCK        => "Luck Power",
    :BIGHAUL     => "Big Haul Power",
    :ITEMDROP    => "Item Drop Power",
    :HUMUNGO     => "Humungo Power",
    :TEENSY      => "Teensy Power",
    :SPARKLING   => "Sparkling Power",
    :TITLE       => "Title Power",
    :RAIDREWARD  => "Raid Reward Power",
    :RAIDOFFENSE => "Raid Offense Power",
    :RAIDDEFENSE => "Raid Defense Power",
    :RAIDSPEED   => "Raid Speed Power",
    :FISHING     => "Fishing Power",
    :FISHITEM    => "Fishing Item Power",
    :MONEY       => "Money Power",
    :BARGAINING  => "Bargaining Power"
  }
  
  TYPE_BASED_POWERS = [
    :ENCOUNTER,
    :REPEL,
    :EXP,
    :ITEMDROP,
    :HUMUNGO,
    :TEENSY,
    :SPARKLING
  ]

  STAT_BASED_POWERS = [
    :BASEPOINT,
    :STRENGTH
  ]
  
  OPTIONLESS_POWERS = [
    :CATCHING,
    :ABILITY,
    :FRIENDSHIP,
    :HATCHING,
    :DAYCARE,
    :LUCK,
    :BIGHAUL,
    :TITLE,
    :RAIDREWARD,
    :RAIDOFFENSE,
    :RAIDDEFENSE,
    :RAIDSPEED,
    :FISHING,
    :FISHITEM,
    :MONEY,
    :BARGAINING
  ]

  def self.types
    ret = [:ALL]

    GameData::Type.each do |type|
      next if EXCLUDED_TYPES.include?(type.id)
      next if type.pseudo_type

      ret.push(type.id)
    end

    return ret
  end
  STATS = [:ALL, :HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED]

  def self.data
    $PokemonGlobal.meal_powers ||= {
      :powers => [],
      :remaining => 0,
      :last_update => System.uptime
    }
    return $PokemonGlobal.meal_powers
  end

  def self.active
    return data[:powers] || []
  end

  def self.remaining
    return data[:remaining] || 0
  end

  def self.clear
    data[:powers] = []
    data[:remaining] = 0
    data[:last_update] = System.uptime
  end

  def self.apply(powers, duration = DEFAULT_DURATION)
    data[:powers] = powers[0, MAX_ACTIVE]
    data[:remaining] = duration
    data[:last_update] = System.uptime
    debug_print
  end

  def self.update_timer
    return if active.empty?
    return if remaining <= 0
    return if $game_temp.in_battle rescue false

    now = System.uptime
    last = data[:last_update] || now
    elapsed = now - last
    data[:last_update] = now
    return if elapsed <= 0

    data[:remaining] -= elapsed

    if data[:remaining] <= 0
      clear
    end
  end

  def self.has?(id, option = nil)
    return !get(id, option).nil?
  end

  def self.get(id, option = nil)
    active.each do |p|
      next if p[:id] != id
      next if option && p[:option] != option && p[:option] != :ALL
      return p
    end
    return nil
  end

  def self.level(id, option = nil)
    power = get(id, option)
    return power ? power[:level] : 0
  end

  def self.time_text
    total = remaining.to_i
    min = total / 60
    sec = total % 60
    return sprintf("%d:%02d", min, sec)
  end

  def self.display_lines
    return [] if active.empty?

    lines = []
    lines.push(sprintf("%-28s %5s", "Meal Powers", time_text))

    active.each do |p|
      name = POWERS[p[:id]] || p[:id].to_s

      if OPTIONLESS_POWERS.include?(p[:id])
        label = name
      else
        opt = p[:option] ? p[:option].to_s.gsub("_", " ").capitalize : "All"
        label = "#{name}: #{opt}"
      end

      lines.push(sprintf("%-28s Lv.%d", label, p[:level]))
    end

    return lines
  end

  def self.debug_print
    return if !DEBUG
    puts "========================================"
    puts "MEAL POWER DEBUG"
    puts display_lines.join("\n")
    puts "========================================"
  end
end

class PokemonGlobalMetadata
  attr_accessor :meal_powers
end

class Scene_Map
  alias mealpowers_update update
  def update
    mealpowers_update
    MealPowers.update_timer if $PokemonGlobal
  end
end

#===============================================================================
# Meal Power HUD for Voltseon's Pause Menu
#===============================================================================

class VPM_MealPowerHud < Component
  def should_draw?
    return true
  end

  def start_component(viewport, menu)
    super(viewport, menu)
    @sprites["mealpowers"] = BitmapSprite.new(Graphics.width, Graphics.height, viewport)
    @sprites["mealpowers"].z = 99999
    refresh
  end

  def refresh
    return if !@sprites["mealpowers"]

    bitmap = @sprites["mealpowers"].bitmap
    bitmap.clear
    return if MealPowers.active.empty?

    pbSetSmallFont(bitmap)

    base = Color.new(248, 248, 248)
    shadow = Color.new(72, 72, 72)

    x_label = 8
    y = 52
    line_height = 20

    labels = []
    values = []

    labels.push("Meal Powers")
    values.push(MealPowers.time_text)

    MealPowers.active.each do |p|
      name = MealPowers::POWERS[p[:id]] || p[:id].to_s

      if MealPowers::OPTIONLESS_POWERS.include?(p[:id])
        label = name
      else
        opt = p[:option] ? p[:option].to_s.gsub("_", " ").capitalize : "All"
        label = "#{name}: #{opt}"
      end

      labels.push(label)
      values.push("Lv.#{p[:level]}")
    end

    longest_width = 0
    labels.each do |label|
      width = bitmap.text_size(label).width
      longest_width = width if width > longest_width
    end

    x_value = x_label + longest_width + 64

    labels.each_with_index do |label, i|
      pbDrawTextPositions(bitmap, [
        [label, x_label, y, 0, base, shadow],
        [values[i], x_value, y, 1, base, shadow]
      ])
      y += line_height
    end
  end

  def update
    super if defined?(super)
    MealPowers.update_timer if $PokemonGlobal
    refresh
  end
end

if defined?(MENU_COMPONENTS) && !MENU_COMPONENTS.include?(:VPM_MealPowerHud)
  MENU_COMPONENTS.push(:VPM_MealPowerHud)
end

#===============================================================================
# Debug Menu
#===============================================================================

def pbDebugMealPowers
  powers = []
  duration = MealPowers::DEFAULT_DURATION

  params = ChooseNumberParams.new
  params.setRange(1, 999)
  params.setDefaultValue(30)
  minutes = pbMessageChooseNumber(_INTL("How many minutes should the Meal Powers last?"), params)
  minutes = [[minutes, 1].max, 999].min
  duration = minutes * 60

  3.times do |i|
    power_ids = MealPowers::POWERS.keys
    power_names = power_ids.map { |id| MealPowers::POWERS[id] }
    cmd = pbShowCommands(nil, power_names + [_INTL("None")], -1)
    break if cmd < 0 || cmd >= power_ids.length

    power_id = power_ids[cmd]
    option = nil

    if MealPowers::TYPE_BASED_POWERS.include?(power_id)
      types = MealPowers.types
      type_cmds = types.map do |t|
        t == :ALL ? "All Types" : GameData::Type.get(t).name
      end

      type_cmd = pbShowCommands(nil, type_cmds, -1)
      option = types[type_cmd] if type_cmd >= 0

    elsif MealPowers::STAT_BASED_POWERS.include?(power_id)
      stat_cmds = MealPowers::STATS.map { |s| s.to_s.gsub("_", " ").capitalize }
      stat_cmd = pbShowCommands(nil, stat_cmds, -1)
      option = MealPowers::STATS[stat_cmd] if stat_cmd >= 0
    end

    params = ChooseNumberParams.new
    params.setRange(1, 3)
    params.setDefaultValue(1)
    level = pbMessageChooseNumber(_INTL("Set the level for this power."), params)
    level = [[level, 1].max, 3].min

    powers.push({
      :id => power_id,
      :option => option || :ALL,
      :level => level
    })
  end

  MealPowers.apply(powers, duration)
  pbMessage(_INTL("Meal Powers applied."))
end

MenuHandlers.add(:debug_menu, :meal_powers_menu, {
  "name"        => _INTL("Meal Powers..."),
  "parent"      => :main,
  "description" => _INTL("Apply, view, or clear active Meal Powers."),
  "effect"      => proc {
    cmd = 0
    loop do
      cmds = [
        _INTL("Apply test Meal Powers"),
        _INTL("View active Meal Powers"),
        _INTL("Clear Meal Powers")
      ]
      cmd = pbShowCommands(nil, cmds, -1, cmd)
      break if cmd < 0
      case cmd
      when 0
        pbDebugMealPowers
      when 1
        pbMessage(MealPowers.display_lines.join("\n"))
      when 2
        MealPowers.clear
        pbMessage(_INTL("Meal Powers cleared."))
      end
    end
  }
})