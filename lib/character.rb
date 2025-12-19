# frozen_string_literal: true

class Character
  ALLOW_ACTIONS = %w[move gathering].freeze

  def initialize(name, client = ArtifactsHttpClient.new)
    @name = name
    @client = client
    @prev_stats = {}
    @stats = client.request_get("/characters/#{name}")['data']
  end

  def details
    client.request_get("/characters/#{name}")['data']
  end

  def changes
    result = {}
    @prev_stats = Marshal.load(Marshal.dump(@stats))
    @stats = details
    @prev_stats.each { |k, v| result[k] = @stats[k] if @stats[k] != v && k != 'inventory' }
    result['inventory'] = @prev_stats['inventory'] - @stats['inventory']
    result
  end

  def action(action_name, params = {})
    data = { body: {}, iterations: 1 }.merge(params)
    puts "Character: #{name}, Action: #{action_name}, params: #{data[:body]}, #{data[:iterations]} time(s)"
    responses = Array.new(data[:iterations]).map do
      wait_for_cooldown

      client.request_post("/my/#{name}/action/#{action_name}", data[:body])
    end
    puts "#{name}: #{changes}"
    responses
  end

  def wait_for_cooldown
    character_cooldown = Time.new(details['cooldown_expiration']) - Time.now
    return unless character_cooldown.positive?

    puts "sleeping for #{character_cooldown.ceil}"
    sleep(character_cooldown.ceil)
  end

  def self.my_characters(client = ArtifactsHttpClient.new)
    response = client.request_get('/my/characters')
    response['data'].each_with_object({}) do |entry, hash|
      hash[entry['name']] = Character.new(entry['name'])
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

  private

  attr_reader :name, :client
end
