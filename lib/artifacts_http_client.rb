# frozen_string_literal: true

require 'uri'
require 'json'
require 'net/http'
require 'dotenv/load'
require_relative 'api/event_logger'
# Client for interacting with the Artifacts MMO API, featuring automatic logging.
class ArtifactsHttpClient
  API_HOST = 'https://api.artifactsmmo.com'
  API_TOKEN = ENV['API_TOKEN'].freeze

  def initialize(
    logger: Api::EventLogger.new
  )
    @host = URI(API_HOST)
    @logger = logger
  end

  def request_get(path, query = nil)
    request = Net::HTTP::Get.new(build_uri(path, query))
    execute_request(request)
  end

  def request_post(path, body)
    @logger.debug([path, body].join)
    request = Net::HTTP::Post.new(build_uri(path))
    request.body = JSON.generate(body)
    execute_request(request)
  end

  private

  def build_uri(path, query = nil)
    uri = URI("#{API_HOST}#{path}")
    uri.query = query if query && !query.empty?
    uri
  end

  def apply_headers(request)
    request['authorization'] = "Bearer #{API_TOKEN}"
    request['content-type'] = 'application/json'
  end

  def execute_request(request)
    apply_headers(request)
    log_request(request)

    response = perform_http_request(request)
    parsed_body = parse_response_body(response)

    log_response(request, response, parsed_body)

    { status: response.code.to_i, body: parsed_body }
  end

  def log_request(request)
    @logger.log_event('request', {
                        method: request.method,
                        path: request.path,
                        body: request.body ? JSON.parse(request.body) : nil
                      })
  end

  def perform_http_request(request)
    http = Net::HTTP.new(@host.host, @host.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.request(request)
  end

  def parse_response_body(response)
    body = response.read_body
    JSON.parse(body)
  rescue StandardError
    body
  end

  def log_response(request, response, parsed_body)
    @logger.log_event('response', {
                        method: request.method,
                        path: request.path,
                        status_code: response.code.to_i,
                        body: parsed_body
                      })
  end
end
