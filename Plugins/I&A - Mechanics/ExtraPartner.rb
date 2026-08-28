def pbRegisterMultiPartner(partner1 = [], partner2 = [])
  #tr_type, tr_name, tr_id = 0
  if partner1 == [] || partner2 == []
    pbMessage('No data given, please fill out using [] containing the trainer Internal ID (:RIVAL), the trainers name ("Blue"), and the version of that specific trainer (0,1,2,ect...)')
  end
  tr_type1 = GameData::TrainerType.get(partner1[0]).id
  tr_type2 = GameData::TrainerType.get(partner2[0]).id
  pbCancelVehicles
  trainer1 = pbLoadTrainer(tr_type1, partner1[1], partner1[2])
  trainer2 = pbLoadTrainer(tr_type2, partner2[1], partner2[2])
  EventHandlers.trigger(:on_trainer_load, trainer1)
  EventHandlers.trigger(:on_trainer_load, trainer2)
  trainer1.party.each do |i|
    i.owner = Pokemon::Owner.new_from_trainer(trainer1)
    i.calc_stats
  end
  trainer2.party.each do |i|
    i.owner = Pokemon::Owner.new_from_trainer(trainer2)
    i.calc_stats
  end
  $PokemonGlobal.partner = [tr_type1, partner1[1], trainer1.id, trainer1.party]
  $PokemonGlobal.extra_partner = [tr_type2, partner2[1], trainer2.id, trainer2.party]
end

def pbRegisterExtraPartner(tr_type, tr_name, tr_id = 0)
  tr_type = GameData::TrainerType.get(tr_type).id
  pbCancelVehicles
  trainer = pbLoadTrainer(tr_type, tr_name, tr_id)
  EventHandlers.trigger(:on_trainer_load, trainer)
  trainer.party.each do |i|
    i.owner = Pokemon::Owner.new_from_trainer(trainer)
    i.calc_stats
  end
  $PokemonGlobal.extra_partner = [tr_type, tr_name, trainer.id, trainer.party]
end

def pbDeregisterMultiPartner
  $PokemonGlobal.partner = nil
  $PokemonGlobal.extra_partner = nil
end

def pbDeregisterExtraPartner
  $PokemonGlobal.extra_partner = nil
end

def pbCanTripleBattle?
  return true if $player.able_pokemon_count >= 3
  return $PokemonGlobal.partner && $player.able_pokemon_count >= 2
  return $PokemonGlobal.partner  && $PokemonGlobal.extra_partner && $player.able_pokemon_count >= 1
end

module BattleCreationHelperMethods
  def set_up_player_trainers(foe_party)
    trainer_array = [$player]
    ally_items    = []
    pokemon_array = $player.party
    party_starts  = [0]
    if partner_can_participate?(foe_party)
      ally1 = NPCTrainer.new($PokemonGlobal.partner[1], $PokemonGlobal.partner[0])
      ally1.id    = $PokemonGlobal.partner[2]
      ally1.party = $PokemonGlobal.partner[3]
      ally2 = NPCTrainer.new($PokemonGlobal.extra_partner[1], $PokemonGlobal.extra_partner[0]) if $PokemonGlobal.extra_partner != nil
      ally2.id    = $PokemonGlobal.extra_partner[2] if $PokemonGlobal.extra_partner != nil
      ally2.party = $PokemonGlobal.extra_partner[3] if $PokemonGlobal.extra_partner != nil
      ally_items[1] = ally1.items.clone
      ally_items[1] = ally2.items.clone if $PokemonGlobal.extra_partner != nil
      trainer_array.push(ally1)
      trainer_array.push(ally2) if $PokemonGlobal.extra_partner != nil
      pokemon_array = []
      $player.party.each { |pkmn| pokemon_array.push(pkmn) }
      party_starts.push(pokemon_array.length)
      ally1.party.each { |pkmn| pokemon_array.push(pkmn) }
      ally2.party.each { |pkmn| pokemon_array.push(pkmn) }  if $PokemonGlobal.extra_partner != nil
      setBattleRule("double") if $game_temp.battle_rules["size"].nil? && $PokemonGlobal.extra_partner == nil
      setBattleRule("triple") if $game_temp.battle_rules["size"].nil? && $PokemonGlobal.extra_partner != nil
    end
    return trainer_array, ally_items, pokemon_array, party_starts
  end

  def after_battle(outcome, can_lose)
    $player.party.each do |pkmn|
      pkmn.statusCount = 0 if pkmn.status == :POISON   # Bad poison becomes regular
      pkmn.makeUnmega
      pkmn.makeUnprimal
    end
    if $PokemonGlobal.partner
      $player.heal_party
      $PokemonGlobal.partner[3].each do |pkmn|
        pkmn.heal
        pkmn.makeUnmega
        pkmn.makeUnprimal
      end
    if $PokemonGlobal.extra_partner
      $PokemonGlobal.extra_partner[3].each do |pkmn|
        pkmn.heal
        pkmn.makeUnmega
        pkmn.makeUnprimal
      end
    end
    if [2, 5].include?(outcome) && can_lose   # if loss or draw
      $player.party.each { |pkmn| pkmn.heal }
      timer_start = System.uptime
      until System.uptime - timer_start >= 0.25
        Graphics.update
      end
    end
    EventHandlers.trigger(:on_end_battle, outcome, can_lose)
    $game_player.straighten
  end
end
end

class PokemonGlobalMetadata
  attr_accessor :extra_partner

  alias extrapartner_initialize initialize
  def initialize
    @extra_partner = nil
	extrapartner_initialize
  end
end
