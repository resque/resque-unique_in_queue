# Resque::UniqueInQueue

| Project                 |  Resque::UniqueInQueue |
|------------------------ | ----------------------- |
| gem name                |  [resque-unique_in_queue](https://rubygems.org/gems/resque-unique_in_queue) |
| license                 |  [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT) |
| download rank           |  [![Downloads Today](https://img.shields.io/gem/rd/resque-unique_in_queue.svg)](https://github.com/pboling/resque-unique_in_queue) |
| version                 |  [![Version](https://img.shields.io/gem/v/resque-unique_in_queue.svg)](https://rubygems.org/gems/resque-unique_in_queue) |
| code triage             |  [![Open Source Helpers](https://www.codetriage.com/pboling/resque-unique_in_queue/badges/users.svg)](https://www.codetriage.com/pboling/resque-unique_in_queue) |
| homepage                |  [on Github.com][homepage], [on Railsbling.com][blogpage] |
| documentation           |  [on RDoc.info][documentation] |
| Spread ~♡ⓛⓞⓥⓔ♡~      |  [🌏](https://about.me/peter.boling), [👼](https://angel.co/peter-boling), [:shipit:](http://coderwall.com/pboling), [![Tweet Peter](https://img.shields.io/twitter/follow/galtzo.svg?style=social&label=Follow)](http://twitter.com/galtzo) |

Resque::UniqueInQueue is a resque plugin to add unique jobs to resque.

It is a re-write of [resque_solo](https://github.com/neighborland/resque_solo), which is a fork of [resque-loner](https://github.com/jayniz/resque-loner).

It requires resque 1.25 and works with ruby 2.0 and later.

It removes the dependency on `Resque::Helpers`, which is deprecated for resque 2.0.

## Install

Add the gem to your Gemfile:

```ruby
gem 'resque-unique_in_queue'
```

## Usage

`resque-unique_in_queue` utilizes 3 class instance variables that can be set
in your Jobs, in addition to the standard `@queue`.  Here they are, with their
default values:

```ruby
@lock_after_execution_period = 0
@ttl = -1
@unique_in_queue_key_base = 'r-uiq'.freeze
```

The last one, in normal circumstances, shouldn't be set as different per class,
or uniqueness cleanup becomes more difficult.

It should be set only once, globally:

```ruby
Resque::UniqueInQueue.configuration.unique_in_queue_key_base = 'my-custom'
```


```ruby
class UpdateCat
  include Resque::Plugins::UniqueInQueue
  @queue = :cats

  def self.perform(cat_id)
    # do something
  end
end
```

If you attempt to queue a unique job multiple times, it is ignored:

```
Resque.enqueue UpdateCat, 1
=> true
Resque.enqueue UpdateCat, 1
=> nil
Resque.enqueue UpdateCat, 1
=> nil
Resque.size :cats
=> 1
Resque.enqueued? UpdateCat, 1
=> true
Resque.enqueued_in? :dogs, UpdateCat, 1
=> false
```

### Options

#### `lock_after_execution_period`

By default, lock_after_execution_period is 0 and `enqueued?` becomes false as soon as the job
is being worked on.

The `lock_after_execution_period` setting can be used to delay when the unique job key is deleted
(i.e. when `enqueued?` becomes `false`). For example, if you have a long-running unique job that
takes around 10 seconds, and you don't want to requeue another job until you are sure it is done,
you could set `lock_after_execution_period = 20`. Or if you never want to run a long running
job more than once per minute, set `lock_after_execution_period = 60`.

```ruby
class UpdateCat
  include Resque::Plugins::UniqueInQueue
  @queue = :cats
  @lock_after_execution_period = 20

  def self.perform(cat_id)
    # do something
  end
end
```

#### Oops, I have stale Queue Time uniqueness keys...
 
Preventing jobs with matching signatures from being queued, and they never get
dequeued because there is no actual corresponding job to dequeue.

*How to deal?*

Option: Rampage

```ruby
# Delete *all* queued jobs in the queue, and
#   delete *all* unqueness keys for the queue.
Redis.remove_queue('queue_name')
```

Option: Butterfly

```ruby
# Delete *no* queued jobs at all, and
#   delete *all* unqueness keys for the queue (might then allow duplicates).
Resque::UniqueInQueue::Queue.cleanup('queue_name')
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pboling/resque-unique_in_queue. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Code of Conduct

Everyone interacting in the Resque::Plugins::UniqueInQueue project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/pboling/resque-unique_in_queue/blob/master/CODE_OF_CONDUCT.md).

## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0][semver].
Violations of this scheme should be reported as bugs. Specifically,
if a minor or patch version is released that breaks backward
compatibility, a new version should be immediately released that
restores compatibility. Breaking changes to the public API will
only be introduced with new major versions.

As a result of this policy, you can (and should) specify a
dependency on this gem using the [Pessimistic Version Constraint][pvc] with two digits of precision.

For example:

```ruby
spec.add_dependency 'resque-unique_in_queue', '~> 1.0'
```

## License

* Copyright (c) 2012 Jonathan R. Wallace
* Copyright (c) 2017 - 2018 [Peter H. Boling][peterboling] of [Rails Bling][railsbling]

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT) 

[license]: LICENSE
[semver]: http://semver.org/
[pvc]: http://guides.rubygems.org/patterns/#pessimistic-version-constraint
[railsbling]: http://www.railsbling.com
[peterboling]: http://www.peterboling.com
[documentation]: http://rdoc.info/github/pboling/resque-unique_in_queue/frames
[homepage]: https://github.com/pboling/resque-unique_in_queue/
[blogpage]: http://www.railsbling.com/tags/resque-unique_in_queue/
