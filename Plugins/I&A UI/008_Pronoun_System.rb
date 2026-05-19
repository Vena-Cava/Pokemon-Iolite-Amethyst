#===============================================================================
# Pronoun Selection Scene
#===============================================================================

class PokemonSystem
  attr_accessor :player_pronouns
end

module PronounSystem
  def self.setup
    $PokemonSystem.player_pronouns ||= {
      :player_color       => "g",
      :subject            => "they",
      :object             => "them",
      :possessive         => "their",
      :contraction        => "they're",
      :verb               => "are",

      :rival1_color       => "g",
      :rival1_name        => "Alex",
      :rival1_subject     => "they",
      :rival1_object      => "them",
      :rival1_possessive  => "their",
      :rival1_contraction => "they're",
      :rival1_verb        => "are",

      :rival2_color       => "g",
      :rival2_name        => "Alex",
      :rival2_subject     => "they",
      :rival2_object      => "them",
      :rival2_possessive  => "their",
      :rival2_contraction => "they're",
      :rival2_verb        => "are"
    }
  end
  
  def self.set_player_color(gender)
    setup
    $PokemonSystem.player_pronouns[:player_color] =
      gender_color(gender)
  end

  def self.set(type, value)
    setup
    $PokemonSystem.player_pronouns[type] = value
  end

  def self.get(type, text_case = nil)
    setup
    text = $PokemonSystem.player_pronouns[type].to_s

    return text if !text_case

    apply_case(text, text_case)
  end
  
  def self.normalize_pronoun(text)
    return "" if !text

    text = text.strip.downcase

    # Capitalize standalone I
    words = text.split(" ")
    words.map! do |w|
      w == "i" ? "I" : w
    end

    return words.join(" ")
  end
  
  def self.set_rival_names(player_gender)
    setup

    case player_gender
    when :male
      set_rival_name(1, "Alex") # NB
      set_rival_name(2, "Amber")   # Female

    when :female
      set_rival_name(1, "Micah")    # Male
      set_rival_name(2, "Alex") # NB

    when :nb
      set_rival_name(1, "Amber")   # Female
      set_rival_name(2, "Micah")    # Male
    end
  end

  def self.set_rival_name(rival_number, name)
    setup
    $PokemonSystem.player_pronouns["rival#{rival_number}_name".to_sym] = name
  end

  def self.rival_name(rival_number)
    setup
    return $PokemonSystem.player_pronouns["rival#{rival_number}_name".to_sym]
  end
  
  def self.color_name(color)
    case color
    when "b"; return "Blue"
    when "r"; return "Red"
    when "g"; return "Green"
    else;    return "Unknown"
    end
  end
  
  def self.set_rival_pronouns(player_gender)
    setup

    case player_gender
    when :male
      set_rival(1, :nb)
      set_rival(2, :female)
    when :female
      set_rival(1, :male)
      set_rival(2, :nb)
    when :nb
      set_rival(1, :female)
      set_rival(2, :male)
    end
  end

  def self.gender_color(gender)
    case gender
    when :male
      return "b"
    when :female
      return "r"
    when :nb
      return "g"
    else
      return "w"
    end
  end

  def self.set_rival(rival_number, gender)
    data = {
      :male   => ["he", "him", "his", "he's", "is"],
      :female => ["she", "her", "her", "she's", "is"],
      :nb     => ["they", "them", "their", "they're", "are"]
    }

    keys = [:subject, :object, :possessive, :contraction, :verb]
    keys.each_with_index do |key, i|
      $PokemonSystem.player_pronouns["rival#{rival_number}_#{key}".to_sym] = data[gender][i]
    end

    $PokemonSystem.player_pronouns["rival#{rival_number}_color".to_sym] =
      gender_color(gender)
  end

  def self.rival_get(rival_number, type, text_case = nil)
    setup
    text = $PokemonSystem.player_pronouns["rival#{rival_number}_#{type}".to_sym].to_s

    return text if !text_case

    apply_case(text, text_case)
  end

  def self.apply_case(text, text_case)
    case text_case
    when :upper
      text.upcase
    when :proper
      text.split(" ").map { |w| w.capitalize }.join(" ")
    else
      text.downcase
    end
  end
  
  def self.apply_preset(preset)
    case preset
    when :masculine
      set(:subject, "he")
      set(:object, "him")
      set(:possessive, "his")
      set(:contraction, "he's")
      set(:verb, "is")
      set(:player_color, "b")

    when :feminine
      set(:subject, "she")
      set(:object, "her")
      set(:possessive, "her")
      set(:contraction, "she's")
      set(:verb, "is")
      set(:player_color, "r")

    when :neutral
      set(:subject, "they")
      set(:object, "them")
      set(:possessive, "their")
      set(:contraction, "they're")
      set(:verb, "are")
      set(:player_color, "g")
    end
  end
  
  def self.convert_message_codes(text)
    setup
    text = text.clone

    text.gsub!(/\\psub/i)   { p_subject }
    text.gsub!(/\\PSub/)    { p_subject(:proper) }
    text.gsub!(/\\PSUB/)    { p_subject(:upper) }
    text.gsub!(/\\pobj/i)   { p_object }
    text.gsub!(/\\PObj/i)   { p_object(:proper) }
    text.gsub!(/\\POBJ/i)   { p_object(:upper) }
    text.gsub!(/\\ppos/i)   { p_possessive }
    text.gsub!(/\\PPos/i)   { p_possessive(:proper) }
    text.gsub!(/\\PPOS/i)   { p_possessive(:upper) }
    text.gsub!(/\\pcon/i)   { p_contraction }
    text.gsub!(/\\PCon/i)   { p_contraction(:proper) }
    text.gsub!(/\\PCON/i)   { p_contraction(:upper) }
    text.gsub!(/\\pverb/i)  { p_verb }
    text.gsub!(/\\PVerb/i)  { p_verb(:proper) }
    text.gsub!(/\\PVERB/i)  { p_verb(:upper) }

    text.gsub!(/\\r1sub/i)  { r1_subject }
    text.gsub!(/\\R1Sub/i)  { r1_subject(:proper) }
    text.gsub!(/\\R1SUB/i)  { r1_subject(:upper) }
    text.gsub!(/\\r1obj/i)  { r1_object }
    text.gsub!(/\\R1Obj/i)  { r1_object(:proper) }
    text.gsub!(/\\R1OBJ/i)  { r1_object(:upper) }
    text.gsub!(/\\r1pos/i)  { r1_possessive }
    text.gsub!(/\\R1Pos/i)  { r1_possessive(:proper) }
    text.gsub!(/\\R1POS/i)  { r1_possessive(:upper) }
    text.gsub!(/\\r1con/i)  { r1_contraction }
    text.gsub!(/\\R1Con/i)  { r1_contraction(:proper) }
    text.gsub!(/\\R1CON/i)  { r1_contraction(:upper) }
    text.gsub!(/\\r1verb/i) { r1_verb }
    text.gsub!(/\\R1Verb/i) { r1_verb(:proper) }
    text.gsub!(/\\R1VERB/i) { r1_verb(:upper) }

    text.gsub!(/\\r2sub/i)  { r2_subject }
    text.gsub!(/\\R2Sub/i)  { r2_subject(:proper) }
    text.gsub!(/\\R2SUB/i)  { r2_subject(:upper) }
    text.gsub!(/\\r2obj/i)  { r2_object }
    text.gsub!(/\\R2Obj/i)  { r2_object(:proper) }
    text.gsub!(/\\R2OBJ/i)  { r2_object(:upper) }
    text.gsub!(/\\r2pos/i)  { r2_possessive }
    text.gsub!(/\\R2Pos/i)  { r2_possessive(:proper) }
    text.gsub!(/\\R2POS/i)  { r2_possessive(:upper) }
    text.gsub!(/\\r2con/i)  { r2_contraction }
    text.gsub!(/\\R2Con/i)  { r2_contraction(:proper) }
    text.gsub!(/\\R2CON/i)  { r2_contraction(:upper) }
    text.gsub!(/\\r2verb/i) { r2_verb }
    text.gsub!(/\\R2Verb/i) { r2_verb(:proper) }
    text.gsub!(/\\R2VERB/i) { r2_verb(:upper) }

    text.gsub!(/\\pc/i)     { p_color }
    text.gsub!(/\\r1c/i)    { r1_color }
    text.gsub!(/\\r2c/i)    { r2_color }

    text.gsub!(/\\r1name/i) { r1_name(:proper) }
    text.gsub!(/\\R1NAME/i) { r1_name(:upper) }
    text.gsub!(/\\r2name/i) { r2_name(:proper) }
    text.gsub!(/\\R2NAME/i) { r2_name(:upper) }

    return text
  end
end

def p_subject(c = :lower);      PronounSystem.get(:subject, c);     end
def p_object(c = :lower);       PronounSystem.get(:object, c);      end
def p_possessive(c = :lower);   PronounSystem.get(:possessive, c);  end
def p_contraction(c = :lower);  PronounSystem.get(:contraction, c); end
def p_verb(c = :lower);         PronounSystem.get(:verb, c);        end

def r1_subject(c = :lower);     PronounSystem.rival_get(1, :subject, c);     end
def r1_object(c = :lower);      PronounSystem.rival_get(1, :object, c);      end
def r1_possessive(c = :lower);  PronounSystem.rival_get(1, :possessive, c);  end
def r1_contraction(c = :lower); PronounSystem.rival_get(1, :contraction, c); end
def r1_verb(c = :lower);        PronounSystem.rival_get(1, :verb, c);        end

def r2_subject(c = :lower);     PronounSystem.rival_get(2, :subject, c);     end
def r2_object(c = :lower);      PronounSystem.rival_get(2, :object, c);      end
def r2_possessive(c = :lower);  PronounSystem.rival_get(2, :possessive, c);  end
def r2_contraction(c = :lower); PronounSystem.rival_get(2, :contraction, c); end
def r2_verb(c = :lower);        PronounSystem.rival_get(2, :verb, c);        end

def p_color
  PronounSystem.get(:player_color)
end

def r1_color
  PronounSystem.rival_get(1, :color)
end

def r2_color
  PronounSystem.rival_get(2, :color)
end

def r1_name
  PronounSystem.rival_name(1)
end

def r2_name
  PronounSystem.rival_name(2)
end

def pbChoosePronouns
  PronounSystem.setup

  choices = [
    ["Preset",               :preset,      ["masculine", "feminine", "neutral"]],
    ["Subject Pronoun",      :subject,     ["he", "she", "they"]],
    ["Object Pronoun",       :object,      ["him", "her", "them"]],
    ["Possessive Pronoun",   :possessive,  ["his", "her", "their"]],
    ["Pronoun Contraction",  :contraction, ["he's", "she's", "they're"]],
    ["Contraction Verb",     :verb,        ["is", "are"]],
    ["Name Colour",          :player_color,["b", "r", "g"]]
  ]

  loop do
    commands = []
    choices.each do |choice|
      label = choice[0]
      type  = choice[1]
      value = PronounSystem.get(type)
      value = PronounSystem.color_name(value) if type == :player_color
      commands.push("#{label}: #{value}")
    end
    commands.push("Done")

    cmd = pbMessage(
      _INTL("Choose your pronouns."),
      commands,
      -1
    )

    break if cmd < 0 || cmd == commands.length - 1

    label  = choices[cmd][0]
    type   = choices[cmd][1]
    values = choices[cmd][2]

    if type == :preset
      subcommands = ["Masculine", "Feminine", "Neutral"]
    elsif type == :player_color
      subcommands = ["Blue", "Red", "Green"]
    else
      subcommands = values.map { |v| v.capitalize }
      subcommands.push("Custom")
    end
    subcommands.push("Back")

    subcmd = pbMessage(
      _INTL("{1}", label),
      subcommands,
      -1
    )

    next if subcmd < 0 || subcmd == subcommands.length - 1

    if type == :preset
      PronounSystem.apply_preset([:masculine, :feminine, :neutral][subcmd])
    elsif type == :player_color
      PronounSystem.set(type, values[subcmd])
    elsif subcommands[subcmd] == "Custom"
      text = pbEnterText(_INTL("Enter custom text."), 1, 10)
      PronounSystem.set(type, PronounSystem.normalize_pronoun(text)) if text && text != ""
    else
      PronounSystem.set(type, values[subcmd])
    end
  end
end


alias pronounsystem_pbMessage pbMessage

def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
  message = PronounSystem.convert_message_codes(message) if message.is_a?(String)
  return pronounsystem_pbMessage(message, commands, cmdIfCancel, skin, defaultCmd, &block)
end