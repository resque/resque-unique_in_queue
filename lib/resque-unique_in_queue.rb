# frozen_string_literal: true

require "resque/unique_in_queue/version"

# Ruby Std Lib
require "digest/md5"

# External Gems
require "resque"

# This Gem
require "resque/plugins/unique_in_queue"
require "resque/unique_in_queue/resque_ext/job"
require "resque/unique_in_queue/resque_ext/resque"
require "resque/unique_in_queue/queue"
require "resque/unique_in_queue/configuration"

# See lib/resque/plugins/unique_in_queue.rb for the actual plugin
#
# This is not that ^.  Rather, it is an API used by the plugin or as tools by a
#   developer.  These methods are not intended to be included/extended into
#   Resque, Resque::Job, or Resque::Queue.
module Resque
  module UniqueInQueue
    # Wraps text in ANSI blue escape codes. Replaces the former `colorize`
    # dependency; produces the exact sequence colorize's String#blue emitted.
    def self.blue_text(text)
      "\e[0;34;49m#{text}\e[0m"
    end

    PLUGIN_TAG = blue_text("[R-UIQ] ").freeze

    def log(message)
      configuration.logger&.send(configuration.log_level, message) if configuration.logger
    end

    def debug(message)
      configuration.logger&.debug("#{PLUGIN_TAG}#{message}") if configuration.debug_mode
    end

    # For per-class config with a block
    def configure
      yield(@configuration)
    end

    #### CONFIG ####
    class << self
      attr_accessor :configuration
    end

    self.configuration = Configuration.instance # setup defaults

    module_function(:log,
      :debug)
  end
end
