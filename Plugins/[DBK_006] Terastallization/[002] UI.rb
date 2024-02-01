#===============================================================================
# UI and visuals.
#===============================================================================

#-------------------------------------------------------------------------------
# Terastal sprite patterns.
#-------------------------------------------------------------------------------
class Sprite
  def apply_tera_pattern(type)
    return if !self.pattern.nil?
    self.zoom_x = 1 if self.zoom_x > 1
    self.zoom_y = 1 if self.zoom_y > 1
    path = Settings::TERASTAL_GRAPHICS_PATH + "Patterns/tera_pattern"
    type_path = path + "_" + type.to_s
    filename = (pbResolveBitmap(type_path)) ? type_path : path
    self.pattern = Bitmap.new(filename)
    self.pattern_opacity = 150
    rand1 = rand(5) - 2
    rand2 = rand(5) - 2
    self.pattern_scroll_x += rand1 * 5
    self.pattern_scroll_y += rand2 * 5
  end

  def set_tera_pattern(pokemon, override = false)
    return if !pokemon.is_a?(Symbol) && pokemon&.dynamax?
    return if !Settings::SHOW_TERA_OVERLAY
    if override || pokemon&.tera?
      apply_tera_pattern(pokemon.tera_type)
    else
      self.pattern = nil
    end
  end
  
  def set_tera_icon_pattern
    return if self.pokemon&.dynamax?
    return if !Settings::SHOW_TERA_OVERLAY
    if self.pokemon&.tera?
      apply_tera_pattern(self.pokemon.tera_type)
    else
      self.pattern = nil
    end
  end
end

#-------------------------------------------------------------------------------
# Pokemon sprites (Defined Pokemon)
#-------------------------------------------------------------------------------
class PokemonSprite < Sprite
  alias tera_setPokemonBitmap setPokemonBitmap
  def setPokemonBitmap(pokemon, back = false)
    tera_setPokemonBitmap(pokemon, back)
    self.set_tera_pattern(pokemon)
  end

  alias tera_setPokemonBitmapSpecies setPokemonBitmapSpecies
  def setPokemonBitmapSpecies(pokemon, species, back = false)
    tera_setPokemonBitmapSpecies(pokemon, species, back)
    self.set_tera_pattern(pokemon)
  end
end

#-------------------------------------------------------------------------------
# Icon sprites (Defined Pokemon)
#-------------------------------------------------------------------------------
class PokemonIconSprite < Sprite
  alias :tera_pokemon= :pokemon=
  def pokemon=(value)
    self.tera_pokemon=(value)
    self.set_tera_icon_pattern
  end
end

#-------------------------------------------------------------------------------
# For displaying Tera types in various UI's.
#-------------------------------------------------------------------------------
def pbDisplayTeraType(pokemon, overlay, xpos, ypos, override = false)
  return if !override && !pokemon.tera_type
  type_number = GameData::Type.get(pokemon.display_tera_type).icon_position
  tera_rect = Rect.new(0, type_number * 32, 32, 32)
  terabitmap = AnimatedBitmap.new(_INTL(Settings::TERASTAL_GRAPHICS_PATH + "tera_types"))
  overlay.blt(xpos, ypos, terabitmap.bitmap, tera_rect)
end

class PokemonStorageScene
  alias tera_pbUpdateOverlay pbUpdateOverlay
  def pbUpdateOverlay(selection, party = nil)
    tera_pbUpdateOverlay(selection, party)
    return if !Settings::STORAGE_TERA_TYPES
    if @sprites["pokemon"].visible
      if !@sprites["plugin_overlay"]
        @sprites["plugin_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @boxsidesviewport)
      end
      plugin_overlay = @sprites["plugin_overlay"].bitmap
      if @screen.pbHeldPokemon
        pokemon = @screen.pbHeldPokemon
      elsif selection >= 0
        pokemon = (party) ? party[selection] : @storage[@storage.currentBox, selection]
      end
      pbDisplayTeraType(pokemon, plugin_overlay, 8, 164)      
    end
  end
end

class PokemonSummary_Scene
  alias tera_drawPageOne drawPageOne
  def drawPageOne
    tera_drawPageOne
    return if !Settings::SUMMARY_TERA_TYPES
    overlay = @sprites["overlay"].bitmap
    coords = (PluginManager.installed?("BW Summary Screen")) ? [122, 129] : [495, 143]
    pbDisplayTeraType(@pokemon, overlay, coords[0], coords[1])
  end
end