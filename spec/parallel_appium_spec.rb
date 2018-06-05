RSpec.describe ParallelAppium do
  it 'has a version number' do
    expect(ParallelAppium::VERSION).not_to be nil
  end

  it 'get\'s default number of iOS devices' do
    expect(ParallelAppium::SeleniumGrid.get_devices('ios').size).to equal 1
  end

  it 'get\'s specified number of possible iOS devices' do
    ENV['THREADS'] = '3'
    expect(ParallelAppium::SeleniumGrid.get_devices('ios').size).to equal 3
    ENV['THREADS'] = nil
  end
end
