#===============================================================================
# Menu handler for the Pokedex Data page.
#===============================================================================
UIHandlers.add(:pokedex, :page_height, { 
  "name"      => "HEIGHT",
  "suffix"    => "height",
  "order"     => 50,
  "layout"    => proc { |species, scene| scene.drawPageSizes }
})
UIHandlers.add(:pokedex, :page_weight, { 
  "name"      => "WEIGHT",
  "suffix"    => "weight",
  "order"     => 60,
  "layout"    => proc { |species, scene| scene.drawPageW }
})


class PokemonPokedexInfo_Scene
  alias hw_drawPage drawPage
  def drawPage(page)
    hw_drawPage(page)
    if @sprites["overlay2"]
      overlay2 = @sprites["overlay2"].bitmap
      overlay2.clear
    end
    # Make certain sprites visible
    @sprites["pokesize"].visible    = (@page_id == :page_height) if @sprites["pokesize"]
    @sprites["trainer"].visible     = (@page_id == :page_height) if @sprites["trainer"]
    @sprites["pokeicon"].visible    = (@page_id == :page_weight) if @sprites["pokeicon"]
    @sprites["tricon"].visible      = (@page_id == :page_weight) if @sprites["tricon"]
    @sprites["scale"].visible       = (@page_id == :page_weight) if @sprites["scale"]
  end
  #-----------------------------------------------------------------------------
  # Allows for a custom action on the Data page when the USE key is pressed.
  #-----------------------------------------------------------------------------
  alias hw_pbPageCustomUse pbPageCustomUse
  def pbPageCustomUse(page_id)
    if [:page_weight,:page_height].include?(page_id)
      if @availableComparator.length > 1
        pbPlayDecisionSE
        pbChooseHWComparator
      end
      return true
    end
    return hw_pbPageCustomUse(page_id)
  end
end