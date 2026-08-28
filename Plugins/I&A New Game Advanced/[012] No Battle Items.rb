class Battle
  alias advanced_new_game_pbRegisterItem pbRegisterItem

  def pbRegisterItem(idxBattler, item, idxTarget = nil, idxMove = nil)
    if pbOwnedByPlayer?(idxBattler) &&
       AdvancedNewGame.no_bag_items_battle? &&
       !GameData::Item.get(item).is_poke_ball?

      pbDisplay(_INTL("Items from the Bag cannot be used in this battle."))
      return false
    end

    return advanced_new_game_pbRegisterItem(idxBattler, item, idxTarget, idxMove)
  end
end