#===============================================================================
# Meal Powers - Humungo / Teensy Power
# Alters wild Pokémon scale values.
#===============================================================================

module MealPowers
  HUMUNGO_SCALE_MIN = {
    0 => nil,
    1 => 128,
    2 => 160,
    3 => 192
  }

  TEENSY_SCALE_MAX = {
    0 => nil,
    1 => 128,
    2 => 95,
    3 => 63
  }

  def self.humungo_level
    return level(:HUMUNGO, :ALL)
  end

  def self.teensy_level
    return level(:TEENSY, :ALL)
  end

  def self.size_power_type_matches?(pkmn, power_id)
    power = active.find { |p| p[:id] == power_id }
    return false if !power

    type = power[:option]
    return true if type == :ALL

    return pkmn.species_data.types.include?(type)
  end
end

EventHandlers.add(:on_wild_pokemon_created, :meal_power_size_powers,
  proc { |pkmn|
    next if !pkmn
    next if pkmn.egg?
    next if !pkmn.respond_to?(:scale)

    humungo = MealPowers.active.find { |p| p[:id] == :HUMUNGO }
    teensy  = MealPowers.active.find { |p| p[:id] == :TEENSY }

    next if !humungo && !teensy

    old_scale = pkmn.scale
    changed_by = nil

    if humungo && MealPowers.size_power_type_matches?(pkmn, :HUMUNGO)
      min_scale = MealPowers::HUMUNGO_SCALE_MIN[humungo[:level]]
      if min_scale && pkmn.scale < min_scale
        pkmn.scale = rand(min_scale..255)
        changed_by = humungo
      end
    end

    if teensy && MealPowers.size_power_type_matches?(pkmn, :TEENSY)
      max_scale = MealPowers::TEENSY_SCALE_MAX[teensy[:level]]
      if max_scale && pkmn.scale > max_scale
        pkmn.scale = rand(0..max_scale)
        changed_by = teensy
      end
    end

    if MealPowers::DEBUG
      puts "========================================"
      puts "SIZE POWER DEBUG"
      puts "Pokémon: #{pkmn.name}"
      puts "Species: #{pkmn.species}"
      puts "Types: #{pkmn.species_data.types.inspect}"
      puts "Old Scale: #{old_scale}"
      puts "New Scale: #{pkmn.scale}"
      puts "Changed By: #{changed_by ? "#{changed_by[:id]} #{changed_by[:option]} Lv.#{changed_by[:level]}" : "None"}"
      puts "========================================"
    end
  }
)