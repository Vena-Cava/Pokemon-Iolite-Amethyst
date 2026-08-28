#===============================================================================
# * Iolite & Amethyst - Terrain Tags
#===============================================================================

GameData::TerrainTag.register({
  :id                     => :DarkGrass,
  :id_number              => 30,
  :shows_grass_rustle     => true,
  :land_wild_encounters   => true,
  :double_wild_encounters => true,
  :battle_environment     => :DarkGrass,
  :can_cut                => true
})

#===============================================================================
# TransBridge Terrain Tag
# Terrain Tag 31
#===============================================================================

module GameData
  class TerrainTag
    attr_reader :trans_bridge

    alias ia_transbridge_initialize initialize
    def initialize(hash)
      ia_transbridge_initialize(hash)
      @trans_bridge = hash[:trans_bridge] || false
      @bridge = true if @trans_bridge
    end
  end
end

GameData::TerrainTag.register({
  :id           => :TransBridge,
  :id_number    => 31,
  :bridge       => true,
  :trans_bridge => true
})

class PokemonGlobalMetadata
  attr_accessor :trans_bridge_under
end

def pbTransBridgeOn
  return if $PokemonGlobal.trans_bridge_under == true
  $PokemonGlobal.trans_bridge_under = true
  pbBridgeOff   # UNDER bridge; lets water underneath count for Surf
end

def pbTransBridgeOff
  return if $PokemonGlobal.trans_bridge_under == false
  $PokemonGlobal.trans_bridge_under = false
  pbBridgeOn    # ON TOP of bridge
end

def pbTransBridgeClear
  $PokemonGlobal.trans_bridge_under = false
  pbBridgeOff
end

#===============================================================================
# Tile opacity
#===============================================================================

class TilemapRenderer::TileSprite
  attr_accessor :trans_bridge

  alias ia_transbridge_set_bitmap set_bitmap
  def set_bitmap(filename, tile_id, autotile, animated, priority, bitmap)
    ia_transbridge_set_bitmap(filename, tile_id, autotile, animated, priority, bitmap)
    @trans_bridge = false
    self.opacity = 255
  end
end

class TilemapRenderer
  alias ia_transbridge_refresh_tile_bitmap refresh_tile_bitmap
  def refresh_tile_bitmap(tile, map, tile_id)
    ia_transbridge_refresh_tile_bitmap(tile, map, tile_id)

    terrain_tag = map.terrain_tags[tile_id] || 0
    terrain = GameData::TerrainTag.try_get(terrain_tag)
    tile.trans_bridge = terrain&.trans_bridge || false
  end

  alias ia_transbridge_update update
  def update
    ia_transbridge_update
    update_transbridge_opacity
  end

  def update_transbridge_opacity
    return if !@tiles

    target_opacity = $PokemonGlobal.trans_bridge_under ? 96 : 255

    @tiles.each do |col|
      col.each do |coord|
        coord.each do |tile|
          next if !tile || !tile.trans_bridge
          tile.opacity += (target_opacity - tile.opacity) / 4
        end
      end
    end
  end
end

#===============================================================================
# Reflection fix while walking on top
#===============================================================================

class Sprite_Reflection
  alias ia_transbridge_reflection_update update
  def update
    if !$PokemonGlobal.trans_bridge_under && $PokemonGlobal.bridge > 0
      old_bridge = $PokemonGlobal.bridge
      $PokemonGlobal.bridge = 0
      ia_transbridge_reflection_update
      $PokemonGlobal.bridge = old_bridge
    else
      ia_transbridge_reflection_update
    end
  end
end