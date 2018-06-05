
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'parallel_appium/version'

summary = 'Start multi-threaded appium servers'
description = 'Through the creation of multiple environments
 this library allows for the distribution of multiple tests across 1 or more
devices or simulators. The library uses Selenium Grid and Appium to launch a
specified number of web driver and appium instances to spread the test load
across available devices'

Gem::Specification.new do |spec|
  spec.name          = 'parallel_appium'
  spec.version       = ParallelAppium::VERSION
  spec.authors       = ['Javon Davis']
  spec.email         = ['javonldavis14@gmail.com']

  spec.summary       = summary
  spec.description   = description
  spec.homepage      = 'https://www.google.com/'
  spec.license       = 'GPLv3'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.4.1 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'appium_lib', '~> 9.14.1'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'json', '~> 1.8'
  spec.add_development_dependency 'parallel', '~> 1.12.1'
  spec.add_development_dependency 'parallel_tests', '~> 2.21.3'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
