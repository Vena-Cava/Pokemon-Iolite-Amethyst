module AdvancedNewGame
  def self.pokecenter_limit_enabled?
    return false if !nuzlocke?
    return nuzlocke_pokecenter_limit != :infinite
  end

  def self.pokecenter_uses
    $PokemonGlobal.instance_variable_get(:@advanced_new_game_pokecenter_uses) || {}
  end

  def self.set_pokecenter_uses(value)
    $PokemonGlobal.instance_variable_set(:@advanced_new_game_pokecenter_uses, value)
  end

  def self.pokecenter_id(id = nil)
    return id if id
    return $game_map.map_id
  end

  def self.pokecenter_heals_used(id = nil)
    return pokecenter_uses[pokecenter_id(id)] || 0
  end

  def self.pokecenter_heals_remaining(id = nil)
    limit = nuzlocke_pokecenter_limit_value
    return -1 if limit < 0
    return [limit - pokecenter_heals_used(id), 0].max
  end

  def self.can_use_pokecenter?(id = nil)
    return true if !pokecenter_limit_enabled?
    return pokecenter_heals_remaining(id) > 0
  end

  def self.register_pokecenter_heal(id = nil)
    return if !pokecenter_limit_enabled?

    uses = pokecenter_uses
    key = pokecenter_id(id)
    uses[key] = 0 if !uses[key]
    uses[key] += 1
    set_pokecenter_uses(uses)
  end
end