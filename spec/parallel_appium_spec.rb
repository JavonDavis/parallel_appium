RSpec.describe ParallelAppium do
  it 'has a version number', ios: true, android: true do
    expect(ParallelAppium::VERSION).not_to be nil
  end

  it 'successfully execute emulator command' do
    ENV['THREADS'] = '1'
    expect(ParallelAppium::Android.new.start_emulators.size).to equal 1
    ENV['THREADS'] = nil
  end

  it 'starts correct number of Android emulators' do
    ENV['THREADS'] = '2'
    expect(ParallelAppium::Android.new.devices.size).to equal 2
    ENV['THREADS'] = nil
  end

  it 'get\'s default number of iOS devices' do
    ENV['THREADS'] = nil
    expect(ParallelAppium::Server.new.get_devices('ios').size).to equal 1
  end

  it 'get\'s specified number of possible iOS devices' do
    ENV['THREADS'] = '3'
    expect(ParallelAppium::Server.new.get_devices('ios').size).to equal 3
    ENV['THREADS'] = nil
  end
end
