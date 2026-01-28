# frozen_string_literal: true

# Manages a pool of worker threads for background task processing per character.
class TaskWorkerThreadPool
  attr_reader :tasks, :my_characters, :threads

  def initialize(my_characters:)
    @tasks = {}
    @my_characters = my_characters
    @threads = {}
  end

  def start_threads
    @my_characters.each_value do |character|
      character_name = character.name
      @tasks[character_name] ||= Thread::Queue.new
      @threads[character_name] = Thread.new { thread_block(character_name) }
    end
  end

  def add_tasks(params)
    character_name = params[:character]
    params[:tasks].each do |entry|
      enqueue_task_entry(character_name, entry)
    end
  end

  private

  def enqueue_task_entry(character_name, entry)
    iterations = entry.dig(:params, :iterations) || 1

    if iterations > 1
      enqueue_repeated(character_name, entry, iterations)
    else
      @tasks[character_name] << [entry]
    end
  end

  def enqueue_repeated(character_name, entry, iterations)
    single_task = entry.dup
    single_task[:params] = entry[:params].merge(iterations: 1)

    iterations.times { @tasks[character_name] << [single_task] }
  end

  public

  def queue_size(character_name = nil)
    if character_name
      @tasks[character_name]&.size || 0
    else
      @tasks.transform_values(&:size)
    end
  end

  private

  def thread_block(character_name)
    loop do
      if @tasks[character_name].empty?
        sleep(5)
        next
      end

      perform_next_task(character_name)
    end
  end

  def perform_next_task(character_name)
    task = begin
      @tasks[character_name].pop(true)
    rescue ThreadError
      nil
    end

    return unless task

    puts "Processing task for #{character_name} by thread #{Thread.current.object_id}"
    character = @my_characters[character_name]
    character.perform(task)
  end
end
