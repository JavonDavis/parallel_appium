require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

# TODO: Move checks into gem
namespace :parallel_appium do
  desc 'Validate Android'
  task :validate_android do
    %x(which emulator 2>&1)
    puts '==========================================='
    can_do_android = true
    can_do_android = can_do_android && ($? == 0)
    if can_do_android
      puts "emulator command configured properly"
    else
      puts "emulator command not configured properly"
      exit
    end
    puts '==========================================='
    puts 'Android good to go'
  end

  desc 'Validate iOS'
  task :validate_ios do
    %x(which instruments 2>&1)
    puts '==========================================='
    can_do_ios = true
    can_do_ios = can_do_ios && ($? == 0)
    if can_do_ios
      puts "instruments command configured properly"
    else
      puts "instruments command not configured properly"
      exit
    end

    puts '==========================================='
    puts 'iOS good to go'
  end
end