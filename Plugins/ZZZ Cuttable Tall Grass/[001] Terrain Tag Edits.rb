#===============================================================================
# Cuttable Tall Grass: Terrain Tag Edits
#===============================================================================

module GameData
  class TerrainTag
    attr_reader :can_cut
    alias cuttable_initialize initialize
    def initialize(hash)
      cuttable_initialize(hash)
      @can_cut = hash[:can_cut] || false
    end
  end
end

CUTTABLE_TERRAIN_TAGS = [
  :Grass,
  :TallGrass,
  :UnderwaterGrass,
  :SootGrass,
  :DarkGrass
]

CUTTABLE_TERRAIN_TAGS.each do |tag_id|
  tag = GameData::TerrainTag.try_get(tag_id)
  next if !tag || tag.id == :None
  tag.instance_variable_set(:@can_cut, true)
end