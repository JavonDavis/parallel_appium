require 'parallel_appium/version'
require 'parallel_appium/server'
require 'parallel_appium/android'
require 'parallel_appium/ios'
require 'parallel_tests'
require 'parallel'
require 'appium_lib'
require 'socket'
require 'timeout'
require 'json'

module ParallelAppium
  # Set up environment, Selenium and Appium
  class ParallelAppium

    def initialize
      @server = Server.new
    end

    # Kill process by pattern name
    def kill_process(process)
      `ps -ef | grep #{process} | awk '{print $2}' | xargs kill -9 >> /dev/null 2>&1`
    end

    # Load capabilities based on current device data
    def load_capabilities(caps)
      device = @server.device_data
      unless device.nil?
        caps[:caps][:udid] = device.fetch('udid', nil)
        caps[:caps][:platformVersion] = device.fetch('os', caps[:caps][:platformVersion])
        caps[:caps][:deviceName] = device.fetch('name', caps[:caps][:deviceName])
        caps[:caps][:wdaLocalPort] = device.fetch('wdaPort', nil)
        caps[:caps][:avd] = device.fetch('avd', nil)
      end

      caps[:appium_lib][:server_url] = ENV['SERVER_URL']
      caps
    end

    # Load appium text file if available and attempt to start the driver
    # platform is either android or ios, otherwise read from ENV
    # caps is mapping of appium capabilities
    def initialize_appium(**args)
      platform = args[:platform]
      caps = args[:caps]

      platform = ENV['platform'] if platform.nil?

      if platform.nil?
        puts 'Platform not found in environment variable'
        exit
      end

      caps = Appium.load_appium_txt file: File.new("#{Dir.pwd}/appium-#{platform}.txt") if caps.nil?

      if caps.nil?
        puts 'No capabilities specified'
        exit
      end
      puts 'Preparing to load capabilities'
      capabilities = load_capabilities(caps)
      puts 'Loaded capabilities'
      @driver = Appium::Driver.new(capabilities, true)
      puts 'Created driver'
      Appium.promote_appium_methods Object
      Appium.promote_appium_methods RSpec::Core::ExampleGroup
      @driver
    end

    # Define a signal handler for SIGINT
    def setup_signal_handler(ios_pid = nil, android_pid = nil)
      Signal.trap('INT') do
        Process.kill('INT', ios_pid) unless ios_pid.nil?
        Process.kill('INT', android_pid) unless android_pid.nil?

        # Kill any existing Appium and Selenium processes
        kill_process 'appium'
        kill_process 'selenium'

        # Terminate ourself
        exit 1
      end
    end

    # Decide whether to execute specs in parallel or not
    # @param [String] platform
    # @param [int] threads
    # @param [String] spec_path
    # @param [boolean] parallel
    def execute_specs(platform, threads, spec_path, parallel = false)
      command = if parallel
                  "platform=#{platform} parallel_rspec -n #{threads} #{spec_path}"
                else
                  "platform=#{platform} rspec #{spec_path} --tag #{platform}"
                end

      puts "Executing #{command}"
      exec command
    end

    # Define Spec path, validate platform and execute specs
    def setup(platform, file_path, threads, parallel)
      spec_path = 'spec/'
      spec_path = file_path.to_s unless file_path.nil?
      puts "SPEC PATH:#{spec_path}"

      unless %w[ios android].include? platform
        puts "Invalid platform #{platform}"
        exit
      end

      execute_specs platform, threads, spec_path, parallel
    end

    # Validate platform is valid
    def check_platform(platform)
      options = %w[ios android all]
      if platform.nil?
        puts 'No platform detected... Options: ios,android,all'
        exit
      elsif !options.include? platform.downcase
        puts "Invalid platform #{platform}"
        exit
      end
    end

    # Fire necessary appium server instances and Selenium grid server if needed.
    def start(**args)

      platform = args[:platform]
      file_path = args[:file_path]

      # Validate environment variable
      if ENV['platform'].nil?
        if platform.nil?
          puts 'No platform detected in environment and none passed to start...'
          exit
        end
        ENV['platform'] = platform
      end

      sleep 3

      # Appium ports
      ios_port = 4725
      android_port = 4727
      default_port = 4725

      platform = ENV['platform']

      # Platform is required
      check_platform platform

      platform = platform.downcase
      ENV['BASE_DIR'] = Dir.pwd

      # Check if multithreaded for distributing tests across devices
      threads = ENV['THREADS'].nil? ? 1 : ENV['THREADS'].to_i
      parallel = threads != 1

      if platform != 'all'
        pid = fork do
          if !parallel
            ENV['SERVER_URL'] = "http://0.0.0.0:#{default_port}/wd/hub"
            @server.start_single_appium platform, default_port
          else
            ENV['SERVER_URL'] = 'http://localhost:4444/wd/hub'
            @server.launch_hub_and_nodes platform
          end
          setup(platform, file_path, threads, parallel)
        end

        puts "PID: #{pid}"
        setup_signal_handler(pid)
        Process.waitpid(pid)
      else # Spin off 2 sub-processes, one for Android connections and another for iOS,
        # each with redefining environment variables for the server url, number of threads and platform
        ios_pid = fork do
          ENV['THREADS'] = threads.to_s
          if parallel
            ENV['SERVER_URL'] = 'http://localhost:4444/wd/hub'
            puts 'Start iOS'
            @server.launch_hub_and_nodes 'ios'
          else
            ENV['SERVER_URL'] = "http://0.0.0.0:#{ios_port}/wd/hub"
            puts 'Start iOS'
            @server.start_single_appium 'ios', ios_port
          end
          setup('ios', file_path, threads, parallel)
        end

        android_pid = fork do
          ENV['THREADS'] = threads.to_s
          if parallel
            ENV['SERVER_URL'] = 'http://localhost:4444/wd/hub'
            puts 'Start Android'
            @server.launch_hub_and_nodes 'android'
          else
            ENV['SERVER_URL'] = "http://0.0.0.0:#{android_port}/wd/hub"
            puts 'Start Android'
            @server.start_single_appium 'android', android_port
          end
          setup('android', file_path, threads, parallel)
        end

        puts "iOS PID: #{ios_pid}\nAndroid PID: #{android_pid}"
        setup_signal_handler(ios_pid, android_pid)
        [ios_pid, android_pid].each { |process_pid| Process.waitpid(process_pid) }
      end

      # Kill any existing Appium and Selenium processes
      kill_process 'appium'
      kill_process 'selenium'
    end
  end
end
