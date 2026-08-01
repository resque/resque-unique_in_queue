module Resque
  class Job
    class << self
      # Mark an item as queued
      def create_unique_in_queue(queue, klass, *args)
        item = {class: klass.to_s, args: args}
        if Resque.inline? || !Resque::UniqueInQueue::Queue.is_unique?(item)
          return create_without_unique_in_queue(queue, klass, *args)
        end
        return "EXISTED" if Resque::UniqueInQueue::Queue.queued?(queue, item)

        create_return_value = false
        # redis transaction block
        Resque.redis.multi do
          create_return_value = create_without_unique_in_queue(queue, klass, *args)
          Resque::UniqueInQueue::Queue.mark_queued(queue, item)
        end
        create_return_value
      end

      # Mark an item as unqueued
      def reserve_unique_in_queue(queue)
        item = reserve_without_unique_in_queue(queue)
        Resque::UniqueInQueue::Queue.mark_unqueued(queue, item) if item && !Resque.inline?
        item
      end

      # Mark destroyed jobs as unqueued
      def destroy_unique_in_queue(queue, klass, *args)
        Resque::UniqueInQueue::Queue.destroy(queue, klass, *args) unless Resque.inline?
        destroy_without_unique_in_queue(queue, klass, *args)
      end

      alias_method :create_without_unique_in_queue, :create
      alias_method :create, :create_unique_in_queue
      alias_method :reserve_without_unique_in_queue, :reserve
      alias_method :reserve, :reserve_unique_in_queue
      alias_method :destroy_without_unique_in_queue, :destroy
      alias_method :destroy, :destroy_unique_in_queue

      if defined?(Resque::Plugins::PriorityEnqueue::Resque)
        # Hack to support resque-priority_enqueue: https://github.com/coupa/resque-priority_enqueue
        def priority_create_unique_in_queue(queue, klass, *args)
          item = {class: klass.to_s, args: args}
          if Resque.inline? || !Resque::UniqueInQueue::Queue.is_unique?(item)
            return priority_create_without_unique_in_queue(queue, klass, *args)
          end
          return "EXISTED" if Resque::UniqueInQueue::Queue.queued?(queue, item)

          priority_create_return_value = false
          # redis transaction block
          Resque.redis.multi do
            priority_create_return_value = priority_create_without_unique_in_queue(queue, klass, *args)
            Resque::UniqueInQueue::Queue.mark_queued(queue, item)
          end
          priority_create_return_value
        end

        alias_method :priority_create_without_unique_in_queue, :priority_create
        alias_method :priority_create, :priority_create_unique_in_queue
      end
    end
  end
end
