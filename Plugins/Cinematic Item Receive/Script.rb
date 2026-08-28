#################################################################
# BW Themed- Item Receieve Animation (For the Light/Dark Stone) #
#################################################################

def pbModularCinematicReceive(item_name, ray_name = "ray", shine_name = "shine", beam_name = "item_beam") # You are free to modify any beam/shine/ray of your choice when calling the script!
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  sprites = {}

  sprites["bg"] = Sprite.new(viewport)
  sprites["bg"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
  sprites["bg"].bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 190))
  sprites["bg"].opacity = 0
  sprites["bg"].z = 10

  sprites["beam"] = Sprite.new(viewport)
  sprites["beam"].bitmap = Bitmap.new("Graphics/UI/BW_Stone/#{beam_name}_am")
  sprites["beam"].bitmap = Bitmap.new("Graphics/UI/BW_Stone/#{beam_name}_io") if IASummary::IAVERSION == 2
  sprites["beam"].ox = sprites["beam"].bitmap.width / 2
  sprites["beam"].oy = sprites["beam"].bitmap.height / 2
  sprites["beam"].x = Graphics.width / 2
  sprites["beam"].y = Graphics.height / 2
  sprites["beam"].zoom_x = 0.1 
  sprites["beam"].zoom_y = 0.05 
  sprites["beam"].opacity = 0
  sprites["beam"].blend_type = 0 
  sprites["beam"].z = 20

  sprites["shine"] = Sprite.new(viewport)
  sprites["shine"].bitmap = Bitmap.new("Graphics/UI/BW_Stone/#{shine_name}")
  sprites["shine"].ox = sprites["shine"].bitmap.width / 2
  sprites["shine"].oy = sprites["shine"].bitmap.height / 2
  sprites["shine"].x = Graphics.width / 2
  sprites["shine"].y = Graphics.height / 2
  sprites["shine"].opacity = 0
  sprites["shine"].blend_type = 1 
  sprites["shine"].z = 30  
  
  ray_count = 20
  ray_particles = [] 
  
  ray_count.times do |i|
    ray = Sprite.new(viewport)
    ray.bitmap = Bitmap.new("Graphics/UI/BW_Stone/#{ray_name}")
    ray.ox = 0 
    ray.oy = ray.bitmap.height / 2
    ray.x = Graphics.width / 2
    ray.y = Graphics.height / 2
    ray.blend_type = 1
    ray.opacity = 0
    ray.z = 40 
    angle = rand(360)
    rot_speed = (rand(10) + 5) / 40.0 
    max_life = 160 + rand(120)          
    lifetime = rand(max_life)         
    max_zoom = 1.0 + (rand(15) / 10.0) 
    ray_particles.push({
      :sprite => ray, :angle => angle, :rot_speed => rot_speed, 
      :lifetime => lifetime, :max_life => max_life, :max_zoom => max_zoom
    })
  end

  ambient_particles = []
  ["particle", "eff"].each do |img|
    15.times do
      orb = Sprite.new(viewport)
      orb.bitmap = Bitmap.new("Graphics/UI/BW_Stone/#{img}")
      orb.ox = orb.bitmap.width / 2
      orb.oy = orb.bitmap.height / 2
      orb.opacity = 0
      orb.blend_type = 1
      orb.z = 50 
      rad_angle = rand(360) * Math::PI / 180.0
      base_speed = (rand(20) + 5) / 60.0 
      vx = Math.cos(rad_angle) * base_speed
      vy = Math.sin(rad_angle) * base_speed
      max_life = 200 + rand(160)

      ambient_particles.push({
        :sprite => orb, :vx => vx, :vy => vy,
        :base_x => Graphics.width / 2.0, :base_y => Graphics.height / 2.0,
        :curr_x => Graphics.width / 2.0, :curr_y => Graphics.height / 2.0,
        :lifetime => rand(max_life), :max_life => max_life,
        :scale => 0.5 + rand(8) / 10.0
      })
    end
  end

  sprites["item"] = Sprite.new(viewport)
  begin
    sprites["item"].bitmap = Bitmap.new(GameData::Item.icon_filename(item_name.to_sym))
  rescue
    sprites["item"].bitmap = Bitmap.new("Graphics/Items/#{item_name}")
  end
  sprites["item"].ox = sprites["item"].bitmap.width / 2
  sprites["item"].oy = sprites["item"].bitmap.height / 2
  sprites["item"].x = Graphics.width / 2
  sprites["item"].y = Graphics.height / 2
  sprites["item"].zoom_x = 0
  sprites["item"].zoom_y = 0
  sprites["item"].opacity = 0
  sprites["item"].z = 60 

# Helper Methods
  update_rays = ->(master_alpha) do
    ray_particles.each do |p|
      ray = p[:sprite]
      p[:lifetime] += 1
      if p[:lifetime] > p[:max_life]
        p[:lifetime] = 0
        p[:angle] = rand(360) 
        p[:max_life] = 160 + rand(120)
        p[:max_zoom] = 1.0 + (rand(15) / 10.0)
      end
      life_pct = p[:lifetime].to_f / p[:max_life].to_f
      ray.zoom_x = 0.1 + (p[:max_zoom] * life_pct)
      ray.zoom_y = 1.0 - (life_pct * 0.5)
      base_opacity = Math.sin(life_pct * Math::PI) * 200
      ray.opacity = base_opacity * master_alpha
      p[:angle] -= p[:rot_speed]
      ray.angle = p[:angle]
    end
  end

  update_ambient = ->(master_alpha) do
    ambient_particles.each do |p|
      orb = p[:sprite]
      p[:lifetime] += 1
      if p[:lifetime] > p[:max_life]
        p[:lifetime] = 0
        p[:curr_x] = p[:base_x]
        p[:curr_y] = p[:base_y]
        rad_angle = rand(360) * Math::PI / 180.0
        speed = (rand(20) + 5) / 60.0
        p[:vx] = Math.cos(rad_angle) * speed
        p[:vy] = Math.sin(rad_angle) * speed
        p[:max_life] = 200 + rand(160)
      end
      # Throttled the random frame jitter so they don't vibrate
      p[:curr_x] += p[:vx] + ((rand(10) - 5) / 40.0)
      p[:curr_y] += p[:vy] + ((rand(10) - 5) / 40.0)
      orb.x = p[:curr_x].round
      orb.y = p[:curr_y].round
      orb.zoom_x = orb.zoom_y = p[:scale]
      
      life_pct = p[:lifetime].to_f / p[:max_life].to_f
      base_opacity = Math.sin(life_pct * Math::PI) * 255
      orb.opacity = base_opacity * master_alpha
    end
  end

# Animation Part
  pulse_frame = 0 
  beam_base_y = 0.05 
  particle_fade = 0.0 

  250.times do |frame|
    Graphics.update
    Input.update
    pulse_frame += 1
    if frame == 0
      pbSEPlay("stone") 
    end
    sprites["bg"].opacity += 2.5 if sprites["bg"].opacity < 150
    sprites["beam"].opacity += 10 if sprites["beam"].opacity < 255
    sprites["beam"].zoom_x += 0.2 if sprites["beam"].zoom_x < 2.5
    if sprites["beam"].zoom_x >= 2.5 && beam_base_y < 0.9
      beam_base_y += 0.05 
    end
    sprites["beam"].zoom_y = beam_base_y + (0.1 * Math.sin(pulse_frame * 0.05))

    if frame > 20
      sprites["shine"].opacity += 5 if sprites["shine"].opacity < 255
      sprites["shine"].zoom_x = 1.5 + 0.05 * Math.sin(pulse_frame * 0.05)
      sprites["shine"].zoom_y = 1.5 + 0.05 * Math.sin(pulse_frame * 0.05)
    end

    if frame > 60
      particle_fade += 0.025 if particle_fade < 1.0
      update_rays.call(particle_fade)
      update_ambient.call(particle_fade)
    end
    
    if frame > 100
      sprites["item"].opacity += 12 if sprites["item"].opacity < 255
      if frame <= 130
        if sprites["item"].zoom_x < 1.7
          sprites["item"].zoom_x += 0.075
          sprites["item"].zoom_y += 0.075
          sprites["item"].zoom_x = 1.7 if sprites["item"].zoom_x > 1.7
          sprites["item"].zoom_y = 1.7 if sprites["item"].zoom_y > 1.7
        end
      else
        if sprites["item"].zoom_x > 1.5
          sprites["item"].zoom_x -= 0.025
          sprites["item"].zoom_y -= 0.025
          sprites["item"].zoom_x = 1.5 if sprites["item"].zoom_x < 1.5
          sprites["item"].zoom_y = 1.5 if sprites["item"].zoom_y < 1.5
        end
      end
      sprites["item"].y = (Graphics.height / 2) + Math.sin(pulse_frame * 0.05) * 8
    end
    pbUpdateSceneMap
  end  

  300.times do
    Graphics.update
    Input.update
    pulse_frame += 1
    sprites["beam"].zoom_y = 0.9 + 0.1 * Math.sin(pulse_frame * 0.05)
    sprites["shine"].zoom_x = 1.5 + 0.05 * Math.sin(pulse_frame * 0.05)
    sprites["shine"].zoom_y = 1.5 + 0.05 * Math.sin(pulse_frame * 0.05)
    sprites["item"].y = (Graphics.height / 2) + Math.sin(pulse_frame * 0.05) * 8
    update_rays.call(1.0)
    update_ambient.call(1.0)
    break if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
    pbUpdateSceneMap
  end

  90.times do
    Graphics.update
    sprites["bg"].opacity -= 7.5
    sprites["shine"].opacity -= 7.5
    sprites["item"].opacity -= 7.5
    sprites["item"].zoom_x += 0.025
    sprites["item"].zoom_y += 0.025
    if sprites["beam"].zoom_y > 0.05
      sprites["beam"].zoom_y -= 0.075 
    elsif sprites["beam"].zoom_x > 0.1
      sprites["beam"].zoom_x -= 0.2
    else
      sprites["beam"].opacity -= 15 
    end
    ray_particles.each { |p| p[:sprite].opacity -= 7.5 if p[:sprite] }
    ambient_particles.each { |p| p[:sprite].opacity -= 7.5 if p[:sprite] }
    pbUpdateSceneMap
  end

  ray_particles.each { |p| p[:sprite].dispose }
  ambient_particles.each { |p| p[:sprite].dispose }
  pbDisposeSpriteHash(sprites)
  viewport.dispose
end