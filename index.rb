# frozen_string_literal: true

# Main entry point for manual character control and testing strategies via CLI.
require_relative 'lib/artifacts_http_client'
require_relative 'lib/character'

# Strategy defined as a sequence of actions.
# TODO: Implement a builder pattern for easier strategy creation.
MINE_COPPER_STRATEGY = [
  { action: 'move', params: { body: { x: 4, y: 0 } } },
  { action: 'move', params: { body: { x: 2, y: 0 } } },
  { action: 'gathering', params: { body: {} } },
  { action: 'gathering', params: { body: {} } }
].freeze

def run_character_loop(character, tasks)
  loop do
    if tasks[character].empty?
      puts "Waiting 5s for #{character.name} to get a task..."
      sleep(5)
      break
    end

    process_next_task(character, tasks)
  end
end

def process_next_task(character, tasks)
  task = begin
    tasks[character].pop(true)
  rescue ThreadError
    nil
  end
  return unless task

  puts "Processing task #{task} for #{character.name}..."
  character.perform(task)
end

my_characters = Character.my_characters
tasks = {}

my_characters.each_value do |character|
  tasks[character] = Thread::Queue.new
  MINE_COPPER_STRATEGY.each { |action| tasks[character] << [action] }
end

workers = my_characters.each_value.map do |character|
  Thread.new { run_character_loop(character, tasks) }
end

workers.each(&:join)
puts 'All tasks completed.'
