SaveData.register(:advanced_new_game) do
  save_value { $advanced_new_game }

  load_value do |value|
    $advanced_new_game = value || AdvancedNewGame::DEFAULT_MODES.clone
  end

  new_game_value do
    $advanced_new_game_pending || AdvancedNewGame::DEFAULT_MODES.clone
  end
end