<<<<<<< Updated upstream
#===============================================================================
#
#===============================================================================
def pbPCItemStorage
  command = 0
  loop do
    command = pbShowCommandsWithHelp(nil,
                                     [_INTL("Withdraw Item"),
                                      _INTL("Deposit Item"),
                                      _INTL("Toss Item"),
                                      _INTL("Exit")],
                                     [_INTL("Take out items from the PC."),
                                      _INTL("Store items in the PC."),
                                      _INTL("Throw away items stored in the PC."),
                                      _INTL("Go back to the previous menu.")], -1, command)
    case command
    when 0   # Withdraw Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        pbMessage(_INTL("There are no items."))
      else
        pbFadeOutIn do
          scene = WithdrawItemScene.new
          screen = PokemonBagScreen.new(scene, $bag)
          screen.pbWithdrawItemScreen
        end
      end
    when 1   # Deposit Item
      pbFadeOutIn do
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene, $bag)
        screen.pbDepositItemScreen
      end
    when 2   # Toss Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        pbMessage(_INTL("There are no items."))
      else
        pbFadeOutIn do
          scene = TossItemScene.new
          screen = PokemonBagScreen.new(scene, $bag)
          screen.pbTossItemScreen
        end
      end
    else
      break
=======
# NOTE: If adding a new target, you will need to add code in several places to
#       make them work properly:
#         - def pbFindTargets
#         - def pbMoveCanTarget?
#         - def pbCreateTargetTexts
#         - def pbFirstTarget
#         - def pbTargetsMultiple?
module GameData
  class Target
    attr_reader :id
    attr_reader :real_name
    attr_reader :num_targets        # 0, 1 or 2 (meaning 2+)
    attr_reader :targets_foe        # Is able to target one or more foes
    attr_reader :targets_all        # Crafty Shield can't protect from these moves
    attr_reader :affects_foe_side   # Pressure also affects these moves
    attr_reader :long_range         # Hits non-adjacent targets

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id               = hash[:id]
      @real_name        = hash[:name]             || "Unnamed"
      @num_targets      = hash[:num_targets]      || 0
      @targets_foe      = hash[:targets_foe]      || false
      @targets_all      = hash[:targets_all]      || false
      @affects_foe_side = hash[:affects_foe_side] || false
      @long_range       = hash[:long_range]       || false
    end

    # @return [String] the translated name of this target
    def name
      return _INTL(@real_name)
    end

    def can_choose_distant_target?
      return @num_targets == 1 && @long_range
    end

    def can_target_one_foe?
      return @num_targets == 1 && @targets_foe
>>>>>>> Stashed changes
    end
  end
end

#===============================================================================
<<<<<<< Updated upstream
#
#===============================================================================
def pbPCMailbox
  if !$PokemonGlobal.mailbox || $PokemonGlobal.mailbox.length == 0
    pbMessage(_INTL("There's no Mail here."))
  else
    loop do
      command = 0
      commands = []
      $PokemonGlobal.mailbox.each do |mail|
        commands.push(mail.sender)
      end
      commands.push(_INTL("Cancel"))
      command = pbShowCommands(nil, commands, -1, command)
      if command >= 0 && command < $PokemonGlobal.mailbox.length
        mailIndex = command
        commandMail = pbMessage(
          _INTL("What do you want to do with {1}'s Mail?", $PokemonGlobal.mailbox[mailIndex].sender),
          [_INTL("Read"),
           _INTL("Move to Bag"),
           _INTL("Give"),
           _INTL("Cancel")], -1
        )
        case commandMail
        when 0   # Read
          pbFadeOutIn do
            pbDisplayMail($PokemonGlobal.mailbox[mailIndex])
          end
        when 1   # Move to Bag
          if pbConfirmMessage(_INTL("The message will be lost. Is that OK?"))
            if $bag.add($PokemonGlobal.mailbox[mailIndex].item)
              pbMessage(_INTL("The Mail was returned to the Bag with its message erased."))
              $PokemonGlobal.mailbox.delete_at(mailIndex)
            else
              pbMessage(_INTL("The Bag is full."))
            end
          end
        when 2   # Give
          pbFadeOutIn do
            sscene = PokemonParty_Scene.new
            sscreen = PokemonPartyScreen.new(sscene, $player.party)
            sscreen.pbPokemonGiveMailScreen(mailIndex)
          end
        end
      else
        break
      end
    end
  end
end

#===============================================================================
#
#===============================================================================
def pbTrainerPC
  pbMessage("\\se[PC open]" + _INTL("{1} booted up the PC.", $player.name))
  pbTrainerPCMenu
  pbSEPlay("PC close")
end

def pbTrainerPCMenu
  command = 0
  loop do
    command = pbMessage(_INTL("What do you want to do?"),
                        [_INTL("Item Storage"),
                         _INTL("Mailbox"),
                         _INTL("Turn Off")], -1, nil, command)
    case command
    when 0 then pbPCItemStorage
    when 1 then pbPCMailbox
    else        break
    end
  end
end

#===============================================================================
#
#===============================================================================
def pbPokeCenterPC
  pbMessage("\\se[PC open]" + _INTL("{1} booted up the PC.", $player.name))
  # Get all commands
  command_list = []
  commands = []
  MenuHandlers.each_available(:pc_menu) do |option, hash, name|
    command_list.push(name)
    commands.push(hash)
  end
  # Main loop
  command = 0
  loop do
    choice = pbMessage(_INTL("Which PC should be accessed?"), command_list, -1, nil, command)
    if choice < 0
      pbPlayCloseMenuSE
      break
    end
    break if commands[choice]["effect"].call
  end
  pbSEPlay("PC close")
end

def pbGetStorageCreator
  return GameData::Metadata.get.storage_creator
end

#===============================================================================
#
#===============================================================================
MenuHandlers.add(:pc_menu, :pokemon_storage, {
  "name"      => proc {
    next ($player.seen_storage_creator) ? _INTL("{1}'s PC", pbGetStorageCreator) : _INTL("Someone's PC")
  },
  "order"     => 10,
  "effect"    => proc { |menu|
    pbMessage("\\se[PC access]" + _INTL("The Pokémon Storage System was opened."))
    command = 0
    loop do
      command = pbShowCommandsWithHelp(nil,
                                       [_INTL("Organize Boxes"),
                                        _INTL("Withdraw Pokémon"),
                                        _INTL("Deposit Pokémon"),
                                        _INTL("See ya!")],
                                       [_INTL("Organize the Pokémon in Boxes and in your party."),
                                        _INTL("Move Pokémon stored in Boxes to your party."),
                                        _INTL("Store Pokémon in your party in Boxes."),
                                        _INTL("Return to the previous menu.")], -1, command)
      break if command < 0
      case command
      when 0   # Organize
        pbFadeOutIn do
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene, $PokemonStorage)
          screen.pbStartScreen(0)
        end
      when 1   # Withdraw
        if $PokemonStorage.party_full?
          pbMessage(_INTL("Your party is full!"))
          next
        end
        pbFadeOutIn do
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene, $PokemonStorage)
          screen.pbStartScreen(1)
        end
      when 2   # Deposit
        count = 0
        $PokemonStorage.party.each do |p|
          count += 1 if p && !p.egg? && p.hp > 0
        end
        if count <= 1
          pbMessage(_INTL("Can't deposit the last Pokémon!"))
          next
        end
        pbFadeOutIn do
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene, $PokemonStorage)
          screen.pbStartScreen(2)
        end
      else
        break
      end
    end
    next false
  }
})

MenuHandlers.add(:pc_menu, :player_pc, {
  "name"      => proc { next _INTL("{1}'s PC", $player.name) },
  "order"     => 20,
  "effect"    => proc { |menu|
    pbMessage("\\se[PC access]" + _INTL("Accessed {1}'s PC.", $player.name))
    pbTrainerPCMenu
    next false
  }
})

MenuHandlers.add(:pc_menu, :close, {
  "name"      => _INTL("Log off"),
  "order"     => 100,
  "effect"    => proc { |menu|
    next true
  }
=======

# Bide, Counter, Metal Burst, Mirror Coat (calculate a target)
GameData::Target.register({
  :id               => :None,
  :name             => _INTL("None")
})

GameData::Target.register({
  :id               => :User,
  :name             => _INTL("User")
})

# Aromatic Mist, Helping Hand, Hold Hands
GameData::Target.register({
  :id               => :NearAlly,
  :name             => _INTL("Near Ally"),
  :num_targets      => 1
})

# Acupressure
GameData::Target.register({
  :id               => :UserOrNearAlly,
  :name             => _INTL("User or Near Ally"),
  :num_targets      => 1
})

# Coaching
GameData::Target.register({
  :id               => :AllAllies,
  :name             => _INTL("All Allies"),
  :num_targets      => 2,
  :targets_all      => true,
  :long_range       => true
})

# Aromatherapy, Gear Up, Heal Bell, Life Dew, Magnetic Flux, Howl (in Gen 8+)
GameData::Target.register({
  :id               => :UserAndAllies,
  :name             => _INTL("User and Allies"),
  :num_targets      => 2,
  :long_range       => true
})

# Me First
GameData::Target.register({
  :id               => :NearFoe,
  :name             => _INTL("Near Foe"),
  :num_targets      => 1,
  :targets_foe      => true
})

# Petal Dance, Outrage, Struggle, Thrash, Uproar
GameData::Target.register({
  :id               => :RandomNearFoe,
  :name             => _INTL("Random Near Foe"),
  :num_targets      => 1,
  :targets_foe      => true
})

GameData::Target.register({
  :id               => :AllNearFoes,
  :name             => _INTL("All Near Foes"),
  :num_targets      => 2,
  :targets_foe      => true
})

# For throwing a Poké Ball
GameData::Target.register({
  :id               => :Foe,
  :name             => _INTL("Foe"),
  :num_targets      => 1,
  :targets_foe      => true,
  :long_range       => true
})

# Unused
GameData::Target.register({
  :id               => :AllFoes,
  :name             => _INTL("All Foes"),
  :num_targets      => 2,
  :targets_foe      => true,
  :long_range       => true
})

GameData::Target.register({
  :id               => :NearOther,
  :name             => _INTL("Near Other"),
  :num_targets      => 1,
  :targets_foe      => true
})

GameData::Target.register({
  :id               => :AllNearOthers,
  :name             => _INTL("All Near Others"),
  :num_targets      => 2,
  :targets_foe      => true
})

# Most Flying-type moves, pulse moves (hits non-near targets)
GameData::Target.register({
  :id               => :Other,
  :name             => _INTL("Other"),
  :num_targets      => 1,
  :targets_foe      => true,
  :long_range       => true
})

# Flower Shield, Perish Song, Rototiller, Teatime
GameData::Target.register({
  :id               => :AllBattlers,
  :name             => _INTL("All Battlers"),
  :num_targets      => 2,
  :targets_foe      => true,
  :targets_all      => true,
  :long_range       => true
})

GameData::Target.register({
  :id               => :UserSide,
  :name             => _INTL("User Side")
})

# Entry hazards
GameData::Target.register({
  :id               => :FoeSide,
  :name             => _INTL("Foe Side"),
  :affects_foe_side => true
})

GameData::Target.register({
  :id               => :BothSides,
  :name             => _INTL("Both Sides"),
  :affects_foe_side => true
>>>>>>> Stashed changes
})
