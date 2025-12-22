# frozen_string_literal: true

require_relative 'lib/artifacts_http_client'
require_relative 'lib/character'

mine_copper = [
  { action: 'move', params: { body: { x: 2, y: 0 } } },
  *Array.new(2).map { { action: 'gathering', params: { body: {} } } },
  { action: 'changes' }
]

my_characters = Character.my_characters

# puts my_characters.values.map(&:data)
tasks = {}

my_characters.values.map do |character|
  tasks[character] = Thread::Queue.new unless tasks[character]
end

workers = tasks.keys.map do |character|
  Thread.new do
    loop do
      if tasks[character].empty?
        puts "waiting 5s for #{character.name} to get a task"
        sleep(5)
        break
      end
      puts "# of Tasks in queue for #{character.name}: #{tasks[character].size}"
      task = begin
        tasks[character].pop(true)
      rescue StandardError
        nil
      end
      next unless task

      puts "Processing task #{task} by #{Thread.current.object_id}"
      character.execute_strategy(task)
    end
  end
end

my_characters.values.map do |character|
  # tasks[character] = Thread::Queue.new unless tasks[character]
  mine_copper.each do |entry|
    tasks[character] << [entry]
  end
end

workers.each(&:join)
puts 'All tasks completed.'
