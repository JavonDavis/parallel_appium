# parallel_appium

Single/Distributed Parallel Cross-Platform mobile testing in Appium and RSpec for Android and iOS.

This project acts as a wrapper around a number of the configurations that have to be in place for 
running appium tests with RSpec. 

The Gem:

* Handles single platform testing 
* Does cross-platform testing in Parallel
* Distributes tests across multiple simulator instances for a platform

Using the gem will speed up the time your entire test suite takes to execute and reducing your 
project size by packaging a lot of code that is not context-specific. 

This project depends on [Appium](http://appium.io/), please ensure you've installed and configured Appium
correctly before trying to work with this gem. [Appium Doctor](https://github.com/appium/appium-doctor) is a good way to
ensure you're good to go here

## Sample Project

To better demonstrate how to use the gem, a project automating Wordpress's mobile apps
is presented [here](https://github.com/JavonDavis/Wordpress-Open-Source-Automation-Ruby).

This project shows hands on how to integrate the gem and what it can do.

## Installation

Add this line to your application's Gemfile:

```
gem 'parallel_appium'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install parallel_appium
    
## Getting setup

## Android

The gem uses the emulator command line tool that comes with your Android installation to manage a number of things. This
however requires a bit of configuration to work properly as by default it's not added to the system path and it's usually
not pointing to the correct one. Adding something like this(**in the specified order**) in your bash_profile will resolve
this 

```
export ANDROID_HOME=/<path>/to/Android/sdk
export ANDROID_AVD_HOME=~/.android/avd
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/tools:$PATH
export PATH=$ANDROID_HOME/tools/bin:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH
```

## iOS

The main requirement here is to be running on a MAC machine, otherwise, there's nothing extra to do here
all the requirements for Appium and iOS hold true. 

### Additional check

I also recommend an additional check to see if you're good to go for this project, simply execute

```bundle install --path vendor```

and then 

```bundle exec rake parallel_appium:validate_android``` for Android

or

```bundle exec rake parallel_appium:validate_ios``` for iOS


The messages will indicate if there's any component necessary for the platform that's still not set up as yet.


## Usage

To get started with this gem in a project there's 3 lines of code you'll need to know to include within your project.
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

When distributing tests across multiple devices the library spreads the specs across multiple threads and depends on the
UDID environment variable to know which device it's working with for the specific test file, as such this will need to 
be setup in each test file, simply include the following line of code at the top of the test file after any dependencies 
and the library will set this up as needed,

```ParallelAppium::Server.new.set_udid_environment_variable```

This is all you need to get started with this library. There's a number of environment variables set by the library
for the purpose of writing easier cross platform tests. These are described in more detail below.


--------

Next you'll need to ensure the project the respective appium text files for the platform, 
the gem will be looking for these files in the Project root. This file is used to load the capabilities of the driver
at launch.

Here's examples of what both could look like 

### appium-ios.txt

```
[caps]
platformName = "ios"
deviceName = "iPhone Simulator"
platformVersion = "11.4"
app = "./apps/WordPress.app.zip"
automationName = "XCUITest"
bundleId = "org.wordpress"

[appium_lib]
wait = 2
```

### appium-android.txt

```
[caps]
platformName = "android"
deviceName = "Android Emulator"
platformVersion = "8.1.0"
app = "./apps/WordPress.apk"
appActivity = "org.wordpress.android.ui.WPLaunchActivity"
appPackage = "org.wordpress.android"

[appium_lib]
wait = 2
```

The vales are expected to change to tailor to the host machine.

### Environment variables


### Tags



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/JavonDavis/parallel_appium. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html).

## Code of Conduct

Everyone interacting in the ParallelAppium project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/JavonDavis/parallel_appium/blob/master/CODE_OF_CONDUCT.md).
