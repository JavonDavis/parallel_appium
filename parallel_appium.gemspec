
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'parallel_appium/version'

summary = 'Multi-threaded mobile testing with Appium, Selenium and Rspec'
description = 'Through the creation of multiple environments
 this library allows for the distribution of multiple tests across 1 or more
devices or simulators. The library uses Selenium Grid and Appium to launch a
specified number of web driver and appium instances to distribute the RSpec test load
across available devices'

Gem::Specification.new do |spec|
  spec.name          = 'parallel_appium'
  spec.version       = ParallelAppium::VERSION
  spec.authors       = ['Javon Davis']
  spec.email         = ['javonldavis14@gmail.com']

  spec.summary       = summary
  spec.description   = description
  spec.homepage      = 'https://github.com/JavonDavis/Parallel_Appium'
  spec.license       = 'GPL-3.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "http://mygemserver.com"
  # else
  #   raise 'RubyGems 2.4.1 or newer is required to protect against ' \
  #     'public gem pushes.'
  # end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.cert_chain  = ['certs/javondavis.pem']
  spec.signing_key = File.expand_path('~/.ssh/gem-private_key.pem') if $PROGRAM_NAME =~ /gem\z/

  spec.add_development_dependency 'appium_lib', '~> 9.14'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'json', '~> 1.8'
  spec.add_development_dependency 'parallel', '~> 1.12'
  spec.add_development_dependency 'parallel_tests', '~> 2.21'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
