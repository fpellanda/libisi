# Copyright (C) 2007-2010 Logintas AG Switzerland
#
# This file is part of Libisi.
#
# Libisi is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Libisi is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Libisi.  If not, see <http://www.gnu.org/licenses/>.

require "libisi/base.rb"
require "log4r"
require 'log4r/configurator'

class Log < Base
  LOG_FORMAT = "[%l] %d :: %m"
  PRINT_DEBUG = false

  def self.output_types
    {"log" => ["err","error","debug","dbg","log"]}
  end
  
  def self.create_output(type, ending, file)
    name = file.basename.to_s
    case ending
    when "err","error"
      new_logger(name, file.to_s, :level => Logger::ERROR)
    when "debug","dbg"
      new_logger(name, file.to_s, :level => Logger::DEBUG)
    when "log"
      new_logger(name, file.to_s, :level => stdout_log_level)
    else
      raise "Unexpected ending #{ending}"
    end
  end  
  
  
  def self.redefine_logger(options)
    options[:redefine] ||= true    
    init(options)
  end
  
  def self.normalize_level(level)
    level = level.to_s if level.class == Symbol
    level = case level
    when String, Symbol
      Log4r.const_get(level.to_s.upcase)
    when Fixnum
      level
    when NilClass
      nil
    else
      raise "Unexpected log level class #{level.class} #{level.inspect}"
    end
    print "Normalized log level is #{level}\n" if PRINT_DEBUG
    level
  end

  def self.init(options = {})
    #raise "Logging already initialized" if $log and !options[:redefine]
    $log.debug("Redefine logger #{options.inspect}") if $log
    
    #    if defined?(RAILS_DEFAULT_LOGGER) and !options[:output]      
    #      logfile = RAILS_DEFAULT_LOGGER.instance_eval("@log")
    #      raise "Cannot handle rails log destination #{logfile.class}" unless
    #	logfile.class == File
    #      RAILS_DEFAULT_LOGGER.info("Going to replace RAILS_DEFAULT_LOGGER by libisis own logger")    
      #      options[:output] ||= logfile
    #    end
    
    case options[:logging]
    when nil, "Log4r", "log4r"
      require "log4r"
      
      # Initialize base logging
      Log4r::Configurator.custom_levels(*options[:log_levels]) if options[:log_levels] and !options[:redefine]
      # we need this to that log levels are initialized
      Log4r::Logger.new("default")
      
      options[:level] ||= (self.log_level_name or
			   (defined?(LOG_LEVEL) and LOG_LEVEL) or
			   ENV["LOG_LEVEL"] or "warn")
      options[:level] = normalize_level(options[:level])
      
      # new version: default_output = $environment.default_log_output
      default_output = :stdout
      options[:output] = nil if (options[:output].class == Array and options[:output].length == 0)
      options[:output] ||= ((defined?(LOG_OUTPUT) and LOG_OUTPUT) or
			    ENV["LOG_OUTPUT"] or 
			    default_output)
      options[:output] = :stdout if options[:output] == "stdout"
      options[:output] = [options[:output]] if options[:output].class != Array
      
      $log.debug{"Create new logger now with Updated options: #{options.inspect}"} if $log
      
      if !options[:redefine] or $log.nil? # new version: or $log.class == Libisi::Logging::FunctionCallLogger
	$log = Log4r::Logger.new((ENV["PROGRAM_IDENT"] or "default"))
      else
	#$log.instance_variable_set("@outputters",[])
	#$log.outputters.each {|o| $log.remove(o.name)}
	$log.outputters = []
	raise "Still outputters, maybe /usr/lib/ruby/1.8/logger.rb loaded" if $log.outputters.length != 0
	@outputs = []
      end
      
      options[:output].each_with_index {|output, i|
	new_logger("default#{i}", (output or :stdout), options)
      }
    else
      raise "Unexpected logging mode #{options[:logging]}"
    end
    
      
    self.log_level = options[:level]
    $log.debug("Logging initialized #{options.inspect}")
    $log.outputters.each {|o| $log.debug("Outputter: #{o.inspect}") } if $log.debug?   
  end

  def self.outputs; @outputs or []; end
  def self.new_logger(name, output, options = {})
    raise "No outputter given." unless output
    new_outputters = []
    case output
    when String, Pathname
      new_outputters << Log4r::FileOutputter.new(name,:filename => output.to_s)
    when :stdout
      $stdout_logger||= Log4r::Outputter.stdout
      $stderr_logger||= Log4r::Outputter.stderr
      new_outputters << $stdout_logger
      new_outputters << $stderr_logger
    when :stderr
      $stderr_logger||= Log4r::Outputter.stderr
      new_outputters << $stderr_logger      
    when Hash
      raise "unexpected output type #{output.inspect}"
    else
      new_outputters << Log4r::IOOutputter.new(name, output)
    end
    
    pattern = Log4r::PatternFormatter.new(:pattern => (options[:pattern] or LOG_FORMAT))
    
    new_outputters.each_with_index {|out,i|
      raise "Outputter #{i} is nil" unless out
      old_len = $log.outputters.length
      $log.add(out)
      raise "No outputter added, maybe /usr/lib/ruby/1.8/logger.rb loaded" unless $log.outputters.length == (old_len + 1)
      @outputs ||= []
      @outputs << output
      out.formatter = pattern
      
      #normalize option
      options[:only] = normalize_level(options[:only])
      options[:level] = ((normalize_level(options[:level]) or $log.level))

      # stderr level is always error
      # and already defined
      if output == :stdout
	next if out == $stderr_logger
	raise "Only log level not allowed for :stdout" if options[:only]
	self.stdout_log_level = options[:level]
	next
      end
      
      if options[:only]
	out.only_at(options[:only]) 
	$log.level = options[:only] if $log.level > options[:only]
      end
      if (options[:level])
	out.level = options[:level]
	$log.level = options[:level] if $log.level > options[:level]
      end
    }    
    
    print "Added new logger at #{output.inspect} (#{options.inspect})\n" if PRINT_DEBUG
    $log.debug{"Added new logger at #{output.inspect} (#{options.inspect})"}
  end
  
  # LOGGING LEVELS
  def self.log_level=(level)
    $log.debug("Setting log_level #{level} (DEBUG is #{Log4r::DEBUG})")
    
    $log.level = level
    $log.outputters.each {|o|
      next if o == $stdout_logger or o == $stderr_logger
      o.level = level
    }
    self.stdout_log_level = level if $stdout_logger
    @log_level = level
    print "Log level is now #{$log.level} (set #{level})\n" if PRINT_DEBUG
    $log.debug("Log level is now #{log_level_name}")
  end
  def self.log_level
    @log_level ||= Log4r::WARN
    @log_level
  end
  def self.log_level_name
    return nil unless self.log_level
    return nil unless defined?(Log4r::LNAMES)
    Log4r::LNAMES[self.log_level]
  end
  
  def self.stdout_log_level
    self.log_level
  end
  def self.stdout_log_level=(level)
    return unless outputs.include?(:stdout)
    print "set stdout level #{level} debug is: #{Log4r::DEBUG}\n" if PRINT_DEBUG
    print "stdout_err_level: #{$stderr_logger.level}\n" if PRINT_DEBUG
    print "stdout_log_level: #{$stdout_logger.level}\n" if PRINT_DEBUG    
    $stderr_logger.level = Log4r::ERROR
    print "stderr_level: #{$stderr_logger.level}\n" if PRINT_DEBUG
    
    raise "Level #{level} is too verbose" if level == 0
    raise "Level #{level} is too quiet" if level >= Log4r::LEVELS - 2
    if level >= (Log4r::LEVELS - 3)
      $log.debug("Removing stdout logger")
      $log.remove($stdout_logger.name)
      print "removed stdout_logger\n" if PRINT_DEBUG
    else
      unless $log.outputters.include?($stdout_logger)
	print "Added stdout_logger\n" if PRINT_DEBUG
	$log.add($stdout_logger) 
      end
      levels = (level..Log4r::LEVELS-4).to_a
      print "Stdout levels: #{levels.inspect}\n" if PRINT_DEBUG
      $stdout_logger.only_at(*levels)
    end
  end  
  
end
