#===============================================================================
# Cuttable Tall Grass: Autotile Refresh
#===============================================================================

module CuttableTallGrass
  BITMASK_TO_AUTOTILE_INDEX = {
	# Isolated ==================================
	0=>46,
	# XXX
	# XCX
	# XXXisolated
	# +

	# One Connection ==================================

	2=>44,
	# XOX
	# XCX
	# XXXup only
	# +
	
	8=>45,
	# XXX
	# OCX
	# XXXleft only
	# +

	16=>43,
	# XXX
	# XCO
	# XXXright only
	# +

	64=>42, 
	# XXX
	# XCX
	# XOXdown only
	# +
	
	# Two Connections ==================================
	
	10=>39,
	# XOX
	# OCX
	# XXXup + left
	# +
	
	18=>41, 
	# XOX
	# XCO
	# XXXup + right
	# +

	24=>33,
	# XXX
	# OCO
	# XXXleft + right only
	# +
	
	66=>32,
	# XOX
	# XCX
	# XOX up + down
	# +
	
	72=>37, 
	# XXX
	# OCX
	# XOXleft + down
	# +

	80=>35, 
	# XXX
	# XCO
	# XOXright + down
	# +
	
	# Full Corners ==================================
	
	11=>38,
	# OOX
	# OCX
	# XXXup + left + upper-left
	# +
	
	22=>40,
	# XOO
	# XCO
	# XXXup + right + upper-right
	# +

	104=>36,
	# XXX
	# OCX
	# OOXleft + down + lower-left
	# +

	208=>34,
	# XXX
	# XCO
	# XOOright + down + lower-right
	# +
	
	# Three Connections ==================================
	
	26=>31,
	# XOX
	# OCO
	# XXXup + left + right
	# +
	
	74=>27, 
	# XOX
	# OCX
	# XOXup + left + down
	# +
	
	82=>19,
	# XOX
	# XCO
	# XOXup + right + down
	# +
	
	88=>23,
	# XXX
	# OCO
	# XOXleft + right + down
	# +
	
	# Full Corners and One Connection ==================================
	
	27=>30,
	# OOX
	# OCO
	# XXXup + left + right + upper-left
	# +
	
	30=>29, 
	# XOO
	# OCO
	# XXXup + left + right + upper-right
	# +
	
	75=>25,
	# OOX
	# OCX
	# XOXup + left + down + upper-left
	# +
	
	86=>18, 
	# XOO
	# XCO
	# XOXup + right + down + upper-right
	# +
	
	106=>26,
	# XOX
	# OCX
	# OOXup + left + down + lower-left
	# +

	120=>21,
	# XXX
	# OCO
	# OOXleft + right + down + lower-left
	# +
	
	210=>17,
	# XOX
	# XCO
	# XOOup + right + down + lower-right
	# +

	216=>22,
	# XXX
	# OCO
	# XOOleft + right + down + lower-right
	# +
	
	# Full Corners and Two Connections ==================================
	
	91=>14, 
	# OOX
	# OCO
	# XOXup + left + right + down + upper-left
	# +
	
	94=>13, 
	# XOO
	# OCO
	# XOXup + left + right + down + upper-right
	# +
	
	122=>7,
	# XOX
	# OCO
	# OOXup + left + right + down + lower-left
	# +
	
	218=>11, 
	# XOX
	# OCO
	# XOOup + left + right + down + lower-right
	# +
	
	# Four Connections ==================================

	90=>15, 
	# XOX
	# OCO
	# XOXup + left + right + down
	# +
	
	# Edges ==================================
	
	31=>28, 
	# OOO
	# OCO
	# XXXup + left + right + both upper corners
	# +
	
	107=>24,
	# OOX
	# OCX
	# OOXup + left + down + upper-left + lower-left
	# +
	
	214=>16,
	# XOO
	# XCO
	# XOOup + right + down + upper-right + lower-right
	# +

	248=>20,
	# XXX
	# OCO
	# OOOleft + right + down + both lower corners
	# +
	
	# Edge and One Connection ==================================
	
	95=>12, 
	# OOO
	# OCO
	# XOXup + left + right + down + both upper corners
	# +
	
	222=>9, 
	# XOO
	# OCO
	# XOOup + left + right + down + upper-right + lower-right
	# +
	
	250=>3, 
	# XOX
	# OCO
	# OOOup + left + right + down + both lower corners
	# +
	
	123=>6, 
	# OOX
	# OCO
	# OOXup + left + right + down + upper-left + lower-left
	# +
	
	# Two Empty Corners ==================================
	
	219=>10, 
	# OOX
	# OCO
	# XOOup + left + right + down + upper-left + lower-right
	# +
	
	126=>5, 
	# XOO
	# OCO
	# OOXup + left + right + down + upper-right + lower-left
	# +
	
	# Inner Corners ==================================
	
	127=>4,
	# OOO
	# OCO
	# OOXup + left + right + down + upper corners + lower-left
	# +
	
	223=>8, 
	# OOO
	# OCO
	# XOOup + left + right + down + upper corners + lower-right
	# +
	
	251=>2, 
	# OOX
	# OCO
	# OOOup + left + right + down + upper-left + lower corners
	# +
	
	254=>1, 
	# XOO
	# OCO
	# OOOup + left + right + down + upper-right + lower corners
	# +
	
	# Fully Surrounded ==================================
	
	255=>0
	# OOO
	# OCO
	# OOOfully surrounded
	# +
  }



  def self.autotile_key(tile_id)
    return nil if !tile_id || tile_id <= 0
    return [:normal, (tile_id - 48) / 48] if tile_id >= 48 && tile_id < 384
    return nil if tile_id >= 384
    return nil
  end

  def self.autotile_base(key)
    return 48 + (key[1] * 48) if key[0] == :normal
    return nil
  end

  def self.same_autotile?(x, y, layer, key)
    return false if x < 0 || y < 0 || x >= $game_map.width || y >= $game_map.height
    return autotile_key($game_map.data[x, y, layer]) == key
  end

  def self.autotile_mask(x, y, layer, key)
    up    = same_autotile?(x,     y - 1, layer, key)
    right = same_autotile?(x + 1, y,     layer, key)
    down  = same_autotile?(x,     y + 1, layer, key)
    left  = same_autotile?(x - 1, y,     layer, key)

    ul = up && left  && same_autotile?(x - 1, y - 1, layer, key)
    ur = up && right && same_autotile?(x + 1, y - 1, layer, key)
    dr = down && right && same_autotile?(x + 1, y + 1, layer, key)
    dl = down && left  && same_autotile?(x - 1, y + 1, layer, key)

    mask = 0
    mask |= 1   if ul
    mask |= 2   if up
    mask |= 4   if ur
    mask |= 8   if left
    mask |= 16  if right
    mask |= 32  if dl
    mask |= 64  if down
    mask |= 128 if dr

    return mask
  end

  def self.refresh_cut_autotiles(cx, cy, layer, key, radius = 1)
    return if !key

    base = autotile_base(key)
    return if !base

    (cx - radius..cx + radius).each do |x|
      (cy - radius..cy + radius).each do |y|
        next if x < 0 || y < 0 || x >= $game_map.width || y >= $game_map.height

        tile_id = $game_map.data[x, y, layer]
        next if !tile_id || tile_id == 0
        next if autotile_key(tile_id) != key

        mask = autotile_mask(x, y, layer, key)
        index = BITMASK_TO_AUTOTILE_INDEX[mask]

        next if !index

        $game_map.data[x, y, layer] = base + index
      end
    end
  end
end