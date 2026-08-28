#===============================================================================
# Nuzlocke - Retired Pokémon Icon UI
# True grayscale + no animation
#===============================================================================

class Bitmap
  def advanced_new_game_grayscale!
    self.width.times do |x|
      self.height.times do |y|
        c = get_pixel(x, y)
        next if c.alpha == 0
        gray = ((c.red * 0.299) + (c.green * 0.587) + (c.blue * 0.114)).to_i
        set_pixel(x, y, Color.new(gray, gray, gray, c.alpha))
      end
    end
  end
end

class PokemonIconSprite
  alias advanced_new_game_retired_ui_dispose dispose
  alias advanced_new_game_retired_ui_pokemon= pokemon=
  alias advanced_new_game_retired_ui_update_frame update_frame
  alias advanced_new_game_retired_ui_update update

  def dispose
    @advanced_new_game_gray_bitmap&.dispose
    advanced_new_game_retired_ui_dispose
  end

  def pokemon=(value)
    @advanced_new_game_gray_bitmap&.dispose
    @advanced_new_game_gray_bitmap = nil
    self.advanced_new_game_retired_ui_pokemon = value
  end

  def advanced_new_game_retired_icon?
    return false if !@pokemon
    return @pokemon.nuzlocke_retired?
  end

  def update_frame
    if advanced_new_game_retired_icon?
      @current_frame = 0
      return
    end

    advanced_new_game_retired_ui_update_frame
  end

  def update
    advanced_new_game_retired_ui_update

    return if !advanced_new_game_retired_icon?
    return if !@animBitmap
    return if !self.src_rect

    old_rect = self.src_rect.clone

    if !@advanced_new_game_gray_bitmap
      sheet = @animBitmap.bitmap
      @advanced_new_game_gray_bitmap = Bitmap.new(old_rect.width, old_rect.height)
      @advanced_new_game_gray_bitmap.blt(
        0, 0,
        sheet,
        old_rect
      )
      @advanced_new_game_gray_bitmap.advanced_new_game_grayscale!
    end

    self.bitmap = @advanced_new_game_gray_bitmap
    self.src_rect = Rect.new(
      0,
      0,
      @advanced_new_game_gray_bitmap.width,
      @advanced_new_game_gray_bitmap.height
    )
  end
end

#===============================================================================
# Summary Screen Retired Icon
#===============================================================================

class PokemonSummary_Scene
  alias advanced_new_game_retired_summary_pbStartScene pbStartScene
  alias advanced_new_game_retired_summary_drawPage drawPage

  def pbStartScene(*args)
    advanced_new_game_retired_summary_pbStartScene(*args)

    @sprites["retired_icon"] = IconSprite.new(0, 0, @viewport)
    @sprites["retired_icon"].setBitmap("Graphics/UI/Summary/icon_retired")
    @sprites["retired_icon"].x = 124
    @sprites["retired_icon"].y = 100
    @sprites["retired_icon"].visible = false
  end

  def drawPage(page)
    advanced_new_game_retired_summary_drawPage(page)
    refresh_retired_icon
  end

  def refresh_retired_icon
    return if !@sprites["retired_icon"]

    @sprites["retired_icon"].visible = (
      @pokemon &&
      @pokemon.respond_to?(:nuzlocke_retired?) &&
      @pokemon.nuzlocke_retired?
    )
  end
end

#===============================================================================
# Retired Pokémon - Main Pokémon sprites
# Summary screen, storage preview, etc.
#===============================================================================

class PokemonSprite
  alias advanced_new_game_retired_sprite_setPokemonBitmap setPokemonBitmap
  alias advanced_new_game_retired_sprite_update update
  alias advanced_new_game_retired_sprite_dispose dispose

  def setPokemonBitmap(pokemon, back = false)
    @advanced_new_game_retired_pokemon = pokemon
    @advanced_new_game_gray_sprite&.dispose
    @advanced_new_game_gray_sprite = nil
    @advanced_new_game_gray_source = nil

    advanced_new_game_retired_sprite_setPokemonBitmap(pokemon, back)

    return if !pokemon

    apply_advanced_new_game_retired_sprite
  end

  def update
    advanced_new_game_retired_sprite_update

    # Needed because storage/summary refreshes the bitmap during updates.
    apply_advanced_new_game_retired_sprite
  end

  def dispose
    @advanced_new_game_gray_sprite&.dispose
    @advanced_new_game_gray_sprite = nil
    advanced_new_game_retired_sprite_dispose
  end

  def apply_advanced_new_game_retired_sprite
    pokemon = @advanced_new_game_retired_pokemon
    return if !pokemon
    return if !pokemon.respond_to?(:nuzlocke_retired?)
    return if !pokemon.nuzlocke_retired?
    return if !self.bitmap || self.bitmap.disposed?
    return if self.bitmap == @advanced_new_game_gray_sprite

    source = self.bitmap
    return if source == @advanced_new_game_gray_sprite

    if @advanced_new_game_gray_source != source
      @advanced_new_game_gray_sprite&.dispose
      @advanced_new_game_gray_sprite = Bitmap.new(source.width, source.height)
      @advanced_new_game_gray_sprite.blt(0, 0, source, Rect.new(0, 0, source.width, source.height))
      @advanced_new_game_gray_sprite.advanced_new_game_grayscale!
      @advanced_new_game_gray_source = source
    end

    self.bitmap = @advanced_new_game_gray_sprite
    changeOrigin if respond_to?(:changeOrigin)
  end
end