# parallel_appium

Distributed mobile testing in Appium

## Installation

Add this line to your application's Gemfile:

```
gem 'parallel_appium'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install parallel_appium

## Usage

To use the gem properly there's 3 lines of code you'll need to know to include within your project.
These lines handle the following.

### Starting the servers

The library at the moment doesn't offer the ability to connect to existing appium processes and instead 
starts appium servers and the selenium grid server as needed. The following line of code is what you'll need to include
for the library to handle this,

```ParallelAppium::ParallelAppium.new.start platform: platform, file_path: file_path```

where platform is either android, ios or all and file_path is the absolute path to the folder or spec file 
to be executed. 

### Initializing the appium instance(s)

As expected each appium instance will need to be loaded with capabilities defining all kinds of important things 
about how the tests executing on that instance will work, hence this will need to be done before the tests begin
it's best to put this in some form of 'before all' block that will execute it prior to all the tests executing.

The following line of code is an example of what you'll need to use

```ParallelAppium::ParallelAppium.new.initialize_appium platform: ENV['platform']```

The initialize_appium function can take two parameters

1. platform - If provided it will look for a appium-{platform}.txt file in the root of the project and load capabilities
from that location.
2. caps - The capabilities as a map to be loaded. 

### Setting UDID for the test

When distributing tests across multiple devices the library spreads the tests across multiple threads and depends on the
UDID environment variable to know which device it's working with for the specific test file, as such this will need to 
be setup in each test file, simply include the following line of code at the top of the test file after any dependencies 
and the library will set this up as needed,

```ParallelAppium::Server.new.set_udid_environment_variable```

This is all you need to get started with this library. There's a number of environment variables set by the library
for the purpose of writing easier cross platform tests. These are described in more detail below.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/JavonDavis/parallel_appium. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html).

## Code of Conduct

Everyone interacting in the ParallelAppium project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/JavonDavis/parallel_appium/blob/master/CODE_OF_CONDUCT.md).
