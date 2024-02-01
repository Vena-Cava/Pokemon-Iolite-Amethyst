#===============================================================================
# Pokemon Summary handlers.
#===============================================================================
UIHandlers.add(:summary, :page_iv, { 
  "name"      => "IV",
  "suffix"    => "iv",
  "order"     => 31,
  "options"   => [:item, :nickname, :pokedex, :mark, "Reset EV's"],
  "layout"    => proc { |pkmn, scene| scene.drawPageIV }
})

UIHandlers.add(:summary, :page_ev, { 
  "name"      => "EV",
  "suffix"    => "ev",
  "order"     => 32,
  "options"   => [:item, :nickname, :pokedex, :mark, "Reset EV's"],
  "layout"    => proc { |pkmn, scene| scene.drawPageEV }
})

UIHandlers.add(:summary, :page_ivev, { 
  "name"      => "IV/EV",
  "suffix"    => "ivev",
  "order"     => 33,
  "options"   => [:item, :nickname, :pokedex, :mark, "Reset EV's"],
  "layout"    => proc { |pkmn, scene| scene.drawPageIVEV }
})

UIHandlers.add(:summary, :page_baseivev, { 
  "name"      => "Hidden Stats",
  "suffix"    => "baseivev",
  "order"     => 34,
  "options"   => [:item, :nickname, :pokedex, :mark],
  "layout"    => proc { |pkmn, scene| scene.drawPageBaseIVEV }
})

UIHandlers.add(:summary, :page_allstats, { 
  "name"      => "Stats",
  "suffix"    => "allstats",
  "order"     => 35,
  "options"   => [:item, :nickname, :pokedex, :mark],
  "layout"    => proc { |pkmn, scene| scene.drawPageAllStats }
})