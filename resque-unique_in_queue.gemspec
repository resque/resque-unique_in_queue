# frozen_string_literal: true

require File.expand_path('lib/resque/unique_in_queue/version', __dir__)

Gem::Specification.new do |spec|
  spec.name          = 'resque-unique_in_queue'
  spec.version       = Resque::UniqueInQueue::VERSION
  spec.authors       = ['Peter H. Boling', 'Tee Parham']
  spec.email         = %w[peter.boling@gmail.com]
  spec.license       = 'MIT'

  spec.summary       = 'A resque plugin that ensures job uniqueness at enqueue time.'
  spec.summary       = 'A resque plugin that ensures job uniqueness at enqueue time.'
  spec.homepage      = 'https://github.com/pboling/resque-unique_in_queue'
  spec.required_ruby_version = '>= 2.3.0'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'colorize', '>= 0.8'
  spec.add_runtime_dependency 'resque', '>= 1.2'

  spec.add_development_dependency 'bundler', '>= 2.2.10'
  spec.add_development_dependency 'byebug', '~> 10.0'
  spec.add_development_dependency 'fakeredis', '~> 0.7'
  spec.add_development_dependency 'minitest', '~> 5.11'
  spec.add_development_dependency 'pry', '~> 0.11'
  spec.add_development_dependency 'pry-byebug', '~> 3.6'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rubocop', '~> 0.60'
end
