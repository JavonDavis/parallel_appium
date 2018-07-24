module ParallelAppium
  # Connecting to Android devices
  class Android
    # Fire up the Android emulators
    def start_emulators
      emulators = `emulator -list-avds`.split("\n")
      emulators = emulators[0, ENV['THREADS'].to_i]
      Parallel.map(emulators, in_threads: emulators.size) do |emulator|
        spawn("emulator -avd #{emulator} -no-snapshot-load -scale 100dpi -no-boot-anim -no-audio -accel on &", out: '/dev/null')
      end

      emulators
    end

    # Get additional information for the Android device with unique identifier udid
    def get_android_device_data(udid)
      specs = { os: 'ro.build.version.release', manufacturer: 'ro.product.manufacturer', model: 'ro.product.model', sdk: 'ro.build.version.sdk' }
      hash = {}
      specs.each do |key, spec|
        value = `adb -s #{udid} shell getprop "#{spec}"`.strip
        hash.merge!(key => value.to_s)
      end
      hash
    end

    # Devices after cleanup and supplemental data included
    def devices
      emulators = start_emulators
      sleep 10
      devices = `adb devices`.split("\n").select { |x| x.include? "\tdevice" }.map.each_with_index { |d, i| {avd: emulators[i], platform: 'android', name: 'android', udid: d.split("\t")[0], wdaPort: 8100 + i, thread: i + 1} }
      devices = devices.map { |x| x.merge(get_android_device_data(x[:udid])) }

      ENV['DEVICES'] = JSON.generate(devices)
      devices
    end
  end
end