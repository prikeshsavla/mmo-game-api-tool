# frozen_string_literal: true

require 'socket'
require 'json'
require_relative '../lib/artifacts_http_client'
require_relative '../lib/character'
require_relative './thread_pool'
require_relative './router'
require_relative './http_utils/request_parser'
require_relative './http_utils/http_responder'

# Wrapper for the application router.
class WebRequestApp
  def initialize(api_client:, worker_pool:)
    @router = Router.new(api_client: api_client, worker_pool: worker_pool)
  end

  def call(env, _worker_pool)
    @router.handle(env)
  end
end

# A simple single-threaded TCP server that handles HTTP requests.
class SingleThreadedServer
  PORT = ENV.fetch('PORT', 3000)
  HOST = ENV.fetch('HOST', '127.0.0.1').freeze
  SOCKET_READ_BACKLOG = ENV.fetch('TCP_BACKLOG', 12).to_i

  def start
    api_client = ArtifactsHttpClient.new
    worker_pool = init_worker_pool(api_client)
    app = WebRequestApp.new(api_client: api_client, worker_pool: worker_pool)

    run_server_loop(app, worker_pool)
  end

  private

  def init_worker_pool(api_client)
    my_characters = Character.my_characters(api_client)
    worker_pool = TaskWorkerThreadPool.new(my_characters: my_characters)
    worker_pool.start_threads
    worker_pool
  end

  def run_server_loop(app, worker_pool)
    server_socket = TCPServer.new(HOST, PORT)
    server_socket.listen(SOCKET_READ_BACKLOG)
    puts "Server started on #{HOST}:#{PORT}"

    loop do
      conn, _addr_info = server_socket.accept
      handle_connection(conn, app, worker_pool)
    end
  end

  def handle_connection(conn, app, worker_pool)
    request_env = RequestParser.call(conn)
    status, headers, body = app.call(request_env, worker_pool)
    HttpResponder.call(conn, status, headers, body)
  rescue StandardError => e
    log_server_error(e)
  ensure
    conn&.close
  end

  def log_server_error(error)
    puts "Server error: #{error.message}"
    puts error.backtrace.join("\n")
  end
end
