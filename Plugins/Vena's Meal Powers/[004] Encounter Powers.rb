#===============================================================================
# Meal Powers - Encounter / Repel Powers
# Type-based version with full repel blocking.
#===============================================================================

module MealPowers
  ENCOUNTER_POWER_CHANCE = {
    1 => 50,
    2 => 75,
    3 => 100
  }

  def self.type_power_chance(level)
    return ENCOUNTER_POWER_CHANCE[level] || 0
  end

  def self.species_has_type?(species, type)
    return true if type == :ALL
    return false if !species || !type
    data = GameData::Species.get(species)
    return data.types.include?(type)
  end

  def self.active_type_repel_powers
    return active.select { |p| p[:id] == :REPEL && p[:option] != :ALL }
  end

  def self.active_type_encounter_powers
    return active.select { |p| p[:id] == :ENCOUNTER && p[:option] != :ALL }
  end
  
  def self.fishing_encounter_type(rodType)
    return :OldRod   if rodType == 1
    return :GoodRod  if rodType == 2
    return :SuperRod if rodType == 3
    return nil
  end

  def self.encounter_table_fully_repelled?(enc_type)
    return false if !$PokemonEncounters
    tables = $PokemonEncounters.instance_variable_get(:@encounter_tables)
    return false if !tables || !tables[enc_type]

    repel_powers = active_type_repel_powers
    return false if repel_powers.empty?

    tables[enc_type].each do |enc|
      species = enc[1]

      blocked = repel_powers.any? do |p|
        p[:level] >= 3 && species_has_type?(species, p[:option])
      end

      return false if !blocked
    end

    return true
  end
end

module MealPowers_EncounterPowers
  def self.apply(encounter_obj, original, enc_type, chance_rolls)
    return nil if !original

    species = original[0]
    level   = original[1]

    repel_powers     = MealPowers.active_type_repel_powers
    encounter_powers = MealPowers.active_type_encounter_powers

    #---------------------------------------------------------------------------
    # Repel Power - Type
    #---------------------------------------------------------------------------
    repel_powers.each do |repel_power|
      repel_type  = repel_power[:option]
      repel_level = repel_power[:level]
      chance      = MealPowers.type_power_chance(repel_level)

      next if !MealPowers.species_has_type?(species, repel_type)

      roll = rand(100)

      if roll < chance
        replacement = choose_allowed_replacement(
          encounter_obj,
          enc_type,
          chance_rolls,
          repel_powers
        )

        if MealPowers::DEBUG
          puts "========================================"
          puts "MEAL REPEL POWER DEBUG"
          puts "Repel Type: #{repel_type}"
          puts "Repel Lv: #{repel_level}"
          puts "Activation Chance: #{chance}%"
          puts "Roll: #{roll}"
          puts "Original: #{species} Lv.#{level}"
          puts "Replacement: #{replacement ? "#{replacement[0]} Lv.#{replacement[1]}" : "None"}"
          puts "Blocked Entire Encounter?: #{replacement.nil?}"
          puts "========================================"
        end

        # No valid replacement means the encounter is fully repelled.
        return nil if !replacement

        return replacement
      end
    end

    #---------------------------------------------------------------------------
    # Encounter Power - Type
    #---------------------------------------------------------------------------
    encounter_powers.each do |encounter_power|
      force_type  = encounter_power[:option]
      force_level = encounter_power[:level]
      chance      = MealPowers.type_power_chance(force_level)

      next if MealPowers.species_has_type?(species, force_type)

      roll = rand(100)

      if roll < chance
        replacement = choose_forced_type_replacement(
          encounter_obj,
          enc_type,
          chance_rolls,
          force_type,
          repel_powers
        )

        if MealPowers::DEBUG
          puts "========================================"
          puts "MEAL ENCOUNTER POWER DEBUG"
          puts "Forced Type: #{force_type}"
          puts "Encounter Lv: #{force_level}"
          puts "Activation Chance: #{chance}%"
          puts "Roll: #{roll}"
          puts "Original: #{species} Lv.#{level}"
          puts "Replacement: #{replacement ? "#{replacement[0]} Lv.#{replacement[1]}" : "None"}"
          puts "========================================"
        end

        return replacement if replacement
      end
    end

    return original
  end

  def self.repel_power_blocks_species?(species, repel_powers)
    repel_powers.each do |p|
      next if !MealPowers.species_has_type?(species, p[:option])
      return true if p[:level] >= 3
    end
    return false
  end

  def self.choose_allowed_replacement(encounter_obj, enc_type, chance_rolls, repel_powers)
    tables = encounter_obj.instance_variable_get(:@encounter_tables)
    return nil if !tables

    enc_list = tables[enc_type]
    return nil if !enc_list || enc_list.empty?

    filtered = enc_list.select do |enc|
      species = enc[1]
      !repel_power_blocks_species?(species, repel_powers)
    end

    return nil if filtered.empty?
    return weighted_choice(filtered, chance_rolls)
  end

  def self.choose_forced_type_replacement(encounter_obj, enc_type, chance_rolls, force_type, repel_powers)
    tables = encounter_obj.instance_variable_get(:@encounter_tables)
    return nil if !tables

    enc_list = tables[enc_type]
    return nil if !enc_list || enc_list.empty?

    filtered = enc_list.select do |enc|
      species = enc[1]
      MealPowers.species_has_type?(species, force_type) &&
        !repel_power_blocks_species?(species, repel_powers)
    end

    return nil if filtered.empty?
    return weighted_choice(filtered, chance_rolls)
  end

  def self.weighted_choice(enc_list, chance_rolls)
    total = enc_list.sum { |enc| enc[0] }
    return nil if total <= 0

    rnd = 0
    chance_rolls.times do
      r = rand(total)
      rnd = r if r > rnd
    end

    enc_list.each do |enc|
      rnd -= enc[0]
      next if rnd >= 0
      return [enc[1], rand(enc[2]..enc[3])]
    end

    return nil
  end
end

class PokemonEncounters
  alias mealpowers_choose_wild_pokemon choose_wild_pokemon unless method_defined?(:mealpowers_choose_wild_pokemon)

  def choose_wild_pokemon(enc_type, chance_rolls = 1)
    original = mealpowers_choose_wild_pokemon(enc_type, chance_rolls)

    if MealPowers::DEBUG
      puts "========================================"
      puts "MEAL POWER ENCOUNTER HOOK REACHED"
      puts "Encounter Type: #{enc_type}"
      puts "Chance Rolls: #{chance_rolls}"
      puts "Original Encounter: #{original.inspect}"
      puts "Active Meal Powers: #{MealPowers.active.inspect}"
      puts "========================================"
    end

    return MealPowers_EncounterPowers.apply(self, original, enc_type, chance_rolls)
  end
end