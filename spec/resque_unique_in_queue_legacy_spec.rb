# frozen_string_literal: true

# This file preserves the original integration cases while moving them from
# MiniTest into the RSpec harness; several cases intentionally exercise one
# behavior through multiple assertions.
# rubocop:disable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength, Env/Assign

require "spec_helper"
require "resque/unique_in_queue"
require_relative "support/fake_jobs"

RSpec.describe "resque-unique_in_queue legacy behavior" do
  before do
    Resque.redis.redis.flushdb
  end

  it "enqueues identical jobs once" do
    Resque.enqueue FakeUniqueInQueue, "x"
    Resque.enqueue FakeUniqueInQueue, "x"

    expect(Resque.size(:unique)).to eq(1)
  end

  it "allows the same jobs to be executed one after the other" do
    Resque.enqueue FakeUniqueInQueue, "foo"
    Resque.enqueue FakeUniqueInQueue, "foo"
    expect(Resque.size(:unique)).to eq(1)

    Resque.reserve(:unique)
    expect(Resque.size(:unique)).to eq(0)

    Resque.enqueue FakeUniqueInQueue, "foo"
    Resque.enqueue FakeUniqueInQueue, "foo"
    expect(Resque.size(:unique)).to eq(1)
  end

  it "considers equivalent hashes regardless of key order" do
    Resque.enqueue FakeUniqueInQueue, bar: 1, foo: 2
    Resque.enqueue FakeUniqueInQueue, foo: 2, bar: 1

    expect(Resque.size(:unique)).to eq(1)
  end

  it "treats string and symbol keys equally" do
    Resque.enqueue FakeUniqueInQueue, bar: 1, foo: 1
    Resque.enqueue FakeUniqueInQueue, :bar => 1, "foo" => 1

    expect(Resque.size(:unique)).to eq(1)
  end

  it "marks jobs as unqueued when Job.destroy kills them" do
    Resque.enqueue FakeUniqueInQueue, "foo"
    Resque.enqueue FakeUniqueInQueue, "foo"
    expect(Resque.size(:unique)).to eq(1)

    Resque::Job.destroy(:unique, FakeUniqueInQueue)
    expect(Resque.size(:unique)).to eq(0)

    Resque.enqueue FakeUniqueInQueue, "foo"
    Resque.enqueue FakeUniqueInQueue, "foo"
    expect(Resque.size(:unique)).to eq(1)
  end

  it "marks jobs as unqueued when they raise an exception" do
    2.times { Resque.enqueue(FailingUniqueInQueue, "foo") }
    expect(Resque.size(:unique)).to eq(1)

    Resque::Worker.new(:unique).work(0)
    expect(Resque.size(:unique)).to eq(0)

    2.times { Resque.enqueue(FailingUniqueInQueue, "foo") }
    expect(Resque.size(:unique)).to eq(1)
  end

  it "reports if a unique job is enqueued" do
    Resque.enqueue FakeUniqueInQueue, "foo"

    expect(Resque.enqueued?(FakeUniqueInQueue, "foo")).to be(true)
    expect(Resque.enqueued?(FakeUniqueInQueue, "bar")).to be(false)
  end

  it "reports if a unique job is enqueued in another queue" do
    begin
      default_queue = FakeUniqueInQueue.instance_variable_get(:@queue)
      FakeUniqueInQueue.instance_variable_set(:@queue, :other)
      Resque.enqueue FakeUniqueInQueue, "foo"

      expect(Resque.enqueued_in?(:other, FakeUniqueInQueue, "foo")).to be(true)

      FakeUniqueInQueue.instance_variable_set(:@queue, default_queue)
      expect(Resque.enqueued?(FakeUniqueInQueue, "foo")).to be(false)
    ensure
      FakeUniqueInQueue.instance_variable_set(:@queue, default_queue)
    end
  end

  it "cleans up when a queue is destroyed" do
    Resque.enqueue FakeUniqueInQueue, "foo"
    Resque.enqueue FailingUniqueInQueue, "foo"
    Resque.remove_queue(:unique)
    Resque.enqueue(FakeUniqueInQueue, "foo")

    expect(Resque.size(:unique)).to eq(1)
  end

  it "honors ttl in the Redis key" do
    Resque.enqueue UniqueInQueueWithTtl
    expect(Resque.enqueued?(UniqueInQueueWithTtl)).to be(true)

    keys = Resque.redis.keys("r-uiq:queue:unique_with_ttl:job:*")
    expect(keys.length).to eq(1)
    expect(Resque.redis.ttl(keys.first)).to be_within(2).of(UniqueInQueueWithTtl.ttl)
  end

  it "prevents duplicates within lock_after_execution_period" do
    Resque.enqueue UniqueInQueueWithLock, "foo"
    Resque.enqueue UniqueInQueueWithLock, "foo"
    expect(Resque.size(:unique_with_lock)).to eq(1)

    Resque.reserve(:unique_with_lock)
    expect(Resque.size(:unique_with_lock)).to eq(0)

    Resque.enqueue UniqueInQueueWithLock, "foo"
    expect(Resque.size(:unique_with_lock)).to eq(0)
  end

  it "honors lock_after_execution_period in the Redis key" do
    Resque.enqueue UniqueInQueueWithLock
    Resque.reserve(:unique_with_lock)

    keys = Resque.redis.keys("r-uiq:queue:unique_with_lock:job:*")
    expect(keys.length).to eq(1)
    expect(Resque.redis.ttl(keys.first)).to be_within(2).of(UniqueInQueueWithLock.lock_after_execution_period)
  end

  describe Resque::UniqueInQueue::Queue do
    describe ".is_unique?" do
      it "is false for non-unique and invalid jobs" do
        expect(described_class.is_unique?(class: "FakeJob")).to be(false)
        expect(described_class.is_unique?(class: "InvalidJob")).to be(false)
      end

      it "is true for a unique job" do
        expect(described_class.is_unique?(class: "FakeUniqueInQueue")).to be(true)
      end
    end

    describe ".item_ttl" do
      it "is -1 for non-unique, invalid, and unique jobs without a ttl" do
        expect(described_class.item_ttl(class: "FakeJob")).to eq(-1)
        expect(described_class.item_ttl(class: "InvalidJob")).to eq(-1)
        expect(described_class.item_ttl(class: "FakeUniqueInQueue")).to eq(-1)
      end

      it "is the job ttl" do
        expect(UniqueInQueueWithTtl.ttl).to eq(300)
        expect(described_class.item_ttl(class: "UniqueInQueueWithTtl")).to eq(300)
      end
    end

    describe ".lock_after_execution_period" do
      it "is 0 for non-unique, invalid, and unique jobs without a lock period" do
        expect(described_class.lock_after_execution_period(class: "FakeJob")).to eq(0)
        expect(described_class.lock_after_execution_period(class: "InvalidJob")).to eq(0)
        expect(described_class.lock_after_execution_period(class: "FakeUniqueInQueue")).to eq(0)
      end

      it "is the job lock period" do
        expect(UniqueInQueueWithLock.lock_after_execution_period).to eq(150)
        expect(described_class.lock_after_execution_period(class: "UniqueInQueueWithLock")).to eq(150)
      end
    end
  end

  it "is a valid plugin" do
    expect(Resque::Plugin.lint(Resque::Plugins::UniqueInQueue)).to be_empty
  end

  it "enqueues normal jobs" do
    Resque.enqueue FakeJob, "x"
    Resque.enqueue FakeJob, "x"

    expect(Resque.size(:normal)).to eq(2)
  end

  it "does not report if a non-unique job was enqueued" do
    expect(Resque.enqueued?(FakeJob)).to be_nil
  end

  it "skips queue locks for non-unique items" do
    item = {class: "FakeJob", args: ["x"]}

    expect(Resque::UniqueInQueue::Queue.queued?(:normal, item)).to be(false)
    expect(Resque::UniqueInQueue::Queue.mark_queued(:normal, item)).to be_nil
    expect(Resque::UniqueInQueue::Queue.mark_unqueued(:normal, item)).to be_nil
  end

  it "does not raise when deleting an empty queue" do
    expect { Resque.remove_queue(:unique) }.not_to raise_error
  end

  it "supports inline enqueue, reserve, and destroy without queue locks" do
    begin
      Resque.inline = true

      expect(Resque.enqueue(FakeUniqueInQueue, "inline")).to be(true)
      expect(Resque.reserve(:unique)).to be_nil
      expect(Resque::Job.destroy(:unique, FakeUniqueInQueue)).to eq(0)
    ensure
      Resque.inline = false
    end
  end

  it "runs before and after enqueue hooks" do
    expect(Resque.enqueue_to(:normal, HookedJob)).to be(true)
    expect(Resque.enqueue_to(:normal, BeforeEnqueueVetoJob)).to be_nil
  end

  describe Resque::UniqueInQueue do
    it "formats the plugin tag" do
      expect(described_class.blue_text("text")).to eq("\e[0;34;49mtext\e[0m")
    end

    it "logs through the configured logger" do
      logger = instance_double(Logger)
      allow(logger).to receive(:debug)
      allow(logger).to receive(:info)
      described_class.configuration.logger = logger
      described_class.configuration.log_level = :info

      described_class.log("message")
      expect(logger).to have_received(:info).with("message")
    end

    it "does nothing when logging is not configured" do
      described_class.configuration.logger = nil

      expect { described_class.log("message") }.not_to raise_error
    end

    it "logs debug messages only when debug mode is enabled" do
      logger = instance_double(Logger)
      allow(logger).to receive(:debug)
      described_class.configuration.logger = logger
      described_class.configuration.debug_mode = false
      described_class.debug("hidden")
      expect(logger).not_to have_received(:debug)

      described_class.configuration.debug_mode = true
      described_class.debug("visible")
      expect(logger).to have_received(:debug).with("\e[0;34;49m[R-UIQ] \e[0mvisible")
    end

    it "uses default plugin configuration values" do
      expect(FakeUniqueInQueue.ttl).to eq(-1)
      expect(FakeUniqueInQueue.lock_after_execution_period).to eq(0)
      expect(FakeUniqueInQueue.unique_in_queue_key_base).to eq("r-uiq")
    end

    it "yields its configuration" do
      configurable = Class.new do
        include Resque::UniqueInQueue
      end.new
      configurable.instance_variable_set(:@configuration, described_class.configuration)
      configurable.configure do |configuration|
        configuration.ttl = 42
      end

      expect(described_class.configuration.ttl).to eq(42)
    end

    it "initializes debug logging from the environment" do
      begin
        configuration = Resque::UniqueInQueue::Configuration.instance
        original_debug = ENV["RESQUE_DEBUG"]

        ENV["RESQUE_DEBUG"] = "true"
        configuration.send(:initialize)
        expect(configuration.debug_mode).to be(true)
        expect(configuration.logger).to be_a(Logger)

        ENV["RESQUE_DEBUG"] = "queue"
        configuration.send(:initialize)
        expect(configuration.debug_mode).to be(true)

        ENV["RESQUE_DEBUG"] = "false"
        configuration.send(:initialize)
        expect(configuration.debug_mode).to be(false)
      ensure
        if original_debug
          ENV["RESQUE_DEBUG"] = original_debug
        else
          ENV.delete("RESQUE_DEBUG")
        end
        configuration.send(:initialize)
      end
    end
  end

  describe "#enqueue_to" do
    context "with a non-unique job" do
      it "returns true if the job was enqueued" do
        expect(Resque.enqueue_to(:normal, FakeJob)).to be(true)
        expect(Resque.enqueue_to(:normal, FakeJob)).to be(true)
      end
    end

    context "with a unique job" do
      it "returns true if the job was enqueued" do
        expect(Resque.enqueue_to(:normal, FakeUniqueInQueue)).to be(true)
      end

      it "returns nil if the job already existed" do
        Resque.enqueue_to(:normal, FakeUniqueInQueue)

        expect(Resque.enqueue_to(:normal, FakeUniqueInQueue)).to be_nil
      end
    end
  end
end

# rubocop:enable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength, Env/Assign
