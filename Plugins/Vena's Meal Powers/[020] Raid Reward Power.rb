#===============================================================================
# Meal Powers - Raid Reward Power
# Adds additional reward rolls after successfully completing a Raid Battle.
#
# Lv. 1 = +1 reward roll
# Lv. 2 = +2 reward rolls
# Lv. 3 = +3 reward rolls
#
# Each roll produces one complete reward entry. For example:
#   Exp. Candy M x6
#   Bottle Cap x1
#   Pomeg Berry x2
#
# Reward categories are weighted according to how frequently that category
# normally appears in the raid reward generation.
#===============================================================================

module MealPowers
  RAID_REWARD_EXTRA_ROLLS = {
    0 => 0,
    1 => 1,
    2 => 2,
    3 => 3
  }

  #-----------------------------------------------------------------------------
  # Returns the number of additional raid reward rolls.
  #-----------------------------------------------------------------------------
  def self.raid_reward_extra_rolls
    return RAID_REWARD_EXTRA_ROLLS[level(:RAIDREWARD)] || 0
  end

  #-----------------------------------------------------------------------------
  # Adds a weighted reward generator to the bonus reward pool.
  #
  # Weight scale:
  #   600 = 100%
  #   480 = 80%
  #   360 = 60%
  #   300 = 50%
  #   240 = 40%
  #   180 = 30%
  #   120 = 20%
  #    60 = 10%
  #
  # These weights preserve the relative frequency of the corresponding
  # categories in the normal raid reward generator.
  #-----------------------------------------------------------------------------
  def self.add_raid_reward_candidate(pool, weight, &block)
    return if weight <= 0
    pool.push([weight, block])
  end

  #-----------------------------------------------------------------------------
  # Selects one weighted candidate and resolves its reward.
  #-----------------------------------------------------------------------------
  def self.choose_raid_reward_candidate(pool)
    return nil if pool.empty?

    total_weight = 0
    pool.each { |entry| total_weight += entry[0] }

    roll = rand(total_weight)

    pool.each do |entry|
      weight    = entry[0]
      generator = entry[1]

      if roll < weight
        return generator.call
      end

      roll -= weight
    end

    return nil
  end

  #-----------------------------------------------------------------------------
  # Generates one additional raid reward roll.
  #-----------------------------------------------------------------------------
  def self.generate_raid_reward_roll(
    pokemon,
    style,
    rank,
    weather = nil,
    terrain = nil,
    environ = nil
  )
    pool = []

    qty = (rank * 1.1).round

    #===========================================================================
    # Exp. Candy
    #===========================================================================

    # Exp. Candy XL
    if rank >= 6
      add_raid_reward_candidate(pool, 600) do
        candy_qty = (qty / 2).round
        [:EXPCANDYXL, candy_qty + rand(3)]
      end
    elsif rank == 5
      add_raid_reward_candidate(pool, 180) do
        candy_qty = (qty / 2).round
        [:EXPCANDYXL, candy_qty + rand(3)]
      end
    end

    # Exp. Candy L
    if rank >= 5
      add_raid_reward_candidate(pool, 600) do
        candy_qty = qty
        [:EXPCANDYL, candy_qty + rand(3)]
      end
    elsif rank == 4
      add_raid_reward_candidate(pool, 180) do
        candy_qty = qty
        [:EXPCANDYL, candy_qty + rand(3)]
      end
    end

    # Exp. Candy M
    if rank >= 3
      add_raid_reward_candidate(pool, 600) do
        candy_qty = qty * 2
        [:EXPCANDYM, candy_qty + rand(3)]
      end
    end

    # Exp. Candy S
    if rank > 5
      add_raid_reward_candidate(pool, 480) do
        candy_qty = qty * 3
        [:EXPCANDYS, candy_qty + rand(3)]
      end
    else
      add_raid_reward_candidate(pool, 600) do
        candy_qty = qty * 3
        [:EXPCANDYS, candy_qty + rand(3)]
      end
    end

    # Exp. Candy XS
    if rank < 5
      add_raid_reward_candidate(pool, 600) do
        candy_qty = qty * 4
        [:EXPCANDYXS, candy_qty + rand(3)]
      end
    elsif rank == 5
      add_raid_reward_candidate(pool, 360) do
        candy_qty = qty * 4
        [:EXPCANDYXS, candy_qty + rand(3)]
      end
    end

    # Rare Candy
    if rank > 2
      add_raid_reward_candidate(pool, 600) do
        [:RARECANDY, qty + rand(-1..2)]
      end
    end

    #===========================================================================
    # Raid-style rewards
    #===========================================================================

    case style
    when :Max
      # Dynamax Candy
      if rank > 2
        add_raid_reward_candidate(pool, 600) do
          [:DYNAMAXCANDY, qty + rand(-1..2)]
        end
      end

      # Max Soup
      if pokemon.gmax_factor?
        add_raid_reward_candidate(pool, 300) do
          [:MAXSOUP, 1]
        end
      end

      # Repeatable species-specific Max Raid rewards.
      case pokemon.species
      when :VESPIQUEN
        add_raid_reward_candidate(pool, 600) do
          [:MAXHONEY, 1]
        end
      when :PARASECT, :BRELOOM, :AMOONGUS, :SHIINOTIC, :TOEDSCRUEL
        add_raid_reward_candidate(pool, 600) do
          [:MAXMUSHROOMS, 1]
        end
      end

    when :Tera
      # Tera Shards
      shard = GameData::Item.get_shard_from_type(pokemon.tera_type)

      if shard
        add_raid_reward_candidate(pool, 600) do
          shard_qty = qty + rand(-1..2)

          if $bag.has?(:GLIMMERINGCHARM)
            case rank
            when 3 then shard_qty += 2
            when 4 then shard_qty += 5
            when 5 then shard_qty += 10
            when 6 then shard_qty += 12
            when 7 then shard_qty += 20
            end
          end

          [shard, shard_qty]
        end
      end

      # Mystery Tera Jewel
      add_raid_reward_candidate(pool, 120) do
        [:MYSTERYTERAJEWEL, 1]
      end
    end

    #===========================================================================
    # TM/TR reward
    #===========================================================================

    if rank > 2
      types = (style == :Tera) ? [pokemon.tera_type] : pokemon.types
      machine = GameData::Item.get_TR_from_type(types)

      if machine
        add_raid_reward_candidate(pool, 600) do
          [machine, 1]
        end
      end
    end

    #===========================================================================
    # General rewards
    #===========================================================================

    # Berries
    add_raid_reward_candidate(pool, 600) do
      item_qty = [1, (qty / 2 + rand(-1..2)).round].max

      berries = [
        :POMEGBERRY,
        :KELPSYBERRY,
        :QUALOTBERRY,
        :HONDEWBERRY,
        :GREPABERRY,
        :TAMATOBERRY
      ]

      [berries.sample, item_qty]
    end

    # Mints
    if rank > 3
      add_raid_reward_candidate(pool, 600) do
        mints = [
          :SERIOUSMINT,
          :LONELYMINT,
          :ADAMANTMINT,
          :NAUGHTYMINT,
          :BRAVEMINT,
          :BOLDMINT,
          :IMPISHMINT,
          :LAXMINT,
          :RELAXEDMINT,
          :MODESTMINT,
          :MILDMINT,
          :RASHMINT,
          :QUIETMINT,
          :CALMMINT,
          :GENTLEMINT,
          :CAREFULMINT,
          :SASSYMINT,
          :TIMIDMINT,
          :HASTYMINT,
          :JOLLYMINT,
          :NAIVEMINT
        ]

        [mints.sample, 1]
      end
    end

    # Feathers
    add_raid_reward_candidate(pool, 600) do
      item_qty = [1, (qty / 2 + rand(-1..2)).round].max

      feathers = [
        :HEALTHFEATHER,
        :MUSCLEFEATHER,
        :RESISTFEATHER,
        :GENIUSFEATHER,
        :CLEVERFEATHER,
        :SWIFTFEATHER
      ]

      [feathers.sample, item_qty]
    end

    if rank > 2
      # Vitamins
      add_raid_reward_candidate(pool, 600) do
        val = (rank > 5) ? 2 : 4
        item_qty = [1, (qty / val + rand(-1..2)).round].max

        vitamins = [
          :HPUP,
          :PROTEIN,
          :IRON,
          :CALCIUM,
          :ZINC,
          :CARBOS
        ]

        [vitamins.sample, item_qty]
      end

      # Training items - normally a 40% reward category.
      add_raid_reward_candidate(pool, 240) do
        training = [
          :PPUP,
          :PPMAX,
          :ABILITYCAPSULE,
          :ABILITYPATCH,
          :BOTTLECAP,
          :GOLDBOTTLECAP
        ]

        [training.sample, 1]
      end

      # Treasure - normally a 20% reward category.
      add_raid_reward_candidate(pool, 120) do
        treasure = case rank
                   when 3
                     [
                       :TINYMUSHROOM,
                       :NUGGET,
                       :PEARL,
                       :RELICCOPPER,
                       :RELICVASE
                     ]
                   when 4, 5
                     [
                       :BIGMUSHROOM,
                       :BIGNUGGET,
                       :BIGPEARL,
                       :RELICSILVER,
                       :RELICBAND
                     ]
                   when 6, 7
                     [
                       :BALMMUSHROOM,
                       :PEARLSTRING,
                       :RELICGOLD,
                       :RELICSTATUE,
                       :RELICCROWN
                     ]
                   else
                     []
                   end

        treasure.empty? ? nil : [treasure.sample, 1]
      end
    end

    #===========================================================================
    # Apricorn/rare balls
    #
    # Native logic:
    #   rand(6) <= rank
    #
    # This gives:
    # Rank 1 = 2/6
    # Rank 2 = 3/6
    # Rank 3 = 4/6
    # Rank 4 = 5/6
    # Rank 5+ = 6/6
    #===========================================================================

    apriball_weight = [(rank + 1) * 100, 600].min

    add_raid_reward_candidate(pool, apriball_weight) do
      apriballs = [
        :HEAVYBALL,
        :LUREBALL,
        :FRIENDBALL,
        :LOVEBALL,
        :LEVELBALL,
        :FASTBALL,
        :MOONBALL,
        :DREAMBALL,
        :BEASTBALL
      ]

      [apriballs.sample, 1]
    end

    #===========================================================================
    # Environmental rewards
    # Each relevant environmental category normally has a 10% chance.
    #===========================================================================

    weather_item = case weather
                   when :Sun       then :HEATROCK
                   when :Rain      then :DAMPROCK
                   when :Sandstorm then :SMOOTHROCK
                   when :Hail      then :ICYROCK
                   when :ShadowSky then :LIFEORB
                   when :Fog       then :SMOKEBALL
                   end

    if weather_item
      add_raid_reward_candidate(pool, 60) do
        [weather_item, 1]
      end
    end

    terrain_item = case terrain
                   when :Electric then :ELECTRICSEED
                   when :Grassy   then :GRASSYSEED
                   when :Misty    then :MISTYSEED
                   when :Psychic  then :PSYCHICSEED
                   end

    if terrain_item
      add_raid_reward_candidate(pool, 60) do
        [terrain_item, 1]
      end
    end

    environ_item = case environ
                   when :None        then :CELLBATTERY
                   when :Grass       then :MIRACLESEED
                   when :TallGrass   then :ABSORBBULB
                   when :MovingWater then :MYSTICWATER
                   when :StillWater  then :FRESHWATER
                   when :Puddle      then :LIGHTCLAY
                   when :Underwater  then :SHOALSHELL
                   when :Cave        then :LUMINOUSMOSS
                   when :Rock        then :HARDSTONE
                   when :Sand        then :SOFTSAND
                   when :Forest      then :SHEDSHELL
                   when :ForestGrass then :SILVERPOWDER
                   when :Snow        then :SNOWBALL
                   when :Ice         then :NEVERMELTICE
                   when :Volcano     then :CHARCOAL
                   when :Graveyard   then :RAREBONE
                   when :Sky         then :PRETTYFEATHER
                   when :Space       then :STARDUST
                   when :UltraSpace  then :COMETSHARD
                   end

    if environ_item
      add_raid_reward_candidate(pool, 60) do
        [environ_item, 1]
      end
    end

    #===========================================================================
    # Select exactly one reward.
    #===========================================================================

    reward = choose_raid_reward_candidate(pool)

    # In case a candidate couldn't produce anything, try again rather than
    # consuming one of the promised bonus rolls.
    while reward.nil? && !pool.empty?
      reward = choose_raid_reward_candidate(pool)
    end

    return reward
  end
end