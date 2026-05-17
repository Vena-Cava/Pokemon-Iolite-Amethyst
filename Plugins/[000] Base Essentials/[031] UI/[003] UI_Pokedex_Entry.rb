#===============================================================================
# Iolite & Amethyst Pokédex Screen
#===============================================================================

class PokemonPokedexInfo_Scene
  def pbStartScene(dexlist, index, region)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 100000
    @dexlist = dexlist
    @index   = index
    @region  = region
    @page = 1
    @show_battled_count = false
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_types"))
    @sprites = {}
	  @sprites["panorama"] = IconSprite.new(0, 0, @viewport)
	  @sprites["panorama"].setBitmap("Graphics/UI/Summary/bg_pan_am")
    @sprites["panorama"].z = -100
    @sprites["panorama"].visible = true
    @sprites["pokeball"] = IconSprite.new(0, 0, @viewport)
    @sprites["pokeball"].x = 104
    @sprites["pokeball"].y = 136
    @sprites["pokeball"].angle = 45   # 45 degrees clockwise
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
	  white = Tone.new(255, 255, 255)
    @sprites["pokemonglow1"] = PokemonSprite.new(@viewport)
    @sprites["pokemonglow1"].setOffset(PictureOrigin::CENTER)
	  @sprites["pokemonglow1"].x = 104
	  @sprites["pokemonglow1"].y = 136
    @sprites["pokemonglow1"].tone = white
	  @sprites["pokemonglow1"].opacity = 120
    @sprites["pokemonglow1"].z = 300
    @sprites["pokemonglow2"] = PokemonSprite.new(@viewport)
    @sprites["pokemonglow2"].setOffset(PictureOrigin::CENTER)
	  @sprites["pokemonglow2"].x = 104
	  @sprites["pokemonglow2"].y = 136
    @sprites["pokemonglow2"].tone = white
	  @sprites["pokemonglow2"].opacity = 120
    @sprites["pokemonglow1"].z = 300
    @sprites["pokemonglow3"] = PokemonSprite.new(@viewport)
    @sprites["pokemonglow3"].setOffset(PictureOrigin::CENTER)
	  @sprites["pokemonglow3"].x = 104
	  @sprites["pokemonglow3"].y = 136
    @sprites["pokemonglow3"].tone = white
	  @sprites["pokemonglow3"].opacity = 120
    @sprites["pokemonglow3"].z = 300
    @sprites["pokemonglow4"] = PokemonSprite.new(@viewport)
    @sprites["pokemonglow4"].setOffset(PictureOrigin::CENTER)
	  @sprites["pokemonglow4"].x = 104
	  @sprites["pokemonglow4"].y = 136
    @sprites["pokemonglow4"].tone = white
	  @sprites["pokemonglow4"].opacity = 120
    @sprites["pokemonglow4"].z = 300
    @sprites["infosprite"] = PokemonSprite.new(@viewport)
    @sprites["infosprite"].setOffset(PictureOrigin::CENTER)
    @sprites["infosprite"].x = 104
    @sprites["infosprite"].y = 136
    @sprites["infosprite"].z = 301
    mappos = $game_map.metadata&.town_map_position
    if @region < 0                                 # Use player's current region
      @region = (mappos) ? mappos[0] : 0                      # Region 0 default
    end
    @mapdata = GameData::TownMap.get(@region)
    @sprites["areamap"] = IconSprite.new(0, 0, @viewport)
    @sprites["areamap"].setBitmap("Graphics/UI/Town Map/#{@mapdata.filename}")
    @sprites["areamap"].x = 188
    @sprites["areamap"].y = 48
    @sprites["areamap"].z = -1
    Settings::REGION_MAP_EXTRAS.each do |hidden|
      next if hidden[0] != @region || hidden[1] <= 0 || !$game_switches[hidden[1]]
      pbDrawImagePositions(
        @sprites["areamap"].bitmap,
        [["Graphics/UI/Town Map/#{hidden[4]}",
          hidden[2] * PokemonRegionMap_Scene::SQUARE_WIDTH,
          hidden[3] * PokemonRegionMap_Scene::SQUARE_HEIGHT]]
      )
    end
    @sprites["areahighlight"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["areaoverlay"] = IconSprite.new(0, 0, @viewport)
    @sprites["areaoverlay"].setBitmap("Graphics/UI/Pokedex/overlay_area")
    @sprites["tod_icon"] = IconSprite.new(0, 0, @viewport)
    @sprites["tod_icon"].x = 136
    @sprites["tod_icon"].y = 46 
    @sprites["tod_icon"].visible = false
    @sprites["weather_icon"] = IconSprite.new(0, 0, @viewport)
    @sprites["weather_icon"].x = 136
    @sprites["weather_icon"].y = 96
    @sprites["weather_icon"].visible = false
    @sprites["method_icon"] = IconSprite.new(0, 0, @viewport)
    @sprites["method_icon"].x = 136
    @sprites["method_icon"].y = 146
    @sprites["method_icon"].visible = false
    @sprites["formfront"] = PokemonSprite.new(@viewport)
    @sprites["formfront"].setOffset(PictureOrigin::CENTER)
    @sprites["formfront"].x = 130
    @sprites["formfront"].y = 158
    @sprites["formback"] = PokemonSprite.new(@viewport)
    @sprites["formback"].setOffset(PictureOrigin::BOTTOM)
    @sprites["formback"].x = 382   # y is set below as it depends on metrics
    @sprites["formicon"] = PokemonSpeciesIconSprite.new(nil, @viewport)
    @sprites["formicon"].setOffset(PictureOrigin::CENTER)
    @sprites["formicon"].x = 82
    @sprites["formicon"].y = 328
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/UI/up_arrow", 8, 28, 40, 2, @viewport)
    @sprites["uparrow"].x = 242
    @sprites["uparrow"].y = 268
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/UI/down_arrow", 8, 28, 40, 2, @viewport)
    @sprites["downarrow"].x = 242
    @sprites["downarrow"].y = 348
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbUpdateDummyPokemon
    @available = pbGetAvailableForms
    @area_locations = []
    @area_loc_index = 0
    @area_selecting_location = false
    refreshAreaLocations
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  # Returns a hash like {:day=>true, :night=>false, :morning=>true, ...}
  def pbSpeciesEncounterTimes(species)
    times = {
      :morning   => false,
      :afternoon => false,
      :evening   => false,
      :day       => false,
      :night     => false,
      :any       => false   # encounter types with no time suffix (assume "all times")
    }
  
    suffix_map = {
      "Morning"   => :morning,
      "Afternoon" => :afternoon,
      "Evening"   => :evening,
      "Day"       => :day,
      "Night"     => :night
    }
  
    GameData::Encounter.each_of_version($PokemonGlobal.encounter_version) do |enc_data|
      next if !enc_data || !enc_data.types
      enc_data.types.each do |enc_type, slots|
        next if !slots
        # Does this table contain our species?
        next if !slots.any? { |slot| GameData::Species.get(slot[1]).species == species }
  
        type_name = enc_type.to_s
        matched = false
        suffix_map.each do |suffix, key|
          if type_name.end_with?(suffix)
            times[key] = true
            matched = true
            break
          end
        end
        times[:any] = true if !matched   # e.g. :Land, :Cave, :Water with no suffix
      end
    end
  
    return times
  end
  
  # For standalone access, shows first page only.
  def pbStartSceneBrief(species)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 100000
    dexnum = 0
    dexnumshift = false
    if $player.pokedex.unlocked?(-1)   # National Dex is unlocked
      species_data = GameData::Species.try_get(species)
      if species_data
        nationalDexList = [:NONE]
        GameData::Species.each_species { |s| nationalDexList.push(s.species) }
        dexnum = nationalDexList.index(species_data.species) || 0
        dexnumshift = true if dexnum > 0 && Settings::DEXES_WITH_OFFSETS.include?(-1)
      end
    else
      ($player.pokedex.dexes_count - 1).times do |i|   # Regional Dexes
        next if !$player.pokedex.unlocked?(i)
        num = pbGetRegionalNumber(i, species)
        next if num <= 0
        dexnum = num
        dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(i)
        break
      end
    end
    @dexlist = [{
      :species => species,
      :name    => "",
      :height  => 0,
      :weight  => 0,
      :number  => dexnum,
      :shift   => dexnumshift
    }]
    @index = 0
    @page = 1
    @brief = true
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_types"))
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["pokemonglow1"] = PokemonSprite.new(@viewport)
    @sprites["pokemonglow1"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemonglow1"].x = 102
    @sprites["pokemonglow1"].y = 136
    @sprites["pokemonglow2"] = PokemonSprite.new(@viewport)
    @sprites["pokemonglow2"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemonglow2"].x = 106
    @sprites["pokemonglow2"].y = 136
    @sprites["pokemonglow3"] = PokemonSprite.new(@viewport)
    @sprites["pokemonglow3"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemonglow3"].x = 104
    @sprites["pokemonglow3"].y = 134
    @sprites["pokemonglow4"] = PokemonSprite.new(@viewport)
    @sprites["pokemonglow4"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemonglow4"].x = 104
    @sprites["pokemonglow4"].y = 138
    @sprites["infosprite"] = PokemonSprite.new(@viewport)
    @sprites["infosprite"].setOffset(PictureOrigin::CENTER)
    @sprites["infosprite"].x = 104
    @sprites["infosprite"].y = 136
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbUpdateDummyPokemon
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @viewport.dispose
  end

  def pbUpdate
	  @sprites["panorama"].x  = 0 if @sprites["panorama"].x == - 56
	  @sprites["panorama"].x -= 2 if IASummary::PANORAMA == true
	  @sprites["panorama"].setBitmap("Graphics/UI/Summary/bg_pan_io") if IASummary::IAVERSION == 2
    @sprites["pokeball"].angle += 1
    @sprites["pokeball"].angle %= 360
    if @page == 2
      intensity_time = System.uptime % 1.0   # 1 second per glow
      if intensity_time >= 0.5
        intensity = lerp(64, 256 + 64, 0.5, intensity_time - 0.5)
      else
        intensity = lerp(256 + 64, 64, 0.5, intensity_time)
      end
      @sprites["areahighlight"].opacity = intensity
    end
    pbUpdateSpriteHash(@sprites)
  end

  def pbUpdateDummyPokemon
    @species = @dexlist[@index][:species]
    @gender, @form, _shiny = $player.pokedex.last_form_seen(@species)
    @shiny = false
    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    @sprites["infosprite"].setSpeciesBitmap(@species, @gender, @form, @shiny)
    @sprites["pokemonglow1"].setSpeciesBitmap(@species, @gender, @form, @shiny)
    @sprites["pokemonglow2"].setSpeciesBitmap(@species, @gender, @form, @shiny)
    @sprites["pokemonglow3"].setSpeciesBitmap(@species, @gender, @form, @shiny)
    @sprites["pokemonglow4"].setSpeciesBitmap(@species, @gender, @form, @shiny)
    @sprites["formfront"]&.setSpeciesBitmap(@species, @gender, @form, @shiny)
    if @sprites["formback"]
      @sprites["formback"].setSpeciesBitmap(@species, @gender, @form, @shiny, false, true)
      @sprites["formback"].y = 256
      # @sprites["formback"].y += metrics_data.back_sprite[1] * 2
    end
    @sprites["formicon"]&.pbSetParams(@species, @gender, @form, @shiny)
    refreshAreaLocations
  end
  
  def pbGetAvailableForms
    ret = []
    multiple_forms = false
    gender_differences = (GameData::Species.front_sprite_filename(@species, 0) == GameData::Species.front_sprite_filename(@species, 0, 1))
    # Find all genders/forms of @species that have been seen
    GameData::Species.each do |sp|
      next if sp.species != @species
      next if sp.form != 0 && (!sp.real_form_name || sp.real_form_name.empty?)
      next if sp.pokedex_form != sp.form
      multiple_forms = true if sp.form > 0
      if sp.single_gendered?
        real_gender = (sp.gender_ratio == :AlwaysFemale) ? 1 : 0
        next if !$player.pokedex.seen_form?(@species, real_gender, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
        real_gender = 2 if sp.gender_ratio == :Genderless
        ret.push([sp.form_name, real_gender, sp.form])
      elsif sp.form == 0 && !gender_differences
        2.times do |real_gndr|
          next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
          ret.push([sp.form_name || _INTL("One Form"), 0, sp.form])
          break
        end
      else   # Both male and female
        2.times do |real_gndr|
          next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
          ret.push([sp.form_name, real_gndr, sp.form])
          break if sp.form_name && !sp.form_name.empty?   # Only show 1 entry for each non-0 form
        end
      end
    end
    # Sort all entries
    ret.sort! { |a, b| (a[2] == b[2]) ? a[1] <=> b[1] : a[2] <=> b[2] }
    # Create form names for entries if they don't already exist
    ret.each do |entry|
      if entry[0]   # Alternate forms, and form 0 if no gender differences
        entry[0] = "" if !multiple_forms && !gender_differences
      else   # Necessarily applies only to form 0
        case entry[1]
        when 0 then entry[0] = _INTL("Male")
        when 1 then entry[0] = _INTL("Female")
        else
          entry[0] = (multiple_forms) ? _INTL("Base Form") : _INTL("Genderless")
        end
      end
      entry[1] = 0 if entry[1] == 2   # Genderless entries are treated as male
    end
    return ret
  end

  def drawPage(page)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Make certain sprites visible
    @sprites["infosprite"].visible    = (@page == 1)
    @sprites["pokeball"].visible      = (@page == 1)
	  @sprites["pokemonglow1"].visible  = (@page == 1)
	  @sprites["pokemonglow2"].visible  = (@page == 1)
	  @sprites["pokemonglow3"].visible  = (@page == 1)
	  @sprites["pokemonglow4"].visible  = (@page == 1)
    @sprites["areamap"].visible       = (@page == 2) if @sprites["areamap"]
    @sprites["areahighlight"].visible = (@page == 2) if @sprites["areahighlight"]
    @sprites["areaoverlay"].visible   = (@page == 2) if @sprites["areaoverlay"]
    @sprites["tod_icon"].visible      = (@page == 2) if @sprites["tod_icon"]
    @sprites["formfront"].visible     = (@page == 3) if @sprites["formfront"]
    @sprites["formback"].visible      = (@page == 3) if @sprites["formback"]
    @sprites["formicon"].visible      = (@page == 3) if @sprites["formicon"]
    # Draw page-specific information
    case page
    when 1 then drawPageInfo
    when 2 then drawPageArea
    when 3 then drawPageForms
    end
  end

  def drawPageInfo
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_info"))
    @sprites["pokeball"].setBitmap(_INTL("Graphics/UI/Pokedex/pokeball"))
    # Center-anchor the pokeball on its x/y
    b = @sprites["pokeball"].bitmap
    @sprites["pokeball"].ox = b.width / 2
    @sprites["pokeball"].oy = b.height / 2
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    whitetext = Color.new(248, 248, 248)
    imagepos = []
    imagepos.push([_INTL("Graphics/UI/Pokedex/overlay_info"), 0, 0]) if @brief
    species_data = GameData::Species.get_species_form(@species, @form)
    # Write various bits of text
    indexText = "???"
    if @dexlist[@index][:number] > 0
      indexNumber = @dexlist[@index][:number]
      indexNumber -= 1 if @dexlist[@index][:shift]
      indexText = sprintf("%03d", indexNumber)
    end
    textpos = [
      [_INTL("{1}{2} {3}", indexText, " ", species_data.name),
       246, 48, :left, Color.new(248, 248, 248), Color.white]
    ]
    if @show_battled_count
      textpos.push([_INTL("Number Battled"), 314, 164, :left, whitetext, shadow])
      textpos.push([$player.pokedex.battled_count(@species).to_s, 452, 196, :right, base, shadow])
    else
      textpos.push([_INTL("Height"), 314, 164, :left, whitetext, shadow])
      textpos.push([_INTL("Weight"), 314, 196, :left, whitetext, shadow])
    end
    if $player.owned?(@species)
      # Write the category
      textpos.push([_INTL("{1} Pokémon", species_data.category), 246, 80, :left, base, shadow])
      # Write the height and weight
      if !@show_battled_count
        height = species_data.height
        weight = species_data.weight
        if System.user_language[3..4] == "US"   # If the user is in the United States
          inches = (height / 0.254).round
          pounds = (weight / 0.45359).round
          textpos.push([_ISPRINTF("{1:d}'{2:02d}\"", inches / 12, inches % 12), 460, 164, :right, base, shadow])
          textpos.push([_ISPRINTF("{1:4.1f} lbs.", pounds / 10.0), 494, 196, :right, base, shadow])
        else
          textpos.push([_ISPRINTF("{1:.1f} m", height / 10.0), 470, 164, :right, base, shadow])
          textpos.push([_ISPRINTF("{1:.1f} kg", weight / 10.0), 482, 196, :right, base, shadow])
        end
      end
      # Draw the Pokédex entry text
      if System.user_language[3..4] == "US"   # If the user is in the United States
        drawTextEx(overlay, 40, 246, Graphics.width - 80, 4,   # overlay, x, y, width, num lines
                 species_data.ampokedexus_entry, base, shadow) if IASummary::IAVERSION == 1
        drawTextEx(overlay, 40, 246, Graphics.width - 80, 4,   # overlay, x, y, width, num lines
                 species_data.iopokedexus_entry, base, shadow) if IASummary::IAVERSION == 2
      else
        drawTextEx(overlay, 40, 246, Graphics.width - 80, 4,   # overlay, x, y, width, num lines
                 species_data.ampokedex_entry, base, shadow) if IASummary::IAVERSION == 1
        drawTextEx(overlay, 40, 246, Graphics.width - 80, 4,   # overlay, x, y, width, num lines
                 species_data.iopokedex_entry, base, shadow) if IASummary::IAVERSION == 2
      end
      # Draw the footprint
      footprintfile = GameData::Species.footprint_filename(@species, @form)
      if footprintfile
        footprint = RPG::Cache.load_bitmap("", footprintfile)
        overlay.blt(226, 138, footprint, footprint.rect)
        footprint.dispose
      end
      # Show the owned icon
      imagepos.push(["Graphics/UI/Pokedex/icon_own", 212, 44])
      # Draw the type icon(s)
      species_data.types.each_with_index do |type, i|
        type_number = GameData::Type.get(type).icon_position
        type_rect = Rect.new(0, type_number * 32, 96, 32)
        overlay.blt(296 + (100 * i), 120, @typebitmap.bitmap, type_rect)
      end
    else
      # Write the category
      textpos.push([_INTL("????? Pokémon"), 246, 80, :left, base, shadow])
      # Write the height and weight
      if !@show_battled_count
        if System.user_language[3..4] == "US"   # If the user is in the United States
          textpos.push([_INTL("???'??\""), 460, 164, :right, base, shadow])
          textpos.push([_INTL("????.? lbs."), 494, 196, :right, base, shadow])
        else
          textpos.push([_INTL("????.? m"), 470, 164, :right, base, shadow])
          textpos.push([_INTL("????.? kg"), 482, 196, :right, base, shadow])
        end
      end
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
  end

  def pbFindEncounter(enc_types, species)
    return false if !enc_types
    enc_types.each_value do |slots|
      next if !slots
      slots.each { |slot| return true if GameData::Species.get(slot[1]).species == species }
    end
    return false
  end

  # Returns a 1D array of values corresponding to points on the Town Map. Each
  # value is true or false.
  def pbGetEncounterPoints(map_filter = nil)
    visible_points = []
    @mapdata.point.each do |loc|
      next if loc[7] && !$game_switches[loc[7]]
      visible_points.push([loc[0], loc[1]])
    end
  
    town_map_width = 1 + PokemonRegionMap_Scene::RIGHT - PokemonRegionMap_Scene::LEFT
    ret = []
  
    GameData::Encounter.each_of_version($PokemonGlobal.encounter_version) do |enc_data|
      next if !enc_data || !enc_data.types
      next if map_filter && enc_data.map != map_filter
      next if !pbFindEncounter(enc_data.types, @species)
  
      map_metadata = GameData::MapMetadata.try_get(enc_data.map)
      next if !map_metadata || map_metadata.has_flag?("HideEncountersInPokedex")
  
      mappos = map_metadata.town_map_position
      next if !mappos
      next if mappos[0] != @region
  
      map_size = map_metadata.town_map_size
      map_width = 1
      map_height = 1
      map_shape = "1"
      if map_size && map_size[0] && map_size[0] > 0
        map_width = map_size[0]
        map_shape = map_size[1]
        map_height = (map_shape.length.to_f / map_width).ceil
      end
  
      map_width.times do |i|
        map_height.times do |j|
          next if map_shape[i + (j * map_width), 1].to_i == 0
          next if !visible_points.include?([mappos[1] + i, mappos[2] + j])
          ret[mappos[1] + i + ((mappos[2] + j) * town_map_width)] = true
        end
      end
    end
  
    return ret
  end
  
  #-------------------------------------------------------------------------------
  # AREA PAGE: Build list of maps in this region where @species appears, along with
  # which encounter types contain it.
  #-------------------------------------------------------------------------------
  def refreshAreaLocations
    @area_locations = []   # each entry: { map: Integer, name: String, types: [Symbol], points: [] }
    @area_loc_index = 0 if @area_loc_index.nil?
  
    return if !@mapdata || !@species
  
    # Gather maps (in current region) where this species appears
    GameData::Encounter.each_of_version($PokemonGlobal.encounter_version) do |enc_data|
      next if !enc_data || !enc_data.types
      next if !pbFindEncounter(enc_data.types, @species)
  
      map_metadata = GameData::MapMetadata.try_get(enc_data.map)
      next if !map_metadata
      next if map_metadata.has_flag?("HideEncountersInPokedex")
  
      mappos = map_metadata.town_map_position
      next if !mappos
      next if mappos[0] != @region
  
      # Which encounter type keys (LandDay, OldRod, etc) include this species?
      matched_types = []
      enc_data.types.each do |enc_type, slots|
        next if !slots
        slots.each do |slot|
          next if !slot || !slot[1]
          sp = GameData::Species.get(slot[1]).species
          if sp == @species
            matched_types << enc_type
            break
          end
        end
      end
      next if matched_types.empty?
  
      # Avoid duplicates (same map can appear multiple times due to versions/forms etc)
      existing = @area_locations.find { |e| e[:map] == enc_data.map }
      if existing
        existing[:types] |= matched_types
      else
        @area_locations << {
          map:   enc_data.map,
          name:  map_metadata.name,
          types: matched_types
        }
      end
    end
  
    # Keep stable ordering
    @area_locations.sort_by! { |e| e[:name].to_s }
  
    # Clamp selection
    if @area_locations.empty?
      @area_loc_index = 0
    else
      @area_loc_index %= @area_locations.length
    end
    refreshAreaEncounters
  end
  
  #-------------------------------------------------------------------------------
  # Given the currently selected area location, return the map id (or nil).
  #-------------------------------------------------------------------------------
  def currentAreaMap
    return nil if !@area_locations || @area_locations.empty?
    entry = @area_locations[@area_loc_index]
    return entry ? entry[:map] : nil
  end
  
  # Turn a slots array into a stable comparable string.
  # Slots are arrays like: [chance, species, minlvl, maxlvl] or similar.
  def encounterSlotsSignature(slots)
    return "" if !slots
    # Convert all values to strings, keep order, join to one signature.
    return slots.map { |s| s.join(",") }.join("|")
  end
  
  # Build encounter variants for the selected map.
  # Each variant corresponds to a specific encounter type key (e.g. :LandDayRain).
  def refreshAreaEncounters
    @area_encounters = []
    @area_enc_index ||= 0
  
    map_id = currentAreaMap
    return if !map_id || !@species
  
    # First collect entries in PBS order
    raw = []  # [{method:, time:, weather:, slots_sig:}]
    GameData::Encounter.each_of_version($PokemonGlobal.encounter_version) do |enc_data|
      next if !enc_data || enc_data.map != map_id || !enc_data.types
  
      enc_data.types.each do |enc_type, slots|
        next if !slots
        next if !slots.any? { |slot| GameData::Species.get(slot[1]).species == @species }
  
        method, time, weather = splitEncounterType(enc_type)
        next if method == :unknown   # safety; should not happen now that split is fixed
  
        raw << {
          :method    => method,
          :time      => time,
          :weather   => weather,
          :slots_sig => encounterSlotsSignature(slots)
        }
      end
    end
  
    # Now collapse only when Day+Night exist AND are identical in every other way
    # (same method + same weather + same slot signature)
    used = Array.new(raw.length, false)
  
    raw.each_with_index do |e, i|
      next if used[i]
  
      # Always keep :any as-is (already unrestricted)
      if e[:time] == :any
        @area_encounters << { :method => e[:method], :time => :any, :weather => e[:weather] }
        used[i] = true
        next
      end
  
      # Try to find matching Day+Night partner
      if e[:time] == :day || e[:time] == :night
        partner_time = (e[:time] == :day) ? :night : :day
        partner_index = nil
  
        (i + 1).upto(raw.length - 1) do |k|
          next if used[k]
          p = raw[k]
          next if p[:time] != partner_time
          next if p[:method] != e[:method]
          next if p[:weather] != e[:weather]
          next if p[:slots_sig] != e[:slots_sig]
          partner_index = k
          break
        end
  
        if partner_index
          # Collapse to Any time
          @area_encounters << { :method => e[:method], :time => :any, :weather => e[:weather] }
          used[i] = true
          used[partner_index] = true
          next
        end
      end
  
      # Otherwise keep this exact entry
      @area_encounters << { :method => e[:method], :time => e[:time], :weather => e[:weather] }
      used[i] = true
    end
  
    # Clamp index
    if @area_encounters.empty?
      @area_enc_index = 0
    else
      @area_enc_index %= @area_encounters.length
    end
  end
  
  def currentEncounterVariant
    return nil if !@area_encounters || @area_encounters.empty?
    return @area_encounters[@area_enc_index]
  end
  
  WEATHER_SUFFIXES = [
    "None","Rain","Storm","Snow","Blizzard","Sandstorm","HeavyRain","Sun","Fog"
  ]
  
  TIME_SUFFIXES = ["Morning","Afternoon","Evening","Day","Night"]
  
  def splitEncounterType(enc_type)
    s = enc_type.to_s
  
    time    = :any
    weather = :any
  
    # IMPORTANT: strip WEATHER first (because in LandDayStorm the LAST suffix is Storm)
    WEATHER_SUFFIXES.each do |w|
      next if w.nil? || w.empty?
      if s.end_with?(w)
        weather = w.downcase.to_sym
        s = s[0...-w.length]
        break
      end
    end
  
    # Then strip TIME (now the end might be Day/Night/etc)
    TIME_SUFFIXES.each do |t|
      next if t.nil? || t.empty?
      if s.end_with?(t)
        time = t.downcase.to_sym
        s = s[0...-t.length]
        break
      end
    end
  
    # Base method
    method =
      case s
      when "Land"        then :land
      when "Cave"        then :cave
      when "Water"       then :water
      when "BugContest"  then :bug_contest
      when "OldRod"      then :old_rod
      when "GoodRod"     then :good_rod
      when "SuperRod"    then :super_rod
      when "RockSmash"   then :rock_smash
      when "SandCastle"  then :sand_castle
      when "HeadbuttLow", "HeadbuttHigh", "Headbutt" then :headbutt
      else
        :unknown
      end
  
    return method, time, weather
  end
  
  # Returns a Symbol method for one encounter type symbol, e.g. :land, :water, :old_rod, :headbutt, etc.
  def methodFromEncounterType(enc_type)
    s = enc_type.to_s
  
    # Strip time suffixes
    s = s.sub(/(Morning|Afternoon|Evening|Day|Night)\z/, "")
  
    # Strip weather suffixes (your token list)
    s = s.sub(/(None|Rain|Storm|Snow|Blizzard|Sandstorm|HeavyRain|Sun|Fog)\z/, "")
  
    # Now s should be a base like "Land", "Cave", "OldRod", "HeadbuttLow", etc.
    case s
    when "Land"      then :land
    when "Cave"      then :cave
    when "Water"     then :water
    when "BugContest" then :bug_contest
    when "OldRod"    then :old_rod
    when "GoodRod"   then :good_rod
    when "SuperRod"  then :super_rod
    when "RockSmash" then :rock_smash
    when "HeadbuttLow", "HeadbuttHigh", "Headbutt" then :headbutt
    else
      :unknown
    end
  end

  #-------------------------------------------------------------------------------
  # Convert encounter type symbols into a time-of-day result.
  # Weather plugins may append extra suffixes (e.g. LandDayRain), so we must
  # detect the time token anywhere in the name, not only at the end.
  #
  # Returns: :unknown, :any, :day, :night, :morning, :afternoon, :evening
  #-------------------------------------------------------------------------------
  def timeOfDayForTypes(types)
    return :unknown if !types || types.empty?
  
    # Order matters: "Morning"/"Afternoon"/"Evening" should be checked before "Day"/"Night"
    time_tokens = {
      "Morning"   => :morning,
      "Afternoon" => :afternoon,
      "Evening"   => :evening,
      "Day"       => :day,
      "Night"     => :night
    }
  
    found = []
  
    types.each do |t|
      s = t.to_s
      matched = nil
  
      time_tokens.each do |token, sym|
        if s.include?(token)
          matched = sym
          break
        end
      end
  
      # No explicit time token anywhere => treat as not time-restricted
      found << (matched || :any)
    end
  
    found.uniq!
  
    # If any type is "any time", simplest UX is to show :any overall
    return :any if found.include?(:any)
  
    # Exactly one time token overall
    return found[0] if found.length == 1
  
    # Multiple different time tokens across locations/types => you can choose what you want here.
    # For now, behave like your old code: fall back to :any.
    return :any
  end
  
  #-------------------------------------------------------------------------------
  # Determine weather from encounter types like LandDayRain.
  # Returns: :unknown, :any, :mixed, or a weather symbol (e.g. :rain).
  #-------------------------------------------------------------------------------
  def weatherForTypes(types)
    return :unknown if !types || types.empty?
  
    # Put the plugin's weather tokens here (CamelCase chunks)
    weather_tokens = [
      ["HeavyRain",  :heavyrain],
      ["Blizzard",   :blizzard],
      ["Sandstorm",  :sandstorm],
      ["Storm",      :storm],
      ["Rain",       :rain],
      ["Snow",       :snow],
      ["Sun",        :sun],
      ["Fog",        :fog],
      ["None",       :none]
    ]
  
    found = []
  
    types.each do |t|
      s = t.to_s
      matched = nil
      weather_tokens.each do |token, sym|
        if s.include?(token)
          matched = sym
          break
        end
      end
      found << (matched || :any)   # no weather token means "not weather-restricted"  
    end
  
    found.uniq!
    return :any if found.include?(:any)          # simplest UX: if any non-weather table exists, show :any
    return found[0] if found.length == 1
    return :mixed
  end
  
  #-------------------------------------------------------------------------------
  # 
  #-------------------------------------------------------------------------------
  def wrapTextToWidth(bitmap, text, max_width)
    words = text.split(" ")
    lines = []
    current = ""
    words.each do |word|
      test = (current.empty?) ? word : "#{current} #{word}"
      if bitmap.text_size(test).width <= max_width
        current = test
      else
        lines << current
        current = word
      end
    end
    lines << current unless current.empty?
    return lines
  end

  #-------------------------------------------------------------------------------
  # AREA PAGE selector (like forms). UP/DOWN cycles locations if multiple.
  #-------------------------------------------------------------------------------
  def pbChooseAreaLocation
    return if !@area_locations || @area_locations.length <= 1
    idx = @area_loc_index
    oldidx = -1
  
    pbPlayDecisionSE
    loop do
      if oldidx != idx
        @area_loc_index = idx
        refreshAreaEncounters
        drawPage(@page)
        oldidx = idx
      end
      Graphics.update
      Input.update
      pbUpdate
  
      if Keybinds.press?(:up)
        pbPlayCursorSE
        idx = (idx + @area_locations.length - 1) % @area_locations.length
      elsif Keybinds.press?(:down)
        pbPlayCursorSE
        idx = (idx + 1) % @area_locations.length
      elsif Keybinds.press?(:back)
        pbPlayCancelSE
        break
      elsif Keybinds.press?(:use)
        pbPlayDecisionSE
        break
      end
    end
  end
  
  def pbChooseAreaEncounter
    return if !@area_encounters || @area_encounters.length <= 1
  
    idx = @area_enc_index
    oldidx = -1
  
    pbPlayDecisionSE
    loop do
      if oldidx != idx
        @area_enc_index = idx
        drawPage(@page)
        oldidx = idx
      end
  
      Graphics.update
      Input.update
      pbUpdate
  
      if Keybinds.press?(:up)
        pbPlayCursorSE
        idx = (idx + @area_encounters.length - 1) % @area_encounters.length
      elsif Keybinds.press?(:down)
        pbPlayCursorSE
        idx = (idx + 1) % @area_encounters.length
      elsif Keybinds.press?(:back)
        pbPlayCancelSE
        break
      elsif Keybinds.press?(:use)
        pbPlayDecisionSE
        break
      end
    end
  end

  def drawPageArea
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_area"))
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    @sprites["areahighlight"].bitmap.clear
    # Get all points to be shown as places where @species can be encountered
    selected_map = currentAreaMap
    points = pbGetEncounterPoints(selected_map)
    # Draw coloured squares on each point of the Town Map with a nest
    pointcolor   = Color.new(0, 248, 248)
    pointcolorhl = Color.new(192, 248, 248)
    town_map_width = 1 + PokemonRegionMap_Scene::RIGHT - PokemonRegionMap_Scene::LEFT
    sqwidth = PokemonRegionMap_Scene::SQUARE_WIDTH
    sqheight = PokemonRegionMap_Scene::SQUARE_HEIGHT
    points.length.times do |j|
      next if !points[j]
      x = (j % town_map_width) * sqwidth
      x += @sprites["areamap"].x
      y = (j / town_map_width) * sqheight
      y += (Graphics.height + 32 - @sprites["areamap"].bitmap.height) / 2
      @sprites["areahighlight"].bitmap.fill_rect(x, y, sqwidth, sqheight, pointcolor)
      if j - town_map_width < 0 || !points[j - town_map_width]
        @sprites["areahighlight"].bitmap.fill_rect(x, y - 2, sqwidth, 2, pointcolorhl)
      end
      if j + town_map_width >= points.length || !points[j + town_map_width]
        @sprites["areahighlight"].bitmap.fill_rect(x, y + sqheight, sqwidth, 2, pointcolorhl)
      end
      if j % town_map_width == 0 || !points[j - 1]
        @sprites["areahighlight"].bitmap.fill_rect(x - 2, y, 2, sqheight, pointcolorhl)
      end
      if (j + 1) % town_map_width == 0 || !points[j + 1]
        @sprites["areahighlight"].bitmap.fill_rect(x + sqwidth, y, 2, sqheight, pointcolorhl)
      end
    end
  textpos = []
  
  tod = :unknown
  loc = nil
  if @area_locations && @area_locations.length > 0
    loc = @area_locations[@area_loc_index]
    variant = currentEncounterVariant
    tod     = variant ? variant[:time] : :unknown
    weather = variant ? variant[:weather] : :unknown
    method  = variant ? variant[:method] : :unknown
    
    @sprites["tod_icon"].visible     = true
    @sprites["weather_icon"].visible = true
    @sprites["method_icon"].visible  = true
    
    @sprites["tod_icon"].setBitmap("Graphics/UI/Pokedex/Detailed Area Page/time_#{tod}")
    @sprites["weather_icon"].setBitmap("Graphics/UI/Pokedex/Detailed Area Page/weather_#{weather}")
    @sprites["method_icon"].setBitmap("Graphics/UI/Pokedex/Detailed Area Page/method_#{method}")
    if @area_encounters && @area_encounters.length > 0
      textpos.push([_INTL("Encounter: {1}/{2}", @area_enc_index + 1, @area_encounters.length),
                    8, Graphics.height - 32, :left, base, shadow])
    end
    textpos.push([_INTL("Location:"), 8, 50, :left, base, shadow])
    lines = wrapTextToWidth(overlay, loc[:name].to_s, 124)

    y = 74
    lines.each do |line|
      # Draw shadow
      overlay.font.color = shadow
      overlay.draw_text(10, y, 124, 24, line, 0)
      overlay.draw_text(8, y + 2, 124, 24, line, 0)
      overlay.draw_text(10, y + 2, 124, 24, line, 0)

      # Draw main text
      overlay.font.color = base
      overlay.draw_text(8, y, 124, 24, line, 0)
      y += 24   # <-- you control this spacing
    end
  end
  
    if points.length == 0
      pbDrawImagePositions(
        overlay,
        [["Graphics/UI/Pokedex/overlay_areanone", 280, 188]]
      )
      textpos.push([_INTL("Area unknown"), 428, (Graphics.height / 2) + 6, :center, base, shadow])
    end
    textpos.push([@mapdata.name, 528, 50, :left, base, shadow])
    textpos.push([_INTL("{1}'s area", GameData::Species.get(@species).name),
                  Graphics.width / 2, 358, :center, base, shadow])
    pbDrawTextPositions(overlay, textpos)
  end

  def drawPageForms
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_forms"))
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    # Write species and form name
    formname = ""
    @available.each do |i|
      if i[1] == @gender && i[2] == @form
        formname = i[0]
        break
      end
    end
    textpos = [
      [GameData::Species.get(@species).name, Graphics.width / 2, Graphics.height - 82, :center, base, shadow],
      [formname, Graphics.width / 2, Graphics.height - 50, :center, base, shadow]
    ]
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

  def pbGoToPrevious
    newindex = @index
    while newindex > 0
      newindex -= 1
      if $player.seen?(@dexlist[newindex][:species])
        @index = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @index
    while newindex < @dexlist.length - 1
      newindex += 1
      if $player.seen?(@dexlist[newindex][:species])
        @index = newindex
        break
      end
    end
  end

  def pbChooseForm
    index = 0
    @available.length.times do |i|
      if @available[i][1] == @gender && @available[i][2] == @form
        index = i
        break
      end
    end
    oldindex = -1
    loop do
      if oldindex != index
        $player.pokedex.set_last_form_seen(@species, @available[index][1], @available[index][2])
        pbUpdateDummyPokemon
        drawPage(@page)
        @sprites["uparrow"].visible   = (index > 0)
        @sprites["downarrow"].visible = (index < @available.length - 1)
        oldindex = index
      end
      Graphics.update
      Input.update
      pbUpdate
      if Keybinds.press?(:up)
        pbPlayCursorSE
        index = (index + @available.length - 1) % @available.length
      elsif Keybinds.press?(:down)
        pbPlayCursorSE
        index = (index + 1) % @available.length
      elsif Keybinds.press?(:back)
        pbPlayCancelSE
        break
      elsif Keybinds.press?(:use)
        pbPlayDecisionSE
        break
      end
    end
    @sprites["uparrow"].visible   = false
    @sprites["downarrow"].visible = false
  end

  def pbScene
    Pokemon.play_cry(@species, @form)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Keybinds.press?(:action)
        pbSEStop
        Pokemon.play_cry(@species, @form) if @page == 1
      elsif Keybinds.press?(:back)
        pbPlayCloseMenuSE
        break
      elsif Keybinds.press?(:use)
        pbSEPlay("GUI sel decision", 100, 100) rescue nil
        p [:USE, @page, defined?(@page_id) ? @page_id : nil]
        case @page
        when 1   # Info
          pbPlayDecisionSE
          @show_battled_count = !@show_battled_count
          dorefresh = true
        when 2   # Area
          if @area_locations && @area_locations.length > 1
            pbChooseAreaLocation
            dorefresh = true
          end
        when 3   # Forms
          if @available.length > 1
            pbPlayDecisionSE
            pbChooseForm
            dorefresh = true
          end
        end
      elsif Keybinds.press?(:up)
        oldindex = @index
        pbGoToPrevious
        if @index != oldindex
          pbUpdateDummyPokemon
          @available = pbGetAvailableForms
          pbSEStop
          (@page == 1) ? Pokemon.play_cry(@species, @form) : pbPlayCursorSE
          dorefresh = true
        end
      elsif Keybinds.press?(:down)
        oldindex = @index
        pbGoToNext
        if @index != oldindex
          pbUpdateDummyPokemon
          @available = pbGetAvailableForms
          pbSEStop
          (@page == 1) ? Pokemon.play_cry(@species, @form) : pbPlayCursorSE
          dorefresh = true
        end
      elsif Keybinds.press?(:left)
        oldpage = @page
        @page -= 1
        @page = 1 if @page < 1
        @page = 3 if @page > 3
        if @page != oldpage
          pbPlayCursorSE
          dorefresh = true
        end
      elsif Keybinds.press?(:right)
        oldpage = @page
        @page += 1
        @page = 1 if @page < 1
        @page = 3 if @page > 3
        if @page != oldpage
          pbPlayCursorSE
          dorefresh = true
        end
      end
      drawPage(@page) if dorefresh
    end
    return @index
  end

  def pbSceneBrief
    Pokemon.play_cry(@species, @form)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Keybinds.press?(:action)
        pbSEStop
        Pokemon.play_cry(@species, @form)
      elsif Keybinds.press?(:back) || Keybinds.press?(:use)
        pbPlayCloseMenuSE
        break
      end
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokedexInfoScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(dexlist, index, region)
    @scene.pbStartScene(dexlist, index, region)
    ret = @scene.pbScene
    @scene.pbEndScene
    return ret   # Index of last species viewed in dexlist
  end

  # For use from a Pokémon's summary screen.
  def pbStartSceneSingle(species)
    region = -1
    if Settings::USE_CURRENT_REGION_DEX
      region = pbGetCurrentRegion
      region = -1 if region >= $player.pokedex.dexes_count - 1
    else
      region = $PokemonGlobal.pokedexDex   # National Dex -1, regional Dexes 0, 1, etc.
    end
    dexnum = pbGetRegionalNumber(region, species)
    dexnumshift = Settings::DEXES_WITH_OFFSETS.include?(region)
    dexlist = [{
      :species => species,
      :name    => GameData::Species.get(species).name,
      :height  => 0,
      :weight  => 0,
      :number  => dexnum,
      :shift   => dexnumshift
    }]
    @scene.pbStartScene(dexlist, 0, region)
    @scene.pbScene
    @scene.pbEndScene
  end

  # For use when capturing or otherwise obtaining a new species.
  def pbDexEntry(species)
    @scene.pbStartSceneBrief(species)
    @scene.pbSceneBrief
    @scene.pbEndScene
  end
end