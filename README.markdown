Libisi (c) Logintas AG

= Quickstart

Console:

  gem install libisi
  apt-get install liblog4r-ruby, libruby1.8, libprogressbar-ruby1.8, libcmdparse-ruby

Your script test.rb:

  #!/usr/bin/ruby
  require "libisi"
  init_libisi(:ui => "console")
  
  args = optparse(:arguments => [["USERNAME","Please provide your username"]])
  
  $log.info("Started")
  if $ui.question("Hello #{args[0]}, yes or now?", :default => true)
    $log.info("You selected yes")

    $ui.progress_bar("Items",["a","b","z"]) {|v|
      if $ui.progress_bar_enabled?
        # print in progressbar
        $ui.progress_message("Processing item: #{v}")
      else
        # print item to console
        p v
      end
      sleep 1
    }

  else
    $log.warn("You selected no!")
  end 
  
  exit 0

try:
  ruby test.rb -h
  ruby test.rb SOMENAME
  ruby test.rb --progress SOMENAME
  ruby test.rb -v SOMENAME
  ruby test.rb -vv SOMENAME

= Requirements

To use the base functionality, these packages are required
on debian systems:
* liblog4r-ruby, libruby1.8, libprogressbar-ruby1.8, libcmdparse-ruby

For additionaly functionalities install these packages:
* libtmail-ruby1.8,libtext-format-ruby1.8

For generating charts:
* libjfreechart-java

== Usage

=== Initialize

  #!/usr/bin/ruby
  require 'libisi'
  init_libisi(:ui => "console")

= Standard commandline options =
Parse the commandline options with:

  args = optparse {|o|
  
    # additional options  
    o.on("-d", "--doit","Do something.") do
      # if you get here the option --doit is given
      # if mutliple -d exist this will be executed
      # multiple times
    end
  
    o.on("-c","--config <file>") do |config_file|
      # config_file is the given argument
      ...
    end
  }

For more information see: http://cmdparse.rubyforge.org

=== Logging

For addidtional information on Log4r see
 /usr/share/doc/liblog4r-ruby1.8/html/index.html
or libisi.rb source code how this library is used.

Commandline options added to script:
  "-q","--quiet"
  "-v","--verbose"

==== Usage
Simple logging mechanism. Try to aviod 
normal brackets. If you use a block like
$log.info{"Something"} the block will not
be evaluated if the log level is not enabled.

  $log.warn{"Log"} 
  $log.debug("abcd") if $log.debug?
  # same as
  $log.debug{"abcd"}

Default Logging is only to stdout.

=== Additional Loggers

Normal logger with levels from INFO to FATAL.
  new_logger("archivlog", "/var/log/archive", :level => Logger::INFO)

Logger that only logs Level SKIPPED.
  new_logger("only_debug", "/var/log/debugonly", :only => Logger::SKIPPED)

Logger that only logs Level DEBUG with another pattern
  new_logger("other_format", "/var/temp/debugging", :only => Logger::DEBUG, :pattern => "%d: %m")

For more information on pattern see:
  /usr/share/doc/liblog4r-ruby1.8/html/rdoc/files/log4r/formatter/patternformatter_rb.html

== More Loglevels

Log with other level, add option :log_levels to initialization.
  init_libisi(:log_levels => [:CONFIG, :DEBUG, :INFO, :NEW_LEVEL, :WARN, :ERROR, :FATAL])

=== Display Progressbars (console)
Command line options added by script:
  "--progress"

If progress is enabled (--progress given on commandline):
  $ui.progress_bar_enabled?

Or you can enable/disable progress_bar with
 $ui.enable_progress_bar
respectively
 $u.enable_progress_bar(false)

=== Display Progressbar
Only if --progress is given on commandline.

  progress_bar("Myprogress", amount_of_objects) {
    ...
    # increment the progressbar by 1
    pinc
    ...
  }

=== Display Status Information
You also can display status information
on the bottom of the progressbar by using

  pinc("Processing")
  # or
  pinc("Processing", object.name)

or simply set the message without increment
the progress with:
  pmsg("Processing", object.name)


= Appendix

Sources:
* URL: https://github.com/fpellanda/libisi
* Repository: git@github.com:fpellanda/libisi.git

Links:
* Rubygems: https://rubygems.org/gems/libisi
* Rubyforge: http://rubyforge.org/projects/libisi/

Release:
* gem install echoe rubyforge
* rake manifest
* rake release
* rake publish_docs