require 'parallel_appium/version'
require 'parallel'
require 'json'

module ParallelAppium
  # Setting up the selenium grid server
  class SeleniumGrid

    def get_devices(platform)
      if platform == 'android'
        Android.devices
      elsif platform == 'ios'
        IOS.devices
      end
    end
  end

  # Connecting to iOS devices
  class IOS
    def self.simulators
      `instruments -s devices`.split("\n").reverse # Reverse to use latest devices first
    end

    def self.simulator_information
      re = /\([0-9]+\.[0-9]\) \[[0-9A-Z-]+\]/m

      # Filter out simulator info for iPhone platform version and udid
      simulators.select { |simulator_data| simulator_data.include?('iPhone') && !simulator_data.include?('Apple Watch')}
                .map { |simulator_data| simulator_data.scan(re)[0].tr('()[]', '').split }
    end

    def self.devices
      devices = []
      simulator_information.each_with_index do |data, i|
        devices.push(name: simulators[i][0, simulators[i].index('(') - 1], platform: 'ios', os: data[0], udid: data[1],
                     wdaPort: 8100 + i + ENV['THREADS'].to_i, thread: i + 1)
      end

      ENV['DEVICES'] = JSON.generate(devices)
      devices
    end
  end

  # Connecting to Android devices
  class Android
    def start_emulators
      emulators = (`emulator -list-avds`).split("\n")
      Parallel.map(emulators, :in_threads=> emulators.size) do |emulator|
        spawn("emulator -avd #{emulator} -scale 100dpi -no-boot-anim -no-audio -accel on &", :out=> "/dev/null")
      end
    end

    def devices
      start_emulators

      devs = `adb devices`.split("\n").select {|x| x.include? "\tdevice"}.map.each_with_index {|d, i| {platform: 'android', name: 'android', udid: d.split("\t")[0], wdaPort: 8100 + i, thread: i + 1}}
      devices = devs.map {|x| x.merge(get_android_device_data(x[:udid]))}

      ENV['DEVICES'] = JSON.generate(devices)
      puts 'Android devices'
      puts devices
      devices
    end

    def get_android_device_data(udid)
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
