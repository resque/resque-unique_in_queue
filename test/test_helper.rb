if ENV["SIMPLE_COV"]
  require "simplecov"
  SimpleCov.start
end

require "minitest/autorun"
require "resque-unique_in_queue"
require "fake_jobs"
require "fakeredis/minitest"

begin
  require "pry-byebug"
rescue LoadError
  # ignore
end
