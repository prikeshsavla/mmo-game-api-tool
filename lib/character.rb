# frozen_string_literal: true

require 'logger'
require 'pry'
require_relative 'character_data'

class Character
  attr_reader :name, :profile

  ALLOW_ACTIONS = %w[move gathering bank_deposit_item].freeze

  def initialize(name, client: ArtifactsHttpClient.new, logger: Logger.new($stdout))
    @name = name
    @client = client
    @logger = logger
    @profile = CharacterData.from_hash(client.request_get("/characters/#{name}"))
  end

  def self.my_characters(client = ArtifactsHttpClient.new)
    response = client.request_get('/my/characters')
    response.each_with_object({}) do |entry, hash|
      hash[entry['name']] = Character.new(entry['name'], logger: Logger.new($stdout))
    end
  end

  def method_missing(method_name, *arguments)
    operation = method_name.to_s

    if ALLOW_ACTIONS.include?(operation)
      action(operation, *arguments)
    else
      super
    end
  end

  def respond_to_missing?(method_name)
    operation = method_name.to_s
    ALLOW_ACTIONS.include?(operation) || super
  end

  def perform(strategy)
    puts strategy
    # binding.pry
    strategy.each do |value|
      send(value[:action], value[:params])
    end
  end

  private

  def perform_action(action_name, body)
    wait_for_cooldown

    response = client.request_post("/my/#{name}/action/#{action_name.split('_').join('/')}", body)
    @profile = CharacterData.from_hash(response['data']['character']) if response.dig('data', 'character')
    response
  end

  def action(action_name, params = {})
    data = { body: {}, iterations: 1 }.merge(params || {})
    @logger.debug "Character: #{name}, Action: #{action_name}, params: #{data[:body]}, #{data[:iterations]} time(s)"
    return unless data[:iterations].positive?

    Array.new(data[:iterations]).map do
      perform_action(action_name, data[:body])
    end
  end

  def wait_for_cooldown
    cooldown = Time.new(profile.cooldown_expiration || 0) - Time.now
    return unless cooldown.positive?

    @logger.debug "sleeping for #{cooldown.ceil}"
    sleep(cooldown.ceil)
  end

  attr_reader :client
end
