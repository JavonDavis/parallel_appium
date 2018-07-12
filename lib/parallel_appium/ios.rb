module ParallelAppium
  # Connecting to iOS devices
  class IOS

    def initialize
      # Get available simulators
      @simulators = `instruments -s devices`.split("\n").reverse
    end

    # Filter simulator data
    def simulator_information
      re = /\([0-9]+\.[0-9](\.[0-9])?\) \[[0-9A-Z-]+\]/m

      # Filter out simulator info for iPhone platform version and udid
      @simulators.select { |simulator_data| simulator_data.include?('iPhone') && !simulator_data.include?('Apple Watch') }
                 .map { |simulator_data| simulator_data.match(re).to_s.tr('()[]', '').split }[0, ENV['THREADS'].to_i]
    end

    # Devices after cleanup and supplemental data included
    def devices
      devices = []
      simulator_information.each_with_index do |data, i|
        devices.push(name: @simulators[i][0, @simulators[i].index('(') - 1], platform: 'ios', os: data[0], udid: data[1],
                     wdaPort: 8100 + i + ENV['THREADS'].to_i, thread: i + 1)
      end
      ENV['DEVICES'] = JSON.generate(devices)
      devices
    end
  end
end

