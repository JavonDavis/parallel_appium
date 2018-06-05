require 'parallel_appium/version'
require 'parallel_tests'
require 'parallel'
require 'appium_lib'
require 'socket'
require 'timeout'
require 'json'

# Set up environment, Selenium and Appium
module ParallelAppium

  def self.thread
    (ENV['TEST_ENV_NUMBER'].nil? || ENV['TEST_ENV_NUMBER'].empty? ? 1 : ENV['TEST_ENV_NUMBER']).to_i
  end

  def self.device_data
    JSON.parse(ENV['DEVICES']).find { |t| t['thread'].eql? thread }
  end

  def self.set_udid_environment_variable
    ENV['UDID'] = device_data['udid'] unless device_data.nil?
    ENV['name'] = device_data['name'] unless device_data.nil? # Unique on ios but could be repeated on android
  end

  def self.load_capabilities(caps)
    device = device_data
    unless device.nil?
      caps[:caps][:udid] = device.fetch('udid', nil)
      caps[:caps][:platformVersion] = device.fetch('os', caps[:caps][:platformVersion])
      caps[:caps][:deviceName] = device.fetch('name', caps[:caps][:deviceName])
      caps[:caps][:wdaLocalPort] = device.fetch('wdaPort', nil)
    end

    caps[:caps][:sessionOverride] = true
    caps[:caps][:useNewWDA] = true
    caps[:caps][:noReset] = true
    caps[:caps][:fullReset] = false
    caps[:appium_lib][:server_url] = ENV['SERVER_URL']
    caps
  end

  def self.initialize_appium(platform, caps = nil)
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

  # Setting up the selenium grid server
  class SeleniumGrid

    def self.get_devices(platform)
      ENV['THREADS'] = '1' if ENV['THREADS'].nil?
      if platform == 'android'
        Android.devices
      elsif platform == 'ios'
        IOS.devices
      end
    end

    def self.save_device_data(dev_array)
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

    def self.kill_process(process)
      `ps -ef | grep #{process} | awk '{print $2}' | xargs kill -9 >> /dev/null 2>&1`
    end

    def self.appium_server_start(**options)
      command = +'appium'
      command << " --nodeconfig #{options[:config]}" if options.key?(:config)
      command << " -p #{options[:port]}" if options.key?(:port)
      command << " -bp #{options[:bp]}" if options.key?(:bp)
      command << " --log #{Dir.pwd}/output/#{options[:log]}" if options.key?(:log)
      command << " --tmp #{ENV['BASE_DIR']}/tmp/#{options[:tmp]}" if options.key?(:tmp)
      Dir.chdir('.') do
        puts(command)
        pid = spawn(command, out: '/dev/null')
        puts 'Waiting for Appium to start up...'
        sleep 10
        puts "Appium PID: #{pid}"
        puts 'Appium server did not start' if pid.nil?
      end
    end

    def self.generate_node_config(file_name, appium_port, device)
      system 'mkdir node_configs >> /dev/null 2>&1'
      f = File.new("#{Dir.pwd}/node_configs/#{file_name}", 'w')
      f.write(JSON.generate(
                capabilities: [{ browserName: device[:udid], maxInstances: 5, platform: device[:platform] }],
                configuration: { cleanUpCycle: 2000,
                                 timeout: 180_0000,
                                 registerCycle: 5000,
                                 proxy: 'org.openqa.grid.selenium.proxy.DefaultRemoteProxy',
                                 url: "http://127.0.0.1:#{appium_port}/wd/hub",
                                 host: '127.0.0.1',
                                 port: appium_port,
                                 maxSession: 5,
                                 register: true,
                                 hubPort: 4444,
                                 hubHost: 'localhost' }
      ))
      f.close
    end

    def self.start_hub
      spawn("java -jar selenium-server-standalone-3.12.0.jar -role hub -newSessionWaitTimeout 250000 -log #{Dir.pwd}/output/hub.log &", out: '/dev/null')
      sleep 3 # wait for hub to start...
      spawn('open -a safari http://127.0.0.1:4444/grid/console')
    end

    def self.start_single_appium(platform, port)
      puts 'Getting Device data'
      devices = get_devices(platform)[0]
      if devices.nil?
        puts "No devices for #{platform}, Exiting..."
        exit
      else
        udid = devices[:udid]
        save_device_data [devices]
      end
      ENV['UDID'] = udid
      appium_server_start udid: udid, log: "appium-#{udid}.log", port: port
    end

    def self.port_open?(ip, port)
      begin
        Timeout.timeout(1) do
          begin
            s = TCPSocket.new(ip, port)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return false
          end
        end
      rescue Timeout::Error
        return false
      end
      false
    end

    def self.launch_hub_and_nodes(platform)
      start_hub unless port_open?('localhost', 4444)
      devices = get_devices(platform)

      if devices.nil?
        puts "No devices for #{platform}, Exiting...."
        exit
      else
        save_device_data [devices]
      end

      threads = ENV['THREADS'].to_i
      if devices.size < threads
        puts "Not enough available devices, reducing to #{devices.size} threads"
        ENV['THREADS'] = devices.size.to_s
      else
        puts "Using #{threads} of the available #{devices.size} devices"
        devices = devices[0, threads]
      end


      Parallel.map_with_index(devices, in_processes: devices.size) do |device, index|
        offset = platform == 'android' ? 0 : threads
        port = 4000 + index + offset
        bp = 2250 + index + offset
        config_name = "#{device[:udid]}.json"
        generate_node_config config_name, port, device
        node_config = "#{Dir.pwd}/node_configs/#{config_name}"
        puts port
        appium_server_start config: node_config, port: port, bp: bp, udid: device[:udid],
                            log: "appium-#{device[:udid]}.log", tmp: device[:udid]
      end
    end
  end

  # Connecting to iOS devices
  class IOS
    @simulators = `instruments -s devices`.split("\n").reverse

    def self.simulator_information
      re = /\([0-9]+\.[0-9]\) \[[0-9A-Z-]+\]/m

      # Filter out simulator info for iPhone platform version and udid
      @simulators.select { |simulator_data| simulator_data.include?('iPhone') && !simulator_data.include?('Apple Watch') }
                 .map { |simulator_data| simulator_data.scan(re)[0].tr('()[]', '').split }[0, ENV['THREADS'].to_i]
    end

    def self.devices
      devices = []
      simulator_information.each_with_index do |data, i|
        devices.push(name: @simulators[i][0, @simulators[i].index('(') - 1], platform: 'ios', os: data[0], udid: data[1],
                     wdaPort: 8100 + i + ENV['THREADS'].to_i, thread: i + 1)
      end
      ENV['DEVICES'] = JSON.generate(devices)
      devices
    end
  end

  # Connecting to Android devices
  class Android
    def self.start_emulators
      emulators = `emulator -list-avds`.split("\n")
      emulators = emulators[0, ENV['THREADS'].to_i]
      Parallel.map(emulators, in_threads: emulators.size) do |emulator|
        spawn("emulator -avd #{emulator} -scale 100dpi -no-boot-anim -no-audio -accel on &", out: '/dev/null')
      end
    end

    def self.devices
      start_emulators
      sleep 10
      devices = `adb devices`.split("\n").select { |x| x.include? "\tdevice" }.map.each_with_index { |d, i| {platform: 'android', name: 'android', udid: d.split("\t")[0], wdaPort: 8100 + i, thread: i + 1} }
      devices = devices.map { |x| x.merge(get_android_device_data(x[:udid])) }

      ENV['DEVICES'] = JSON.generate(devices)
      devices
    end

    def self.get_android_device_data(udid)
      specs = { os: 'ro.build.version.release', manufacturer: 'ro.product.manufacturer', model: 'ro.product.model', sdk: 'ro.build.version.sdk' }
      hash = {}
      specs.each do |key, spec|
        value = `adb -s #{udid} shell getprop "#{spec}"`.strip
        hash.merge!(key => value.to_s)
      end
      hash
    end
  end
end
