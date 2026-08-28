#===============================================================================
# Cuttable Tall Grass: Field Move Edits
#===============================================================================

def pbTerrainCanCut?(x, y)
  return false if x < 0 || y < 0 || x >= $game_map.width || y >= $game_map.height
  terrain = $map_factory.getTerrainTag($game_map.map_id, x, y)
  return terrain.respond_to?(:can_cut) && terrain.can_cut
end

def pbCuttableGrassNearby?(range = 1)
  px = $game_player.x
  py = $game_player.y
  (-range..range).each do |dx|
    (-range..range).each do |dy|
      return true if pbTerrainCanCut?(px + dx, py + dy)
    end
  end
  return false
end

def pbCutGrassTile(x, y)
  return [] if !pbTerrainCanCut?(x, y)

  cut_layers = []

  if $scene.is_a?(Scene_Map)
    spriteset = $scene.spriteset($game_map.map_id)
    spriteset&.addUserAnimation(Settings::GRASS_ANIMATION_ID, x, y, true, 1)
  end

  2.downto(0) do |layer|
    tile_id = $game_map.data[x, y, layer]
    next if !tile_id || tile_id == 0

    old_tile = tile_id
    key = CuttableTallGrass.autotile_key(tile_id)

    # Test-remove this layer.
    $game_map.data[x, y, layer] = 0

    # If the terrain changed, this layer was part of the cuttable grass.
    if !pbTerrainCanCut?(x, y)
      cut_layers << [x, y, layer, key, old_tile]
      break
    else
      # Keep it removed only if there is still another cuttable grass layer below.
      cut_layers << [x, y, layer, key, old_tile]
      next
    end
  end

  return cut_layers
end

def pbRefreshBushDepthForEvent(event)
  return if !event
  in_deep_bush = false
  event.each_occupied_tile do |x, y|
    terrain = $map_factory.getTerrainTagFromCoords(event.map.map_id, x, y, true)
    if terrain.deep_bush
      in_deep_bush = true
      break
    end
  end
  event.instance_variable_set(:@bush_depth, in_deep_bush ? 12 : 0)
end

def pbRefreshAllBushDepths
  pbRefreshBushDepthForEvent($game_player)
  $game_map.events.each_value do |event|
    pbRefreshBushDepthForEvent(event)
  end
end

def pbCutBoostAbility?(pokemon)
  return false if !pokemon
  return false if AdvancedNewGame.retired?(pokemon)

  CuttableTallGrass::CUTBOOSTABILITIES.each do |ability|
    return true if pokemon.hasAbility?(ability)
  end

  return false
end

def pbCutGrassAroundPlayer(pokemon)
  range = (pbCutBoostAbility?(pokemon)) ? 2 : 1
  cut_any = false
  px = $game_player.x
  py = $game_player.y
  cut_tiles = []

  (-range..range).each do |dx|
    (-range..range).each do |dy|
      results = pbCutGrassTile(px + dx, py + dy)
      next if !results || results.empty?
      cut_any = true
      cut_tiles.concat(results)
    end
  end

  cut_tiles.each do |data|
    x, y, layer, key, old_tile = data

  CuttableTallGrass.refresh_cut_autotiles(x, y, layer, key, 1)
  end

  if cut_any
    pbSEPlay("Cut")
    $game_map.need_refresh = true
    pbRefreshAllBushDepths
  end

  return cut_any
end

HiddenMoveHandlers::CanUseMove.add(:CUT, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_CUT, showmsg)
  facingEvent = $game_player.pbFacingEvent
  can_cut_tree = facingEvent && facingEvent.name[/cuttree/i]
  range = (pbCutBoostAbility?(pkmn)) ? 2 : 1
  can_cut_grass = pbCuttableGrassNearby?(range)
  if !can_cut_tree && !can_cut_grass
    pbMessage(_INTL("You can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:CUT, proc { |move, pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  $stats.cut_count += 1
  facingEvent = $game_player.pbFacingEvent
  pbSmashEvent(facingEvent) if facingEvent && facingEvent.name[/cuttree/i]
  pbCutGrassAroundPlayer(pokemon)
  next true
})