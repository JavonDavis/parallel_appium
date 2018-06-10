require 'bundler/setup'
require 'parallel_appium'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before :all do
    parallel_appium = ParallelAppium::ParallelAppium.new
    puts "Initializing Appium for #{ENV['platform']}"
    parallel_appium.initialize_appium platform: ENV['platform']
  end
end
