#-------------------------------------------------------------------------------
# Adds TM Material pocket to the bag.
#-------------------------------------------------------------------------------
module Settings
  Settings.singleton_class.alias_method :tmmaterial_bag_pocket_names, :bag_pocket_names
  
  TMMATERIAL_BAG_POCKET_NAME = _INTL("TM Materials")
  TMMATERIAL_BAG_POCKET = 10
  
  def self.bag_pocket_names
    tmmatpocket = TMMATERIAL_BAG_POCKET - 1
    names = self.tmmaterial_bag_pocket_names
    tmmatpocket = names.length if tmmatpocket >= names.length
    names[tmmatpocket] = TMMATERIAL_BAG_POCKET_NAME
    return names
  end
  
  def self.get_tmmaterial_pocket
    self.bag_pocket_names.each_with_index do |p, i|
      next if p != TMMATERIAL_BAG_POCKET_NAME
      return i + 1
    end
    return TMMATERIAL_BAG_POCKET
  end
   
  BAG_MAX_POCKET_SIZE.push(-1)    if TMMATERIAL_BAG_POCKET > BAG_MAX_POCKET_SIZE.length
  BAG_POCKET_AUTO_SORT.push(true) if TMMATERIAL_BAG_POCKET > BAG_MAX_POCKET_SIZE.length
end

#-------------------------------------------------------------------------------
# Compatibility with the Bag Screen w/int. Party plugin.
#-------------------------------------------------------------------------------
if PluginManager.installed?("Bag Screen w/int. Party")
  class PokemonBag_Scene
    def pbRefresh
      pocketX  = []; incrementX = 0
      @bag.pockets.length.times do |i|
        break if pocketX.length == @bag.pockets.length
        pocketX.push(incrementX)
        incrementX += 2 if i.odd?
      end
      if Settings::TMMATERIAL_BAG_POCKET == 10
        path = "Graphics/UI/Bag Screen with Party/icon_pocket_zcrystal"
        @pocketbitmap = AnimatedBitmap.new(path)
        @sprites["pocketicon"].bitmap.clear
        @sprites["pocketicon"] = BitmapSprite.new(162, 52, @viewport)
        @sprites["pocketicon"].x = 362
        @sprites["pocketicon"].y = 0
        @sprites["currentpocket"].setBitmap(path)
        @sprites["currentpocket"].x = 362
        @sprites["currentpocket"].src_rect = Rect.new(0, 0, 28, 28)
      end
      pocketAcc = @sprites["itemlist"].pocket - 1
      @sprites["pocketicon"].bitmap.clear
      (1...@bag.pockets.length).each do |i|
        pocketValue = i - 1
        @sprites["pocketicon"].bitmap.blt(
          (i - 1) * 14 + pocketX[pocketValue], (i % 2) * 26, @pocketbitmap.bitmap,
          Rect.new((i - 1) * 28, 0, 28, 28)) if pocketValue != pocketAcc
      end
      if @choosing && @filterlist
        (1...@bag.pockets.length).each do |i|
          next if @filterlist[i].length > 0
          pocketValue = i - 1
          @sprites["pocketicon"].bitmap.blt(
            (i - 1) * 14 + pocketX[pocketValue], (i % 2) * 26, @pocketbitmap.bitmap,
            Rect.new((i - 1) * 28, 56, 28, 28))
        end
      end
      @sprites["currentpocket"].x = @sprites["pocketicon"].x + ((pocketAcc) * 14) + pocketX[pocketAcc]
      @sprites["currentpocket"].y = 26 - (((pocketAcc) % 2) * 26)
      @sprites["currentpocket"].src_rect = Rect.new((pocketAcc) * 28, 28, 28, 28)
      @sprites["itemlist"].refresh
      pbRefreshIndexChanged
      pbRefreshParty
      pbPocketColor if BagScreenWiInParty::BGSTYLE == 2
    end
    
    alias tmmaterial_pbUpdateAnnotation pbUpdateAnnotation
    def pbUpdateAnnotation
      item = @sprites["itemlist"].item
      item_data = GameData::Item.try_get(item)
      if item_data && item_data.is_TM_material? && 
        @bag.last_viewed_pocket == Settings::TMMATERIAL_BAG_POCKET
        $player.party.each_with_index do |pkmn, i|
          elig = pkmn.has_zmove?(item)
          annotation = (elig) ? _INTL("ABLE") : _INTL("UNABLE")
          @sprites["pokemon#{i}"].text = annotation
        end
      else
        tmmaterial_pbUpdateAnnotation
      end
    end
  end
end