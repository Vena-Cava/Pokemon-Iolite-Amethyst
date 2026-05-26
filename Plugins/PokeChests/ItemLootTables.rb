#===============================================================================
# Loot Tables
#===============================================================================

module LootTables
  BOOST_ABILITIES = [:SUPERLUCK	]

  RARITY_ORDER = [:common, :uncommon, :rare, :very_rare]

  SandCastleTable = {
    :common    => [[:SOFTSAND, 1],[:SHOALSHELL, 1],[:GIMMIGHOULCOIN, 1, 5]],
    :uncommon  => [[:PEARL, 1],[:HEARTSCALE, 1]],
    :rare      => [[:BIGPEARL, 1]],
    :very_rare => [[:PEARLSTRING, 1]]
  }

  RockSmashTable = {
    :common    => [[:HARDSTONE, 1],[:EVERSTONE, 1],[:GIMMIGHOULCOIN, 1, 5]],
    :uncommon  => [[:STARDUST, 1],[:RAREBONE, 1]],
    :rare      => [[:STARPIECE, 1]],
    :very_rare => [[:COMETSHARD, 1]]
  }

  GimmifoolTable = {
    :common    => [[:GIMMIFOOLCOIN, 5, 15]],
    :uncommon  => [[:GIMMIFOOLCOIN, 16, 30]],
    :rare      => [[:GIMMIFOOLCOIN, 31, 60]],
    :very_rare => [[:GIMMIFOOLCOIN, 61, 100]]
  }

  GimmighoulTable = {
    :common    => [[:GIMMIGHOULCOIN, 5, 15]],
    :uncommon  => [[:GIMMIGHOULCOIN, 16, 30]],
    :rare      => [[:GIMMIGHOULCOIN, 31, 60]],
    :very_rare => [[:GIMMIGHOULCOIN, 61, 100]]
  }

  PokeChestCommonTable = {
    :common    => [[:POKEBALL, 2, 5],[:POTION, 1, 3],[:ANTIDOTE, 1, 2],[:PARALYZEHEAL, 1, 2]],
    :uncommon  => [[:GREATBALL, 2, 5],[:SUPERPOTION, 1, 2],[:REPEL, 1, 2],[:ESCAPEROPE, 1]],
    :rare      => [[:REVIVE, 1],[:FULLHEAL, 1, 2],[:ETHER, 1],[:PEARL, 1]],
    :very_rare => [[:ULTRABALL, 2, 5],[:MAXREVIVE, 1],[:BIGPEARL, 1]]
  }
  
  PokeChestGreatTable = {
    :common    => [[:GREATBALL, 2, 5],[:SUPERPOTION, 2, 4],[:REPEL, 1, 3],[:FULLHEAL, 1, 2]],
    :uncommon  => [[:ULTRABALL, 2, 5],[:HYPERPOTION, 1, 3],[:REVIVE, 1, 2],[:ETHER, 1]],
    :rare      => [[:MAXREPEL, 1, 2],[:MAXREVIVE, 1],[:ELIXIR, 1],[:NUGGET, 1, 2]],
    :very_rare => [[:DUSKBALL, 2, 4],[:QUICKBALL, 2, 4],[:BIGNUGGET, 1],[:ABILITYCAPSULE, 1]]
  }

  PokeChestUltraTable = {
    :common    => [[:ULTRABALL, 3, 6],[:HYPERPOTION, 2, 5],[:MAXREPEL, 1, 3],[:REVIVE, 2, 4]],
    :uncommon  => [[:DUSKBALL, 2, 5],[:QUICKBALL, 2, 5],[:TIMERBALL, 2, 5],[:MAXPOTION, 1, 3]],
    :rare      => [[:MAXREVIVE, 1, 2],[:ABILITYCAPSULE, 1],[:COMETSHARD, 1],[:BOTTLECAP, 1]],
    :very_rare => [
	[:BEASTBALL, 1],
	[:DREAMBALL, 1],
	[:FASTBALL, 1],
	[:FRIENDBALL, 1],
	[:HEAVYBALL, 1],
	[:LEVELBALL, 1],
	[:LOVEBALL, 1],
	[:LUREBALL, 1],
	[:MOONBALL, 1],
	[:SAFARIBALL, 1],
	[:SPORTBALL, 1],
	[:ABILITYPATCH, 1],
	[:BIGNUGGET, 1, 2],
	[:GOLDBOTTLECAP, 1]
	]
  }
  
PokeChestTMTable = {
  :common => [
    [:TM001,1,2],[:TM002,1,2],[:TM003,1,2],[:TM005,1,2],[:TM006,1,2],
    [:TM007,1,2],[:TM011,1,2],[:TM015,1,2],[:TM016,1,2],[:TM017,1,2],
    [:TM019,1,2],[:TM022,1,2],[:TM023,1,2],[:TM025,1,2],[:TM026,1,2],
    [:TM027,1,2],[:TM028,1,2],[:TM030,1,2],[:TM031,1,2],[:TM032,1,2],
    [:TM033,1,2],[:TM034,1,2],[:TM035,1,2],[:TM036,1,2],[:TM037,1,2],
    [:TM038,1,2],[:TM040,1,2],[:TM042,1,2],[:TM046,1,2],[:TM047,1,2],
    [:TM057,1,2],[:TM070,1,2],[:TM072,1,2],[:TM074,1,2],[:TM075,1,2],
    [:TM080,1,2],[:TM081,1,2],[:TM082,1,2],[:TM085,1,2],[:TM092,1,2],
    [:TM096,1,2],[:TM104,1,2],[:TM122,1,2],[:TM123,1,2],[:TM128,1,2],
    [:TM130,1,2],[:TM134,1,2],[:TM171,1,2],[:TM172,1,2],[:TM173,1,2],
    [:TM174,1,2],[:TM176,1,2],[:TM177,1,2],[:TM178,1,2],[:TM179,1,2],
    [:TM182,1,2],[:TM184,1,2],[:TM193,1,2],[:TM202,1,2],[:TM203,1,2],
    [:TM208,1,2],[:TM211,1,2],[:TM213,1,2],[:TM216,1,2],[:TM223,1,2],
    [:TM224,1,2],[:TM226,1,2],[:TM229,1,2],[:TM231,1,2],[:TM233,1,2],
    [:TM245,1,2],[:TM246,1,2],[:TM252,1,2],[:TM253,1,2],[:TM254,1,2],
    [:TM255,1,2],[:TM256,1,2],[:TM257,1,2],[:TM258,1,2],[:TM260,1,2],
    [:TM262,1,2],[:TM271,1,2]
  ],

  :uncommon => [
    [:TM004,1,2],[:TM008,1,2],[:TM009,1,2],[:TM010,1,2],[:TM012,1,2],
    [:TM013,1,2],[:TM014,1,2],[:TM018,1,2],[:TM020,1,2],[:TM021,1,2],
    [:TM024,1,2],[:TM029,1,2],[:TM039,1,2],[:TM041,1,2],[:TM043,1,2],
    [:TM044,1,2],[:TM045,1,2],[:TM048,1,2],[:TM049,1,2],[:TM050,1,2],
    [:TM051,1,2],[:TM052,1,2],[:TM053,1,2],[:TM054,1,2],[:TM055,1,2],
    [:TM056,1,2],[:TM058,1,2],[:TM059,1,2],[:TM060,1,2],[:TM061,1,2],
    [:TM062,1,2],[:TM064,1,2],[:TM065,1,2],[:TM066,1,2],[:TM067,1,2],
    [:TM068,1,2],[:TM069,1,2],[:TM071,1,2],[:TM073,1,2],[:TM076,1,2],
    [:TM078,1,2],[:TM079,1,2],[:TM083,1,2],[:TM084,1,2],[:TM086,1,2],
    [:TM087,1,2],[:TM097,1,2],[:TM098,1,2],[:TM101,1,2],[:TM105,1,2],
    [:TM106,1,2],[:TM107,1,2],[:TM108,1,2],[:TM109,1,2],[:TM110,1,2],
    [:TM114,1,2],[:TM115,1,2],[:TM117,1,2],[:TM121,1,2],[:TM124,1,2],
    [:TM131,1,2],[:TM133,1,2],[:TM136,1,2],[:TM137,1,2],[:TM138,1,2],
    [:TM139,1,2],[:TM144,1,2],[:TM145,1,2],[:TM146,1,2],[:TM147,1,2],
    [:TM148,1,2],[:TM151,1,2],[:TM161,1,2],[:TM162,1,2],[:TM175,1,2],
    [:TM183,1,2],[:TM185,1,2],[:TM186,1,2],[:TM188,1,2],[:TM189,1,2],
    [:TM191,1,2],[:TM195,1,2],[:TM196,1,2],[:TM197,1,2],[:TM199,1,2],
    [:TM204,1,2],[:TM205,1,2],[:TM206,1,2],[:TM207,1,2],[:TM209,1,2],
    [:TM210,1,2],[:TM214,1,2],[:TM215,1,2],[:TM217,1,2],[:TM219,1,2],
    [:TM221,1,2],[:TM222,1,2],[:TM225,1,2],[:TM227,1,2],[:TM228,1,2],
    [:TM230,1,2],[:TM234,1,2],[:TM235,1,2],[:TM236,1,2],[:TM237,1,2],
    [:TM242,1,2],[:TM243,1,2],[:TM247,1,2],[:TM248,1,2],[:TM249,1,2],
    [:TM251,1,2],[:TM259,1,2],[:TM261,1,2],[:TM263,1,2],[:TM264,1,2],
    [:TM265,1,2],[:TM266,1,2],[:TM269,1,2],[:TM270,1,2]
  ],

  :rare => [
    [:TM063,1,2],[:TM077,1,2],[:TM088,1,2],[:TM089,1,2],[:TM090,1,2],
    [:TM091,1,2],[:TM093,1,2],[:TM094,1,2],[:TM095,1,2],[:TM099,1,2],
    [:TM100,1,2],[:TM103,1,2],[:TM111,1,2],[:TM112,1,2],[:TM113,1,2],
    [:TM116,1,2],[:TM118,1,2],[:TM119,1,2],[:TM120,1,2],[:TM125,1,2],
    [:TM126,1,2],[:TM127,1,2],[:TM129,1,2],[:TM132,1,2],[:TM135,1,2],
    [:TM140,1,2],[:TM181,1,2],[:TM187,1,2],[:TM192,1,2],[:TM194,1,2],
    [:TM200,1,2],[:TM201,1,2],[:TM232,1,2],[:TM238,1,2],[:TM239,1,2],
    [:TM240,1,2],[:TM241,1,2],[:TM244,1,2],[:TM267,1,2],[:TM268,1,2],
    [:TM276,1,2],[:TM277,1,2],[:TM278,1,2],[:TM279,1,2]
  ],

  :very_rare => [
    [:TM102,1,2],[:TM141,1,2],[:TM142,1,2],[:TM143,1,2],[:TM149,1,2],
    [:TM150,1,2],[:TM152,1,2],[:TM153,1,2],[:TM154,1,2],[:TM155,1,2],
    [:TM156,1,2],[:TM157,1,2],[:TM158,1,2],[:TM159,1,2],[:TM160,1,2],
    [:TM163,1,2],[:TM164,1,2],[:TM165,1,2],[:TM166,1,2],[:TM167,1,2],
    [:TM168,1,2],[:TM169,1,2],[:TM170,1,2],[:TM180,1,2],[:TM190,1,2],
    [:TM198,1,2],[:TM212,1,2],[:TM218,1,2],[:TM220,1,2],[:TM250,1,2],
    [:TM272,1,2],[:TM273,1,2],[:TM274,1,2],[:TM275,1,2]
  ]
}

  def self.has_boost_ability?(pokemon)
    return false if !pokemon || pokemon.egg?
    return false if AdvancedNewGame.retired?(pokemon)
    BOOST_ABILITIES.any? { |ability| pokemon.hasAbility?(ability) }
  end

  def self.boosted_by?(mode, pokemon = nil)
    case mode
    when :user
      return has_boost_ability?(pokemon)
    when :lead
      return has_boost_ability?($player.party[0])
    when :party
      return $player.party.any? { |pkmn| has_boost_ability?(pkmn) }
    end
    return false
  end

  def self.boost_rarity(rarity)
    index = RARITY_ORDER.index(rarity)
    return rarity if !index || index >= RARITY_ORDER.length - 1
    return RARITY_ORDER[index + 1]
  end
end

def pbLootTable(table, chance = 100, boost_mode = nil, pokemon = nil)
  return false if !table
  return false if rand(100) >= chance

  rarity_roll = rand(100)
  rarity = if rarity_roll < 60
             :common
           elsif rarity_roll < 85
             :uncommon
           elsif rarity_roll < 97
             :rare
           else
             :very_rare
           end

  rarity = LootTables.boost_rarity(rarity) if LootTables.boosted_by?(boost_mode, pokemon)

  items = table[rarity]
  return false if !items || items.empty?

  item_data = items.sample
  item = item_data[0]
  min_qty = item_data[1] || 1
  max_qty = item_data[2] || min_qty
  quantity = rand(min_qty..max_qty)

  return pbItemBall(item, quantity)
end	