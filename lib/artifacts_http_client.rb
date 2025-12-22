# frozen_string_literal: true

require 'uri'
require 'json'
require 'net/http'
require 'dotenv/load'

class ArtifactsHttpClient
  attr_reader :http

  API_TOKEN = ENV['API_TOKEN'].freeze
  API_HOST = 'https://api.artifactsmmo.com'

  def initialize
    host = URI(API_HOST)
    @http = Net::HTTP.new(host.host, host.port)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @logger = Logger.new('log/http.log')
  end

  def request_get(path)
    url = URI("#{API_HOST}#{path}")
    request = Net::HTTP::Get.new(url)
    execute_request(request)['data']
  end

  def request_post(path, body)
    @logger.debug("POST: #{path} #{body}")
    url = URI("#{API_HOST}#{path}")
    request = Net::HTTP::Post.new(url)
    request.body = JSON[body]
    execute_request(request)
  end

  private

  def apply_headers(request)
    request['authorization'] = "Bearer #{API_TOKEN}"
    request['content-type'] = 'application/json'
  end

  def execute_request(request)
    apply_headers(request)
    response = http.request(request)
    JSON[response.read_body]
  end
end
