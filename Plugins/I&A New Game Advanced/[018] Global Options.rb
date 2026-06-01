#===============================================================================
# Advanced New Game - Global Options
#===============================================================================

module AdvancedNewGame
  def self.global_options_path
    return sprintf("%s/GlobalOptions.rxdata", save_directory)
  end

  def self.save_global_options
    return if !$PokemonSystem

    File.open(global_options_path, "wb") do |f|
      Marshal.dump($PokemonSystem, f)
    end
  end

  def self.load_global_options
    if File.file?(global_options_path)
      $PokemonSystem = File.open(global_options_path, "rb") { |f| Marshal.load(f) }
    else
      $PokemonSystem = PokemonSystem.new if !$PokemonSystem
      save_global_options
    end
  rescue
    $PokemonSystem = PokemonSystem.new
    save_global_options
  end
end

# Load global options when reaching the title screen.
class PokemonLoadScreen
  alias advanced_new_game_global_options_initialize initialize

  def initialize(scene)
    AdvancedNewGame.load_global_options
    advanced_new_game_global_options_initialize(scene)
  end
end

# Save global options when leaving the Options screen.
class PokemonOptionScreen
  alias advanced_new_game_global_options_pbStartScreen pbStartScreen

  def pbStartScreen(*args)
    ret = advanced_new_game_global_options_pbStartScreen(*args)
    AdvancedNewGame.save_global_options
    return ret
  end
end