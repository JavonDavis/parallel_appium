RSpec.describe ParallelAppium do
  it 'has a version number' do
    expect(ParallelAppium::VERSION).not_to be nil
  end

  it 'get\'s possible iOS devices' do
    expect(ParallelAppium::SeleniumGrid.ios_devices).not_to be nil
  end
end
