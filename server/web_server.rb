require 'socket'
require_relative './http_utils/request_parser'
require_relative './http_utils/http_responder'
# frozen_string_literal: true

require_relative '../lib/artifacts_http_client'
require_relative '../lib/character'

require 'open-uri'
require 'json'

class WebRequestApp
  def call(env)
    puts env
    body = env['rack.input'].string
    puts body
    [200, { 'Content-Type' => 'application/json' }, [body]]
  end
end

class TaskWorkerThreadPool
  attr_accessor :tasks, :running
  attr_reader :my_characters, :threads

  def initialize(my_characters:)
    # threadsafe queue to manage work
    self.tasks = {}

    @my_characters = my_characters

    @threads = {}
  end

  def start_threads
    my_characters.values.map do |character|
      character_name = character.name
      tasks[character_name] = Thread::Queue.new unless tasks[character_name]
      @threads[character_name] = Thread.new do
        thread_block(character_name)
      end
    end
  end

  private

  def thread_block(character_name)
    loop do
      if tasks[character_name].empty?
        puts "waiting 5s for #{character_name} to get a task"
        sleep(5)
        next
      end
      puts "# of Tasks in queue for #{character_name}: #{tasks[character_name].size}"
      perform_next_task(character_name)
    end
  end

  def perform_next_task(character_name)
    task = begin
      tasks[character_name].pop(true)
    rescue StandardError
      nil
    end

    puts "Processing task #{task} by #{Thread.current.object_id}"
    character = my_characters[character_name]
    character.perform(task)
  end
end

class SingleThreadedServer
  PORT = ENV.fetch('PORT', 3000)
  HOST = ENV.fetch('HOST', '127.0.0.1').freeze
  # number of incoming connections to keep in a buffer
  SOCKET_READ_BACKLOG = ENV.fetch('TCP_BACKLOG', 12).to_i

  attr_accessor :app

  # app: Rack app
  def initialize(app)
    self.app = app
  end

  def start
    socket = TCPServer.new(HOST, PORT)
    socket.listen(SOCKET_READ_BACKLOG)
    puts "Server started on #{HOST}:#{PORT}"
    # TODO: refactory strategy with a builder pattern
    mine_copper = [
      { action: 'move', params: { body: { x: 2, y: 0 } } },
      *Array.new(2).map { { action: 'gathering', params: { body: {} } } }
    ]

    my_characters = Character.my_characters

    worker_pool = TaskWorkerThreadPool.new(my_characters: my_characters)
    worker_pool.start_threads

    my_characters.keys.map do |character_name|
      mine_copper.each do |entry|
        worker_pool.tasks[character_name] << [entry]
      end
    end

    # worker_pool.threads.values.each(&:join)
    loop do
      conn, _addr_info = socket.accept
      request = RequestParser.call(conn)
      status, headers, body = app.call(request)
      HttpResponder.call(conn, status, headers, body)
    rescue StandardError => e
      puts e.message
    ensure
      conn&.close
    end
  end
end
