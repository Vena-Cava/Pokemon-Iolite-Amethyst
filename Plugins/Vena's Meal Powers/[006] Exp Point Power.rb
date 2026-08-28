#===============================================================================
# Meal Powers - Exp. Point Power
# Boosts Exp based on the defeated Pokémon's type.
#===============================================================================

module MealPowers
  EXP_POWER_MULT = {
    0 => 1.0,
    1 => 1.1,
    2 => 1.3,
    3 => 1.5
  }

  def self.exp_power_multiplier_for(defeated_pokemon)
    return 1.0 if !defeated_pokemon

    species_data = defeated_pokemon.species_data
    types = species_data.types
    best_level = level(:EXP, :ALL)

    types.each do |type|
      best_level = [best_level, level(:EXP, type)].max
    end

    return EXP_POWER_MULT[best_level] || 1.0
  end

  def self.exp_power_level_for(defeated_pokemon)
    return 0 if !defeated_pokemon

    species_data = defeated_pokemon.species_data
    types = species_data.types
    best_level = level(:EXP, :ALL)

    types.each do |type|
      best_level = [best_level, level(:EXP, type)].max
    end

    return best_level
  end
end

module MealPowers_ExpPointPower
  def pbGainExpOne(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages = true)
    defeated_pokemon = defeatedBattler&.pokemon
    level = MealPowers.exp_power_level_for(defeated_pokemon)
    mult  = MealPowers.exp_power_multiplier_for(defeated_pokemon)

    return super(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages) if level <= 0 || mult == 1.0

    old_base_exp = defeated_pokemon.base_exp
    new_base_exp = (old_base_exp * mult).floor
    new_base_exp = 1 if old_base_exp > 0 && new_base_exp < 1

    if MealPowers::DEBUG
      puts "========================================"
      puts "EXP POINT POWER DEBUG"
      puts "Gainer: #{pbParty(0)[idxParty].name rescue "Unknown"}"
      puts "Defeated Pokémon: #{defeated_pokemon.name}"
      puts "Defeated Types: #{defeated_pokemon.species_data.types.inspect}"
      puts "Exp Power Lv: #{level}"
      puts "Multiplier: x#{mult}"
      puts "Base Exp: #{old_base_exp}"
      puts "Modified Base Exp: #{new_base_exp}"
      puts "========================================"
    end

    defeated_pokemon.define_singleton_method(:base_exp) { new_base_exp }

    begin
      return super(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages)
    ensure
      defeated_pokemon.singleton_class.remove_method(:base_exp) rescue nil
    end
  end
end

class Battle
  prepend MealPowers_ExpPointPower
end