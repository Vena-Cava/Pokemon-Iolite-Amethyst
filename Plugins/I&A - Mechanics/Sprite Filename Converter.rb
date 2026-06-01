module AdvancedNewGame
  def self.convert_old_pokemon_sprite_names(preview = true)
    root = "Graphics/Pokemon"
    return pbMessage(_INTL("Graphics/Pokemon folder was not found.")) if !Dir.safe?(root)

    dex_to_species = {}
    dex_num = 0

    GameData::Species.each_species do |species|
      dex_num += 1
      dex_to_species[dex_num] = species.id
    end

    renamed = 0
    skipped = 0
    failed  = 0

    Dir.glob("#{root}/**/*").each do |path|
      next if File.directory?(path)

      folder = File.dirname(path)
      ext    = File.extname(path)
      name   = File.basename(path, ext)

      next if name == "000"
      next if name =~ /[A-Za-z]/   # Already new format

      if name =~ /^0*(\d+)(?:_(\d+))?$/
        dex_num = $1.to_i
        form    = $2

        species_id = dex_to_species[dex_num]

        if !species_id
          skipped += 1
          next
        end

        new_name = species_id.to_s
        new_name += "_#{form}" if form

        new_path = "#{folder}/#{new_name}#{ext}"

        if File.file?(new_path)
          skipped += 1
          next
        end

        if preview
          echoln "#{path} -> #{new_path}"
        else
          File.rename(path, new_path)
        end

        renamed += 1
      else
        skipped += 1
      end
    rescue
      failed += 1
    end

    if preview
      pbMessage(_INTL("Preview complete. Check the console. {1} file(s) would be renamed.", renamed))
    else
      pbMessage(_INTL("Done. Renamed {1} file(s). Skipped {2}. Failed {3}.", renamed, skipped, failed))
    end
  end
end

MenuHandlers.add(:debug_menu, :advanced_new_game_convert_sprite_names, {
  "name"        => _INTL("Convert Old Pokémon Sprite Names"),
  "parent"      => :main,
  "description" => _INTL("Renames old numbered Pokémon sprites to species ID filenames."),
  "effect"      => proc {
    commands = [
      _INTL("Preview Only"),
      _INTL("Rename Files"),
      _INTL("Cancel")
    ]

    choice = pbMessage(_INTL("Convert old sprite filenames?"), commands, 2)

    case choice
    when 0
      AdvancedNewGame.convert_old_pokemon_sprite_names(true)
    when 1
      next false if !pbConfirmMessage(_INTL("This will rename files inside Graphics/Pokemon. Continue?"))
      AdvancedNewGame.convert_old_pokemon_sprite_names(false)
    end

    next false
  }
})