# frozen_string_literal: true

require_relative 'lib/artifacts_http_client'
require_relative 'lib/character'

mine_copper = {
  'move': { body: { x: 2, y: 0 } },
  "changes": nil,
  'gathering': { body: {}, iterations: 20 }
}

deposit_in_bank = {
  'move': { body: { x: 2, y: 0 } },
  "changes": nil,
  'gathering': { body: {}, iterations: 20 }
}

my_characters = Character.my_characters

def execute_strategy(character, strategy)
  strategy.each_entry do |key, value|
    if value
      character.send(key, value)
    else
      character.send(key)
    end
  end
end

ts = my_characters.values.map do |character|
  Thread.new { execute_strategy(character, mine_copper) }
end
ts.map(&:value)
