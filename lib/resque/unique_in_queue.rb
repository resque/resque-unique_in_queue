# frozen_string_literal: true

require "version_gem"
require_relative "unique_in_queue/version"

module Resque
  module UniqueInQueue
  end
end

Resque::UniqueInQueue::Version.class_eval do
  extend VersionGem::Basic
end
