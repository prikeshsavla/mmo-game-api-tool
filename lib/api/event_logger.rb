# frozen_string_literal: true

require 'logger'
require 'json'
require 'time'

module Api
  # Logger for API events, saving logs to a file in JSON format.
  class EventLogger
    def initialize(log_path: nil)
      project_root = File.expand_path('../../', __dir__)
      log_path ||= File.join(project_root, 'log/http.log')

      # Ensure log directory exists
      FileUtils.mkdir_p(File.dirname(log_path))

      @logger = Logger.new(log_path)
    end

    def log_event(type, data)
      event = {
        timestamp: Time.now.iso8601,
        type: type
      }.merge(data)
      @logger.info(JSON.generate(event))
    end

    def info(msg)
      @logger.info(msg)
    end

    def debug(msg)
      @logger.debug(msg)
    end

    def error(msg)
      @logger.error(msg)
    end
  end
end
