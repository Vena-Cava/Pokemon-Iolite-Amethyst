#===============================================================================
# Apply Advanced New Game settings after Game.start_new creates switches/variables
#===============================================================================

module Game
  class << self
    alias advanced_new_game_start_new start_new

    def start_new
      pending_settings = $advanced_new_game_pending

      advanced_new_game_start_new

      $advanced_new_game = pending_settings || AdvancedNewGame::DEFAULT_MODES.clone
      $advanced_new_game_pending = nil

      AdvancedNewGame.apply_game_settings

      if $PokemonGlobal
        $PokemonGlobal.instance_variable_set(
          :@advanced_new_game_settings,
          Marshal.load(Marshal.dump($advanced_new_game))
        )
      end
    end
  end
end