require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec


# TODO: Move into functions
desc 'Validate Android'
task :validate_android do
  %x(emulator 2>&1)
  if $? == 0
    puts "emulator command configured properly"
  else
    puts "emulator command not configured properly"
  end
end

desc 'Validate iOS'
task :validate_ios do
  %x(instruments 2>&1)
  if $? == 0
    puts "instruments command configured properly"
  else
    puts "instruments command not configured properly"
  end
end