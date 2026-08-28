#===============================================================================
## Size Difference
##===============================================================================

class Pokemon
  def scale
    return @scale || 100
  end unless method_defined?(:scale)

  def scale=(value)
    @scale = value.clamp(0, 255)
  end unless method_defined?(:scale=)
end

##===============================================================================
## Metrics PBS Fields
##===============================================================================

module GameData
  class SpeciesMetrics
    attr_accessor :ally_scale_anchor
    attr_accessor :enemy_scale_anchor

    SCHEMA["AllyScaleAnchor"]  = [:ally_scale_anchor, "ii"]
    SCHEMA["EnemyScaleAnchor"] = [:enemy_scale_anchor, "ii"]

    alias ia_size_difference_metrics_initialize initialize unless method_defined?(:ia_size_difference_metrics_initialize)
    def initialize(hash)
      ia_size_difference_metrics_initialize(hash)
      @ally_scale_anchor  = hash[:ally_scale_anchor]  || [0, 0]
      @enemy_scale_anchor = hash[:enemy_scale_anchor] || [0, 0]
    end

    alias ia_size_difference_metrics_get_property_for_PBS get_property_for_PBS unless method_defined?(:ia_size_difference_metrics_get_property_for_PBS)
    def get_property_for_PBS(key)
      ret = ia_size_difference_metrics_get_property_for_PBS(key)
      case key
      when "AllyScaleAnchor"
        ret = nil if ret == [0, 0]
      when "EnemyScaleAnchor"
        ret = nil if ret == [0, 0]
      end
      return ret
    end
  end
end

##===============================================================================
## Battle Sprite Scaling
##===============================================================================

class Battle::Scene::BattlerSprite
  SIZE_VISUAL_MIN = 0.50
  SIZE_VISUAL_MAX = 1.50

  MULTI_ALLY_X_SPREAD = {
    0 => -80,
    2 =>  80,
    4 =>  160
  }

  MULTI_ENEMY_Y_SPREAD = {
    1 =>  60,
    3 => -60,
    5 => -120
  }
  
  def pbSizeDifferencePokemon
    return @pkmn if @pkmn
    return @pokemon if defined?(@pokemon) && @pokemon
    return @battler.pokemon if @battler && @battler.respond_to?(:pokemon)
    return nil
  end

  def pbSizeDifferenceZoom
    pkmn = pbSizeDifferencePokemon
    return 1.0 if !pkmn || !pkmn.respond_to?(:scale)
    return SIZE_VISUAL_MIN + ((pkmn.scale.to_f / 255.0) * 1.0)
  end

  def pbSizeDifferenceEnemySprite?
    return @battler.opposes? if @battler && @battler.respond_to?(:opposes?)
    return !@size_difference_back_sprite
  end

  def pbSizeDifferenceAnchor
    pkmn = pbSizeDifferencePokemon
    return [0, 0] if !pkmn

    metrics = GameData::SpeciesMetrics.get_species_form(pkmn.species, pkmn.form)
    return [0, 0] if !metrics

    anchor = pbSizeDifferenceEnemySprite? ? metrics.enemy_scale_anchor : metrics.ally_scale_anchor
    return anchor || [0, 0]
  end
  
  def pbSizeDifferenceBaseZoom
    pkmn = pbSizeDifferencePokemon
    return 1.0 if !pkmn
    return 1.5 if pkmn.respond_to?(:dynamax?) && pkmn.dynamax? &&
                  defined?(Settings::SHOW_DYNAMAX_SIZE) &&
                  Settings::SHOW_DYNAMAX_SIZE
    return 1.0
  end

  def pbSizeDifferenceMultiOffset
    return [0, 0] if !@battler || !@battler.battle

    side_size = @battler.battle.pbSideSize(@battler.idxOwnSide)
    return [0, 0] if side_size <= 1

    index = @battler.index
    side_pos = index / 2

    if @battler.opposes?
      case side_pos
      when 0 then return [0, 24]
      when 1 then return [0, 16]
      when 2 then return [0, 8]
      end
    else
      case side_pos
      when 0 then return [0, 0]
      when 1 then return [40, 0]
      when 2 then return [80, 0]
      end
    end

    return [0, 0]
  end

  def pbApplySizeDifference
    bitmap = @_iconBitmap || self.bitmap
    return if !bitmap || bitmap.disposed?

    anchor = pbSizeDifferenceAnchor
    zoom   = pbSizeDifferenceZoom

    @size_difference_base_x  = self.x  if @size_difference_base_x.nil?
    @size_difference_base_y  = self.y  if @size_difference_base_y.nil?
    @size_difference_base_ox = self.ox if @size_difference_base_ox.nil?
    @size_difference_base_oy = self.oy if @size_difference_base_oy.nil?

    anchor_x = (bitmap.width / 2) + (anchor[0] * 2)
    anchor_y = bitmap.height + (anchor[1] * 2)

    offset_x = -((anchor_x - @size_difference_base_ox) * (zoom - 1.0))
    offset_y = -((anchor_y - @size_difference_base_oy) * (zoom - 1.0))

    multi_x, multi_y = pbSizeDifferenceMultiOffset

    self.x = @size_difference_base_x + offset_x + multi_x
    self.y = @size_difference_base_y + offset_y + multi_y

    base_zoom = pbSizeDifferenceBaseZoom
    self.zoom_x = base_zoom * zoom
    self.zoom_y = base_zoom * zoom
  end
  
  alias ia_size_difference_setPokemonBitmap setPokemonBitmap unless method_defined?(:ia_size_difference_setPokemonBitmap)
  def setPokemonBitmap(pkmn, back = false)
    @pkmn = pkmn
    @size_difference_back_sprite = back

    @size_difference_base_x  = nil
    @size_difference_base_y  = nil
    @size_difference_base_ox = nil
    @size_difference_base_oy = nil

    ia_size_difference_setPokemonBitmap(pkmn, back)
    pbApplySizeDifference
  end
  
  alias ia_size_difference_pbSetPosition pbSetPosition unless method_defined?(:ia_size_difference_pbSetPosition)
  def pbSetPosition
    ia_size_difference_pbSetPosition

    @size_difference_base_x  = nil
    @size_difference_base_y  = nil
    @size_difference_base_ox = nil
    @size_difference_base_oy = nil

    pbApplySizeDifference
  end
  


  alias ia_size_difference_update update unless method_defined?(:ia_size_difference_update)
  def update
    ia_size_difference_update

    zoom = pbSizeDifferenceBaseZoom * pbSizeDifferenceZoom
    self.zoom_x = zoom
    self.zoom_y = zoom
  end
end

##===============================================================================
## Preserve Size Difference During Battle Animations
##===============================================================================

alias ia_size_difference_setPictureSprite setPictureSprite unless defined?(ia_size_difference_setPictureSprite)

def setPictureSprite(sprite, picture, iconSprite = false)
  ia_size_difference_setPictureSprite(sprite, picture, iconSprite)

  return if !sprite
  return if !picture
  return if iconSprite
  return if !defined?(Battle::Scene::BattlerSprite)
  return if !sprite.is_a?(Battle::Scene::BattlerSprite)

  pkmn = nil
  pkmn = sprite.instance_variable_get(:@pkmn) if sprite.instance_variable_defined?(:@pkmn)
  pkmn = sprite.instance_variable_get(:@pokemon) if !pkmn && sprite.instance_variable_defined?(:@pokemon)

  if !pkmn && sprite.instance_variable_defined?(:@battler)
    battler = sprite.instance_variable_get(:@battler)
    pkmn = battler.pokemon if battler && battler.respond_to?(:pokemon)
  end

  return if !pkmn || !pkmn.respond_to?(:scale)

  min_zoom = Battle::Scene::BattlerSprite::SIZE_VISUAL_MIN
  max_zoom = Battle::Scene::BattlerSprite::SIZE_VISUAL_MAX
  size_zoom = min_zoom + ((pkmn.scale.to_f / 255.0) * (max_zoom - min_zoom))

  anim_zoom_x = picture.respond_to?(:zoom_x) ? picture.zoom_x : 100
  anim_zoom_y = picture.respond_to?(:zoom_y) ? picture.zoom_y : 100

  anim_zoom_x = 100 if anim_zoom_x.nil?
  anim_zoom_y = 100 if anim_zoom_y.nil?

  sprite.zoom_x = (anim_zoom_x / 100.0) * size_zoom
  sprite.zoom_y = (anim_zoom_y / 100.0) * size_zoom
end

##===============================================================================
## Debug Metrics Editor
##===============================================================================

class SpritePositioner
  alias ia_size_difference_pbOpen pbOpen unless method_defined?(:ia_size_difference_pbOpen)
  def pbOpen
    ia_size_difference_pbOpen
    @sprites["scale_anchor_dot"]&.dispose
    @sprites["scale_anchor_dot"] = Sprite.new(@viewport)
    @sprites["scale_anchor_dot"].bitmap = Bitmap.new(2, 2)
    @sprites["scale_anchor_dot"].bitmap.fill_rect(0, 0, 2, 2, Color.new(255, 0, 0))
    @sprites["scale_anchor_dot"].z = 99999
    @sprites["scale_anchor_dot"].visible = false
  end

  def pbMenu
    refresh
    cw = Window_CommandPokemon.new([
      _INTL("Set Ally Position"),
      _INTL("Set Enemy Position"),
      _INTL("Set Shadow Size"),
      _INTL("Set Shadow Position"),
      _INTL("Auto-Position Sprites"),
      _INTL("Set Ally Scale Anchor"),
      _INTL("Set Enemy Scale Anchor"),
      _INTL("Set Scale Preview")
    ])
    cw.x        = Graphics.width - cw.width
    cw.y        = Graphics.height - cw.height
    cw.viewport = @viewport
    ret = -1

    loop do
      Graphics.update
      Input.update
      cw.update
      self.update
      if Keybinds.trigger?(:use)
        pbPlayDecisionSE
        ret = cw.index
        break
      elsif Keybinds.trigger?(:back)
        pbPlayCancelSE
        break
      end
    end

    cw.dispose
    return ret
  end

  def pbSetParameter(param)
    return pbShadowSize if param == 2
    return pbAutoPosition if param == 4
    return pbSetScaleAnchor(0) if param == 5
    return pbSetScaleAnchor(1) if param == 6
    return pbSetScalePreview if param == 7

    metrics = GameData::SpeciesMetrics.get_species_form(@species, @form)

    case param
    when 0
      sprite = @sprites["pokemon_0"]
      xpos = metrics.back_sprite[0]
      ypos = metrics.back_sprite[1]
    when 1
      sprite = @sprites["pokemon_1"]
      xpos = metrics.front_sprite[0]
      ypos = metrics.front_sprite[1]
    when 3
      sprite = @sprites["shadow_1"]
      xpos = metrics.shadow_x
      ypos = 0
    end

    oldx = xpos
    oldy = ypos
    @sprites["info"].visible = true

    loop do
      sprite.visible = ((System.uptime * 8).to_i % 4) < 3
      Graphics.update
      Input.update
      self.update

      case param
      when 0 then @sprites["info"].setTextToFit("Ally Position = #{xpos},#{ypos}")
      when 1 then @sprites["info"].setTextToFit("Enemy Position = #{xpos},#{ypos}")
      when 3 then @sprites["info"].setTextToFit("Shadow Position = #{xpos}")
      end

      ypos -= 1 if Input.repeat?(Input::UP) && param != 3
      ypos += 1 if Input.repeat?(Input::DOWN) && param != 3
      xpos -= 1 if Input.repeat?(Input::LEFT)
      xpos += 1 if Input.repeat?(Input::RIGHT)

      case param
      when 0
        metrics.back_sprite = [xpos, ypos]
      when 1
        metrics.front_sprite = [xpos, ypos]
      when 3
        metrics.shadow_x = xpos
      end

      refresh

      if Keybinds.trigger?(:back)
        case param
        when 0 then metrics.back_sprite = [oldx, oldy]
        when 1 then metrics.front_sprite = [oldx, oldy]
        when 3 then metrics.shadow_x = oldx
        end
        pbPlayCancelSE
        refresh
        break
      elsif Keybinds.trigger?(:use)
        @metricsChanged = true if xpos != oldx || ypos != oldy
        pbPlayDecisionSE
        break
      end
    end

    sprite.visible = true
    @sprites["info"].visible = false
    return false
  end

  def pbSetScaleAnchor(side)
    metrics = GameData::SpeciesMetrics.get_species_form(@species, @form)
    anchor = side == 0 ? metrics.ally_scale_anchor : metrics.enemy_scale_anchor
    anchor ||= [0, 0]

    xpos = anchor[0]
    ypos = anchor[1]
    oldx = xpos
    oldy = ypos
    sprite = @sprites["pokemon_#{side}"]
    dot = @sprites["scale_anchor_dot"]

    dot.visible = true
    @sprites["info"].visible = true

    loop do
      Graphics.update
      Input.update
      self.update

      label = side == 0 ? "Ally Scale Anchor" : "Enemy Scale Anchor"
      @sprites["info"].setTextToFit("#{label} = #{xpos},#{ypos}")

      dot.x = sprite.x + (xpos * 2)
      dot.y = sprite.y + (ypos * 2)

      ypos -= 1 if Input.repeat?(Input::UP)
      ypos += 1 if Input.repeat?(Input::DOWN)
      xpos -= 1 if Input.repeat?(Input::LEFT)
      xpos += 1 if Input.repeat?(Input::RIGHT)

      if side == 0
        metrics.ally_scale_anchor = [xpos, ypos]
      else
        metrics.enemy_scale_anchor = [xpos, ypos]
      end

      if Keybinds.trigger?(:back)
        if side == 0
          metrics.ally_scale_anchor = [oldx, oldy]
        else
          metrics.enemy_scale_anchor = [oldx, oldy]
        end
        pbPlayCancelSE
        break
      elsif Keybinds.trigger?(:use)
        @metricsChanged = true if xpos != oldx || ypos != oldy
        pbPlayDecisionSE
        break
      end
    end

    dot.visible = false
    @sprites["info"].visible = false
    return false
  end

  def pbSizePreviewZoom(scale_value)
    return 0.50 + ((scale_value.to_f / 255.0) * 1.0)
  end

  def pbApplyScalePreview(scale_value)
    metrics = GameData::SpeciesMetrics.get_species_form(@species, @form)
    size_zoom = pbSizePreviewZoom(scale_value)

    @scale_preview_originals ||= {}

    [0, 1].each do |side|
      sprite = @sprites["pokemon_#{side}"]
      next if !sprite || !sprite.bitmap

      @scale_preview_originals[side] ||= {
        :x => sprite.x,
        :y => sprite.y,
        :ox => sprite.ox,
        :oy => sprite.oy,
        :zoom_x => sprite.zoom_x,
        :zoom_y => sprite.zoom_y
      }

      original = @scale_preview_originals[side]

      anchor = side == 0 ? metrics.ally_scale_anchor : metrics.enemy_scale_anchor
      anchor ||= [0, 0]

      new_ox = (sprite.bitmap.width / 2) + (anchor[0] * 2)
      new_oy = sprite.bitmap.height + (anchor[1] * 2)

      sprite.x  = original[:x] + (new_ox - original[:ox])
      sprite.y  = original[:y] + (new_oy - original[:oy])
      sprite.ox = new_ox
      sprite.oy = new_oy

      # Stack Size Difference on top of the current editor zoom.
      sprite.zoom_x = original[:zoom_x] * size_zoom
      sprite.zoom_y = original[:zoom_y] * size_zoom
    end
  end

  def pbClearScalePreview
    if @scale_preview_originals
      @scale_preview_originals.each do |side, original|
        sprite = @sprites["pokemon_#{side}"]
        next if !sprite
        sprite.x      = original[:x]
        sprite.y      = original[:y]
        sprite.ox     = original[:ox]
        sprite.oy     = original[:oy]
        sprite.zoom_x = original[:zoom_x]
        sprite.zoom_y = original[:zoom_y]
      end
    end

    @scale_preview_originals = nil
    refresh
  end

  def pbSetScalePreview
    scale_value = 128
    @scale_preview_originals = nil

    @sprites["info"].visible = true
    pbApplyScalePreview(scale_value)

    loop do
      Graphics.update
      Input.update
      self.update

      zoom_percent = (pbSizePreviewZoom(scale_value) * 100).round
      @sprites["info"].setTextToFit("Scale Preview = #{scale_value}/255  (#{zoom_percent}%)")

      scale_value -= 1  if Input.repeat?(Input::LEFT)
      scale_value += 1  if Input.repeat?(Input::RIGHT)
      scale_value += 16 if Input.repeat?(Input::UP)
      scale_value -= 16 if Input.repeat?(Input::DOWN)

      scale_value = scale_value.clamp(0, 255)
      pbApplyScalePreview(scale_value)

      if Keybinds.trigger?(:back) || Keybinds.trigger?(:use)
        pbPlayDecisionSE if Keybinds.trigger?(:use)
        pbPlayCancelSE if Keybinds.trigger?(:back)
        break
      end
    end

    pbClearScalePreview
    @sprites["info"].visible = false
    return false
  end
end