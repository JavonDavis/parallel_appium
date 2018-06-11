module ParallelAppium
  # Setting up the selenium grid server
  class Server
    # Sets the current thread number environment variable(TEST_ENV_NUMBER)
    def thread
      (ENV['TEST_ENV_NUMBER'].nil? || ENV['TEST_ENV_NUMBER'].empty? ? 1 : ENV['TEST_ENV_NUMBER']).to_i
    end

    # Get the device data from the DEVICES environment variable
    def device_data
      JSON.parse(ENV['DEVICES']).find { |t| t['thread'].eql? thread } unless ENV['DEVICES'].nil?
    end

    # Save device specifications to output directory
    def save_device_data(dev_array)
      dev_array.each do |device|
        device_hash = {}
        device.each do |key, value|
          device_hash[key] = value
        end

        # Delete and create output folder
        `rm -rf output`
        `mkdir output`

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

    # Get the device information for the respective platform
    def get_devices(platform)
      ENV['THREADS'] = '1' if ENV['THREADS'].nil?
      if platform == 'android'
        Android.new.devices
      elsif platform == 'ios'
        IOS.new.devices
      end
    end

    # Start the appium server with the specified options
    def appium_server_start(**options)
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

    # Generate node config for sellenium grid
    def generate_node_config(file_name, appium_port, device)
      system 'mkdir node_configs >> /dev/null 2>&1'
      f = File.new("#{Dir.pwd}/node_configs/#{file_name}", 'w')
      f.write(JSON.generate(
                capabilities: [{ browserName: device[:udid], maxInstances: 5, platform: device[:platform] }],
                configuration: { cleanUpCycle: 2000,
                                 timeout: 1_800_000,
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

    # Start the Selenium grid server as a hub
    def start_hub
      spawn("java -jar #{File.dirname(__FILE__)}/selenium-server-standalone-3.12.0.jar -role hub -newSessionWaitTimeout 250000 -log #{Dir.pwd}/output/hub.log &", out: '/dev/null')
      sleep 3 # wait for hub to start...
      spawn('open -a safari http://127.0.0.1:4444/grid/console')
    end

    # Start an appium server or the platform on the specified port
    def start_single_appium(platform, port)
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

    # Check if a port on an ip address is available
    def port_open?(ip, port)
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

    # Launch the Selenium grid hub and required appium instances
    def launch_hub_and_nodes(platform)
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
end