# frozen_string_literal: true

require_relative 'lib/artifacts_http_client'
require_relative 'lib/character'

mine_copper = [
  { action: 'move', params: { body: { x: 2, y: 2 } } },
  { action: 'move', params: { body: { x: 2, y: 0 } } },
  { action: 'changes' }
]

2.times.each { mine_copper << { action: 'gathering', params: { body: {} } } }

# deposit_in_bank = [
#   { action: 'move', params: { body: { x: 4, y: 1 } } },
#   { action: 'changes' },
#   { action: 'bank_deposit_item', params: { body: [{ code: 'copper_ore', quantity: 97 }] } }
# ]

my_characters = Character.my_characters

def execute_strategy(character, strategy)
  strategy.each do |value|
    if value[:params]
      character.send(value[:action], value[:params])
    else
      character.send(value[:action])
    end
  end
end

character_queue = {}

my_characters.values.map do |character|
  character_queue[character] = Thread::Queue.new unless character_queue[character]
end

workers = character_queue.keys.map do |character|
  Thread.new do
    loop do
      if character_queue[character].empty?
        puts "waiting 5s for #{character.name} to get a task"
        sleep(5)
        next
      end
      puts "# of Tasks in queue for #{character.name}: #{character_queue[character].size}"
      task = begin
        character_queue[character].pop(true)
      rescue StandardError
        nil
      end
      next unless task

      puts "Processing task #{task} by #{Thread.current.object_id}"
      execute_strategy(character, task) if task
      # sleep(1) # simulate work
    end
  end
end

my_characters.values.map do |character|
  # character_queue[character] = Thread::Queue.new unless character_queue[character]
  mine_copper.each do |entry|
    character_queue[character] << [entry]
  end
end

workers.each(&:join)
puts 'All tasks completed.'
