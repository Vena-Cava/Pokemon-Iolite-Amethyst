#===============================================================================
# Size Difference - Dynamax Metrics Editor Support
#===============================================================================

class DynamaxSpritePositioner < SpritePositioner
  def pbMenu
    refresh
    cw = Window_CommandPokemon.new([
      _INTL("Set Ally Position"),
      _INTL("Set Enemy Position"),
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
    return pbSetScaleAnchor(0) if param == 4
    return pbSetScaleAnchor(1) if param == 5
    return pbSetScalePreview if param == 6

    return if !@species
    if param == 3
      pbAutoPosition
      return false
    end

    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)

    case param
    when 0
      sprite = @sprites["pokemon_0"]
      xpos = metrics_data.dmax_back_sprite[0]
      ypos = metrics_data.dmax_back_sprite[1]
    when 1
      sprite = @sprites["pokemon_1"]
      xpos = metrics_data.dmax_front_sprite[0]
      ypos = metrics_data.dmax_front_sprite[1]
    when 2
      sprite = @sprites["shadow_1"]
      xpos = metrics_data.dmax_shadow_x
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
      when 2 then @sprites["info"].setTextToFit("Shadow Position = #{xpos}")
      end

      ypos -= 1 if Input.repeat?(Input::UP) && param != 2
      ypos += 1 if Input.repeat?(Input::DOWN) && param != 2
      xpos -= 1 if Input.repeat?(Input::LEFT)
      xpos += 1 if Input.repeat?(Input::RIGHT)

      case param
      when 0
        metrics_data.dmax_back_sprite = [xpos, ypos]
      when 1
        metrics_data.dmax_front_sprite = [xpos, ypos]
      when 2
        metrics_data.dmax_shadow_x = xpos
      end

      refresh

      if Keybinds.trigger?(:back)
        case param
        when 0 then metrics_data.dmax_back_sprite = [oldx, oldy]
        when 1 then metrics_data.dmax_front_sprite = [oldx, oldy]
        when 2 then metrics_data.dmax_shadow_x = oldx
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

    @sprites["info"].visible = false
    sprite.visible = true
    return false
  end
end

#===============================================================================
# TDW Debug List Search - Dynamax Metrics Editor Support
#===============================================================================

class DynamaxSpritePositioner
  def pbChooseSpecies
    return super
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

      # Keep the chosen anchor point stable BEFORE changing zoom.
      sprite.x = original[:x] + ((new_ox - original[:ox]) * original[:zoom_x])
      sprite.y = original[:y] + ((new_oy - original[:oy]) * original[:zoom_y])

      sprite.ox = new_ox
      sprite.oy = new_oy

      # Stack Size Difference on top of Dynamax zoom.
      sprite.zoom_x = original[:zoom_x] * size_zoom
      sprite.zoom_y = original[:zoom_y] * size_zoom
    end
  end
end