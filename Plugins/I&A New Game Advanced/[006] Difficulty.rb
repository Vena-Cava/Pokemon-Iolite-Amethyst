module AdvancedNewGame
  def self.hard?
    [:hard, :ultra_hard].include?(difficulty)
  end

  def self.ultra_hard?
    difficulty == :ultra_hard
  end
end