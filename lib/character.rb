# frozen_string_literal: true

require 'logger'
require_relative 'character_data'

class Character
  attr_reader :name, :data

  ALLOW_ACTIONS = %w[move gathering bank_deposit_item].freeze

  def initialize(name, client: ArtifactsHttpClient.new, logger: Logger.new($stdout))
    @name = name
    @client = client
    @profile = reload
    @logger = logger
  end

  def changes
    prev_data = CharacterData.new(@profile.to_h)
    @profile = reload
    @profile.diff(prev_data)
  end

  def self.my_characters(client = ArtifactsHttpClient.new)
    response = client.request_get('/my/characters')
    response.each_with_object({}) do |entry, hash|
      hash[entry['name']] = Character.new(entry['name'], logger: Logger.new("log/#{entry['name']}.log", 'daily'))
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

  def execute_strategy(strategy)
    strategy.each do |value|
      send(value[:action], value[:params])
    end
  end

  private

  def take_action(action_name, body)
    wait_for_cooldown

    client.request_post("/my/#{name}/action/#{action_name.split('_').join('/')}", body)
  end

  def action(action_name, params = {})
    data = { body: {}, iterations: 1 }.merge(params || {})
    @logger.debug "Character: #{name}, Action: #{action_name}, params: #{data[:body]}, #{data[:iterations]} time(s)"
    Array.new(data[:iterations]).map do
      take_action(action_name, data[:body])
    end
  end

  def wait_for_cooldown
    return unless @profile.cooldown_expiration

    cooldown = Time.new(@profile.cooldown_expiration) - Time.now
    return unless cooldown.positive?

    @logger.debug "sleeping for #{cooldown.ceil}"
    sleep(cooldown.ceil)
  end

  def reload
    CharacterData.new(client.request_get("/characters/#{name}"))
  end
  attr_reader :client
end
