#===============================================================================
# Meal Powers - Base Point Power
# Adds bonus EVs after normal EV gain.
#===============================================================================

module MealPowers
  EV_STATS = [
    :HP,
    :ATTACK,
    :DEFENSE,
    :SPECIAL_ATTACK,
    :SPECIAL_DEFENSE,
    :SPEED
  ]

  def self.base_point_bonus_for(stat)
    all_level  = level(:BASEPOINT, :ALL)
    stat_level = level(:BASEPOINT, stat)
    return [all_level, stat_level].max
  end

  def self.active_base_point_power?
    EV_STATS.any? { |stat| base_point_bonus_for(stat) > 0 }
  end
end

class Battle
  alias mealpowers_pbGainEVsOne pbGainEVsOne unless method_defined?(:mealpowers_pbGainEVsOne)

  def pbGainEVsOne(idxParty, defeatedBattler)
    pkmn = pbParty(0)[idxParty]

    old_evs = {}
    MealPowers::EV_STATS.each { |stat| old_evs[stat] = pkmn.ev[stat] }

    ret = mealpowers_pbGainEVsOne(idxParty, defeatedBattler)

    return ret if !MealPowers.active_base_point_power?
    return ret if !pkmn || pkmn.egg?

    total_ev_limit = Pokemon::EV_LIMIT
    stat_ev_limit  = Pokemon::EV_STAT_LIMIT

    bonuses_added = {}

    MealPowers::EV_STATS.each do |stat|
      bonus = MealPowers.base_point_bonus_for(stat)
      next if bonus <= 0

      current_total = 0
      MealPowers::EV_STATS.each { |s| current_total += pkmn.ev[s] }

      break if current_total >= total_ev_limit
      next if pkmn.ev[stat] >= stat_ev_limit

      can_add_total = total_ev_limit - current_total
      can_add_stat  = stat_ev_limit - pkmn.ev[stat]
      amount = [bonus, can_add_total, can_add_stat].min

      next if amount <= 0

      pkmn.ev[stat] += amount
      bonuses_added[stat] = amount
    end

    if MealPowers::DEBUG && !bonuses_added.empty?
      puts "========================================"
      puts "BASE POINT POWER DEBUG"
      puts "Pokémon gaining EVs: #{pkmn.name}"
      puts "Defeated Pokémon: #{defeatedBattler.pokemon.name}"
      puts "Defeated EV Yield: #{defeatedBattler.pokemon.evYield.inspect rescue 'Unknown'}"
      puts "Bonuses Added: #{bonuses_added.inspect}"
      puts "Old EVs: #{old_evs.inspect}"
      new_evs = {}
      MealPowers::EV_STATS.each { |stat| new_evs[stat] = pkmn.ev[stat] }
      puts "New EVs: #{new_evs.inspect}"
      puts "========================================"
    end

    return ret
  end
end