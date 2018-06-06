require 'parallel_appium/version'
require 'parallel_appium/selenium'
require 'parallel_appium/android'
require 'parallel_appium/ios'
require 'parallel_tests'
require 'parallel'
require 'appium_lib'
require 'socket'
require 'timeout'
require 'json'

# Set up environment, Selenium and Appium
module ParallelAppium

  # Sets the current thread number environment variable(TEST_ENV_NUMBER)
  def thread
    (ENV['TEST_ENV_NUMBER'].nil? || ENV['TEST_ENV_NUMBER'].empty? ? 1 : ENV['TEST_ENV_NUMBER']).to_i
  end

  # Get the device data from the DEVICES environment variable
  def device_data
    JSON.parse(ENV['DEVICES']).find { |t| t['thread'].eql? thread }
  end

  # Save device specifications to output directory
  def save_device_data(dev_array)
    dev_array.each do |device|
      device_hash = {}
      device.each do |key, value|
        device_hash[key] = value
      end

      device.each do |k, v|
        open("output/specs-#{device_hash[:udid]}.log", 'a') do |file|
          file << "#{k}: #{v}\n"
        end
      end
    end
  end

  # Set UDID and name environment variable
  def set_udid_environment_variable
    ENV['UDID'] = device_data['udid'] unless device_data.nil?
    ENV['name'] = device_data['name'] unless device_data.nil? # Unique on ios but could be repeated on android
  end

  # Kill process by pattern name
  def kill_process(process)
    `ps -ef | grep #{process} | awk '{print $2}' | xargs kill -9 >> /dev/null 2>&1`
  end

  # Load capabilities based on current device data
  def load_capabilities(caps)
    device = device_data
    unless device.nil?
      caps[:caps][:udid] = device.fetch('udid', nil)
      caps[:caps][:platformVersion] = device.fetch('os', caps[:caps][:platformVersion])
      caps[:caps][:deviceName] = device.fetch('name', caps[:caps][:deviceName])
      caps[:caps][:wdaLocalPort] = device.fetch('wdaPort', nil)
    end

    caps[:caps][:sessionOverride] = true
    caps[:caps][:useNewWDA] = true
    # TODO: Optionally set these capabilities below
    caps[:caps][:noReset] = true
    caps[:caps][:fullReset] = false
    caps[:appium_lib][:server_url] = ENV['SERVER_URL']
    caps
  end

  # Load appium text file if available and attempt to start the driver
  def initialize_appium(platform, caps = nil)
    caps = Appium.load_appium_txt file: File.join(File.dirname(__FILE__), "./appium-#{platform}.txt") if caps.nil?

    if caps.nil?
      puts 'No capabilities specified'
      exit
    end
    capabilities = load_capabilities(caps)
    @driver = Appium::Driver.new(capabilities, true)
    @driver.start_driver
    Appium.promote_appium_methods Object
    Appium.promote_appium_methods RSpec::Core::ExampleGroup
  end
end
