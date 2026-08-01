class FakeJob
  @queue = :normal
end

class FakeUniqueInQueue
  include Resque::Plugins::UniqueInQueue

  @queue = :unique

  def self.perform(_)
  end
end

class FailingUniqueInQueue
  include Resque::Plugins::UniqueInQueue

  @queue = :unique

  def self.perform(_)
    raise "Fail"
  end
end

class UniqueInQueueWithTtl
  include Resque::Plugins::UniqueInQueue

  @queue = :unique_with_ttl
  @ttl = 300

  def self.perform(*_)
  end
end

class UniqueInQueueWithLock
  include Resque::Plugins::UniqueInQueue

  @queue = :unique_with_lock
  @lock_after_execution_period = 150

  def self.perform(*_)
  end
end
