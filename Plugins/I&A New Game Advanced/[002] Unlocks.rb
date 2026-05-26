module AdvancedNewGame
  def self.cleared_difficulties
    $PokemonGlobal.instance_variable_get(:@advanced_new_game_cleared) || []
  end

  def self.set_cleared_difficulties(value)
    $PokemonGlobal.instance_variable_set(:@advanced_new_game_cleared, value)
  end

  def self.unlocked_difficulties
    return DIFFICULTIES.keys if $DEBUG

    ret = [:easy, :normal]

    cleared = cleared_difficulties

    ret.push(:hard) if cleared.include?(:normal)
    ret.push(:ultra_hard) if cleared.include?(:hard)

    return ret
  end

  def self.locked_difficulties
    return [] if $DEBUG
    return DIFFICULTIES.keys - unlocked_difficulties
  end

  def self.difficulty_unlocked?(difficulty)
    return unlocked_difficulties.include?(difficulty)
  end

  def self.mark_game_cleared
    cleared = cleared_difficulties
    cleared.push(difficulty)
    cleared.uniq!
    set_cleared_difficulties(cleared)
  end
end