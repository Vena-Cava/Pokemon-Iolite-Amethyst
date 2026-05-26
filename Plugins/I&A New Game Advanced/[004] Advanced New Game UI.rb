#===============================================================================
# Advanced New Game UI
#===============================================================================

class AdvancedNewGame_Scene
  attr_reader :result

  def pbStartScene
    @result = nil
    @data = AdvancedNewGame::DEFAULT_MODES.clone
    @data[:nuzlocke_options] = AdvancedNewGame::DEFAULT_MODES[:nuzlocke_options].clone

    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    addBackgroundOrColoredPlane(@sprites, "bg", "optionsbg", Color.new(192, 200, 208), @viewport)

    @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
      _INTL("Advanced New Game"), 0, -16, Graphics.width, 64, @viewport
    )
    @sprites["title"].back_opacity = 0

    @sprites["textbox"] = pbCreateMessageWindow
    pbSetSystemFont(@sprites["textbox"].contents)

    build_options

    @sprites["option"] = Window_PokemonOption.new(
      @options,
      0,
      @sprites["title"].y + @sprites["title"].height - 16,
      Graphics.width,
      Graphics.height - (@sprites["title"].y + @sprites["title"].height - 16) - @sprites["textbox"].height
    )

    @sprites["option"].viewport = @viewport
    @sprites["option"].visible = true

    @options.length.times do |i|
      @sprites["option"].setValueNoRefresh(i, @options[i].get || 0)
    end

    @sprites["option"].refresh
    pbChangeSelection
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def build_options
    @options = []
    @descriptions = []

    unlocked = AdvancedNewGame.unlocked_difficulties
    difficulty_names = unlocked.map { |d| AdvancedNewGame::DIFFICULTIES[d][:name] }

    @options.push(EnumOption.new(
      _INTL("Difficulty"),
      difficulty_names,
      proc { next unlocked.index(@data[:difficulty]) || 0 },
      proc { |value, _scene| @data[:difficulty] = unlocked[value] }
    ))
    @descriptions.push(proc {
      diff = @data[:difficulty]
      next AdvancedNewGame::DIFFICULTIES[diff][:desc]
    })

    add_bool_option(:nuzlocke, "Nuzlocke", AdvancedNewGame::MODES[:nuzlocke][:desc])

    if @data[:nuzlocke]
      @options.push(ButtonOption.new(
        _INTL("Nuzlocke Options"),
        _INTL("Change special Nuzlocke rules."),
        proc { open_nuzlocke_options }
      ))
      @descriptions.push(_INTL("Open extra Nuzlocke rules, such as Dupes Clause and Shiny Clause."))
    end

    add_bool_option(:inverse, "Inverse", AdvancedNewGame::MODES[:inverse][:desc])
    add_bool_option(:level_caps, "Level Caps", AdvancedNewGame::MODES[:level_caps][:desc])
    add_bool_option(:no_bag_items_battle,"No Battle Items",AdvancedNewGame::MODES[:no_bag_items_battle][:desc])

    @options.push(ButtonOption.new(
      _INTL("Start Game"),
      _INTL("Start the game with these settings."),
      proc { @result = @data }
    ))
    @descriptions.push(_INTL("Start the game with these Advanced New Game settings."))
  end

  def rebuild_option_window
    old_index = @sprites["option"].index

    @sprites["option"].dispose if @sprites["option"]

    build_options

    @sprites["option"] = Window_PokemonOption.new(
      @options,
      0,
      @sprites["title"].y + @sprites["title"].height - 16,
      Graphics.width,
      Graphics.height - (@sprites["title"].y + @sprites["title"].height - 16) - @sprites["textbox"].height
    )

    @sprites["option"].viewport = @viewport
    @sprites["option"].visible = true
    @sprites["option"].active = true

    @options.length.times do |i|
      @sprites["option"].setValueNoRefresh(i, @options[i].get || 0)
    end

    @sprites["option"].index = [old_index, @options.length - 1].min
    @sprites["option"].refresh
    pbChangeSelection
  end

  def add_bool_option(key, name, description)
    @options.push(EnumOption.new(
      _INTL(name),
      [_INTL("Off"), _INTL("On")],
      proc { next @data[key] ? 1 : 0 },
      proc { |value, _scene| @data[key] = value == 1 }
    ))
    @descriptions.push(description)
  end

  def open_nuzlocke_options
    pbFadeOutIn do
      pbNuzlockeOptionsMenu(@data)
    end
    rebuild_option_window
  end

  def pbChangeSelection
    index = @sprites["option"].index
    desc = @descriptions[index]

    desc = desc.call if desc.is_a?(Proc)

    @sprites["textbox"].letterbyletter = false
    @sprites["textbox"].text = desc || ""
  end

  def pbOptions
    pbActivateWindow(@sprites, "option") do
      old_index = -1

      loop do
        Graphics.update
        Input.update
        pbUpdate

        if @sprites["option"].index != old_index
          pbChangeSelection
          old_index = @sprites["option"].index
        end

        if @sprites["option"].value_changed
          i = @sprites["option"].index
          @options[i].set(@sprites["option"][i], self)

          # Rebuild menu when Nuzlocke is toggled,
          # because Nuzlocke Options should appear/disappear.
          if @options[i].name == "Nuzlocke" || @options[i].name == _INTL("Nuzlocke")
            rebuild_option_window
          else
            pbChangeSelection
          end
        end

        if Keybinds.press?(:back)
          @result = nil
          break
        elsif Keybinds.trigger?(:use)
          # Close option
          break if @sprites["option"].index == @options.length

          i = @sprites["option"].index
          option = @options[i]

          if option.is_a?(ButtonOption)
            option.activate
            break if @result
          end
        end
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeMessageWindow(@sprites["textbox"])
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end
end

class AdvancedNewGameScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbOptions
    result = @scene.result
    @scene.pbEndScene
    return result
  end
end

#===============================================================================
# Nuzlocke Options UI
#===============================================================================

class NuzlockeOptions_Scene
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    addBackgroundOrColoredPlane(@sprites, "bg", "optionsbg", Color.new(192, 200, 208), @viewport)

    @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
      _INTL("Nuzlocke Options"), 0, -16, Graphics.width, 64, @viewport
    )
    @sprites["title"].back_opacity = 0

    @sprites["textbox"] = pbCreateMessageWindow
    pbSetSystemFont(@sprites["textbox"].contents)

    build_options

    @sprites["option"] = Window_PokemonOption.new(
      @options,
      0,
      @sprites["title"].y + @sprites["title"].height - 16,
      Graphics.width,
      Graphics.height - (@sprites["title"].y + @sprites["title"].height - 16) - @sprites["textbox"].height
    )

    @sprites["option"].viewport = @viewport
    @sprites["option"].visible = true

    @options.length.times do |i|
      @sprites["option"].setValueNoRefresh(i, @options[i].get || 0)
    end

    @sprites["option"].refresh
    pbChangeSelection
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def build_options
    @options = []
    @descriptions = []

    rules = AdvancedNewGame::NUZLOCKE_FAINT_RULES.keys
    rule_names = rules.map { |r| AdvancedNewGame::NUZLOCKE_FAINT_RULES[r][:name] }

    @options.push(EnumOption.new(
      _INTL("Faint Rule"),
      rule_names,
      proc { next rules.index(@data[:nuzlocke_options][:faint_rule]) || 0 },
      proc { |value, _scene| @data[:nuzlocke_options][:faint_rule] = rules[value] }
    ))
    @descriptions.push(proc {
      rule = @data[:nuzlocke_options][:faint_rule]
      next AdvancedNewGame::NUZLOCKE_FAINT_RULES[rule][:desc]
    })
    limits = AdvancedNewGame::POKECENTER_LIMITS.keys
    limit_names = limits.map { |l| AdvancedNewGame::POKECENTER_LIMITS[l][:name] }

    @options.push(EnumOption.new(
      _INTL("PokéCentre Limit"),
      limit_names,
      proc { next limits.index(@data[:nuzlocke_options][:pokecenter_limit]) || 0 },
      proc { |value, _scene| @data[:nuzlocke_options][:pokecenter_limit] = limits[value] }
    ))
    @descriptions.push(AdvancedNewGame::NUZLOCKE_OPTIONS[:pokecenter_limit][:desc])

    add_bool_option(:dupes_clause)
    add_bool_option(:shiny_clause)
    add_bool_option(:nickname_clause)
    add_bool_option(:wipe_deletes_save)
  end

  def add_bool_option(key)
    info = AdvancedNewGame::NUZLOCKE_OPTIONS[key]

    @options.push(EnumOption.new(
      _INTL(info[:name]),
      [_INTL("Off"), _INTL("On")],
      proc { next @data[:nuzlocke_options][key] ? 1 : 0 },
      proc { |value, _scene| @data[:nuzlocke_options][key] = value == 1 }
    ))

    @descriptions.push(info[:desc])
  end

  def pbChangeSelection
    index = @sprites["option"].index
    desc = @descriptions[index]
    desc = desc.call if desc.is_a?(Proc)

    @sprites["textbox"].letterbyletter = false
    @sprites["textbox"].text = desc || ""
  end

  def pbOptions
    pbActivateWindow(@sprites, "option") do
      old_index = -1

      loop do
        Graphics.update
        Input.update
        pbUpdate

        if @sprites["option"].index != old_index
          pbChangeSelection
          old_index = @sprites["option"].index
        end

        if @sprites["option"].value_changed
          i = @sprites["option"].index
          @options[i].set(@sprites["option"][i], self)
          pbChangeSelection
        end

        if Keybinds.press?(:back)
          break
        elsif Keybinds.trigger?(:use)
          # Close option
          break if @sprites["option"].index == @options.length

          i = @sprites["option"].index
          option = @options[i]

          if option.is_a?(ButtonOption)
            option.activate
            pbChangeSelection
          end
        end
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeMessageWindow(@sprites["textbox"])
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end
end

class NuzlockeOptionsScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbOptions
    @scene.pbEndScene
  end
end

def pbNuzlockeOptionsMenu(data)
  scene = NuzlockeOptions_Scene.new(data)
  screen = NuzlockeOptionsScreen.new(scene)
  screen.pbStartScreen
end

#===============================================================================
# Called from AdvancedNewGame.start_advanced_game
#===============================================================================

def pbAdvancedNewGameMenu
  scene = AdvancedNewGame_Scene.new
  screen = AdvancedNewGameScreen.new(scene)
  return screen.pbStartScreen
end