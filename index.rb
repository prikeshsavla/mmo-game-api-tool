# frozen_string_literal: true

require_relative 'lib/artifacts_http_client'
require_relative 'lib/character'

my_characters = Character.my_characters

def mine_copper(character)
  character.move({ x: 2, y: 0 })
  character.gathering({}, 2)
end

ts = my_characters.values.map do |character|
  Thread.new { mine_copper(character) }
end
ts.map(&:value)
