# frozen_string_literal: true

require 'logger'
require 'pry'
require_relative 'character_data'

# Represents an MMO character and provides methods for actions and profile management.
class Character
  attr_reader :name, :profile

  ALLOW_ACTIONS = %w[
    move gathering fight rest equip unequip use
    bank_deposit_item bank_withdraw_item bank_deposit_gold bank_withdraw_gold
    task_new task_complete task_cancel task_exchange task_trade
    recycling crafting ge_buy ge_sell ge_cancel
  ].freeze

  def initialize(name, client: ArtifactsHttpClient.new, logger: Logger.new($stdout))
    @name = name
    @client = client
    @logger = logger
    response = client.request_get("/characters/#{name}")
    @profile = CharacterData.from_hash(response[:body]['data'])
  end

  def self.my_characters(client = ArtifactsHttpClient.new)
    response = client.request_get('/my/characters')
    (response[:body]['data'] || []).each_with_object({}) do |entry, hash|
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
    wait_for_cooldown
  end

  private

  def perform_action(action_name, body)
    wait_for_cooldown

    response_data = client.request_post("/my/#{name}/action/#{action_name.split('_').join('/')}", body)
    body_data = response_data[:body]
    char_data = body_data.dig('data', 'character') || body_data.dig('error', 'details', 'character')
    @profile = CharacterData.from_hash(char_data) if char_data
    body_data
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
