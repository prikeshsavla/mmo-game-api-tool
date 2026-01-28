# frozen_string_literal: true

require 'json'

# Responsible for routing incoming requests to appropriate handlers.
class Router
  def initialize(api_client:, worker_pool:)
    @api_client = api_client
    @worker_pool = worker_pool
  end

  def handle(env)
    case env['REQUEST_METHOD']
    when 'GET'
      handle_get(env['PATH_INFO'], env['QUERY_STRING'])
    when 'POST'
      handle_post(env)
    else
      json_response(405, { status: 'error', message: 'Method Not Allowed' })
    end
  end

  private

  def handle_get(path, query)
    if path.start_with?('/queues')
      character_name = path.split('/')[2]
      json_response(200, @worker_pool.queue_size(character_name))
    else
      result = @api_client.request_get(path, query)
      json_response(result[:status], result[:body])
    end
  end

  def handle_post(env)
    body = env['rack.input']&.string || '{}'
    data = JSON.parse(body, symbolize_names: true)

    if valid_task_data?(data)
      @worker_pool.add_tasks(data)
      json_response(200, { status: 'success', message: 'Tasks added to queue' })
    else
      json_response(400, { status: 'error', message: 'Missing character or tasks' })
    end
  rescue JSON::ParserError
    json_response(400, { status: 'error', message: 'Invalid JSON' })
  end

  def valid_task_data?(data)
    data[:character] && data[:tasks]
  end

  def json_response(status, body)
    [status, { 'Content-Type' => 'application/json' }, [body.to_json]]
  end
end
