require "test_helper"

class QueueTest < MiniTest::Spec
  describe ".is_unique?" do
    it "is false for non-unique job" do
      refute Resque::UniqueInQueue::Queue.is_unique?(class: "FakeJob")
    end

    it "is false for invalid job class" do
      refute Resque::UniqueInQueue::Queue.is_unique?(class: "InvalidJob")
    end

    it "is true for unique job" do
      assert Resque::UniqueInQueue::Queue.is_unique?(class: "FakeUniqueInQueue")
    end
  end

  describe ".item_ttl" do
    it "is -1 for non-unique job" do
      assert_equal(-1, Resque::UniqueInQueue::Queue.item_ttl(class: "FakeJob"))
    end

    it "is -1 for invalid job class" do
      assert_equal(-1, Resque::UniqueInQueue::Queue.item_ttl(class: "InvalidJob"))
    end

    it "is -1 for unique job" do
      assert_equal(-1, Resque::UniqueInQueue::Queue.item_ttl(class: "FakeUniqueInQueue"))
    end

    it "is job TTL" do
      assert_equal 300, UniqueInQueueWithTtl.ttl
      assert_equal 300, Resque::UniqueInQueue::Queue.item_ttl(class: "UniqueInQueueWithTtl")
    end
  end

  describe ".lock_after_execution_period" do
    it "is 0 for non-unique job" do
      assert_equal 0, Resque::UniqueInQueue::Queue.lock_after_execution_period(class: "FakeJob")
    end

    it "is 0 for invalid job class" do
      assert_equal 0, Resque::UniqueInQueue::Queue.lock_after_execution_period(class: "InvalidJob")
    end

    it "is 0 for unique job" do
      assert_equal 0, Resque::UniqueInQueue::Queue.lock_after_execution_period(class: "FakeUniqueInQueue")
    end

    it "is job lock period" do
      assert_equal 150, UniqueInQueueWithLock.lock_after_execution_period
      assert_equal 150, Resque::UniqueInQueue::Queue.lock_after_execution_period(class: "UniqueInQueueWithLock")
    end
  end
end
