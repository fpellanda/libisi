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

require "open3"
require "ordered_hash"

module LibIsi
  
  LOG_FORMAT = "[%l] %d :: %m"
  LIBISI = true
  def init_libisi(options = {})
    require "date"
    require "time"
    require "fileutils"
    require "pathname"
    require "libisi/doc"
    require "libisi/log"    
    require "libisi/uri"
    
    Log.init(options) unless options[:no_logging]
    initialize_ui(options) unless options[:no_ui]
    initialize_environment(options) unless options[:no_environment]
    initialize_mail(options) unless options[:no_mail]
    Doc.init(options) unless options[:no_doc]
    Uri.init(options) unless options[:no_uri]
  end

  # Mail
  def initialize_mail(options)
    # there is no ohter implementation yet
    raise "Mail already initialized" if $mail
    require "libisi/mail/tmail"
    $mail = TMailMail.new
  end

  # UI
  def initialize_ui(options)
    raise "UI already initialized" if $ui
    
    if options[:ui]
      @ui_overwritten = true
      ui = options[:ui]
    else
      ui = ((rails_available? and "rails") or
	    (kde_available? and "kde") or
	    (x_available? and "x11") or
	    (terminal_available? and "console") or
	    "nobody")
    end
    change_ui(ui)
  end 
  def change_ui(ui)
    ui = ui.to_s
    raise "Hacking attack!!" unless ui.class == String
    raise "Unexpected UI name #{ui}." unless ui =~ /^[a-zA-Z][a-zA-Z0-9]*$/
    require "libisi/ui/#{ui}.rb"
    klass = eval("#{ui.capitalize}UI")
    $ui = klass.new
  end
  def kde_available?
    return false unless ENV["KDE_FULL_SESSION"] == "true"
    unless system("ps aux | grep -v grep | grep kded > /dev/null")
      $log.warn("kded not running but kde seems to be available. Executing kded --new-startup.")
      return false unless system("kded --new-startup")
    end
    true
  end
  def x_available?
    if ENV["DISPLAY"]
      unless Pathname.new("/usr/bin/xvinfo").exist?
	$log.debug("xvinfo not available => return x_available: false")
	return false 
      end
      system("xvinfo 2>/dev/null 1> /dev/null")
      return true if $?.exitstatus != 255
      $log.warn("DISPLAY set to #{ENV["DISPLAY"]} but cannot access X.")
    end
    false
  end
  def terminal_available?
    ENV["TERM"]
  end

  # OUTPUT
  def add_output(file)
    unless Log.output(file) or
	Doc.output(file)
      raise "No outputter found for #{file}"
    end
  end
  

  # LOG
  def new_logger(name, filename, options = {})
    # function now in Log class
    Log.new_logger(name, filename, options)
  end

  # ENVIRONMENT
  def initialize_environment(options)
    "Could not parse caller main script: #{caller[-1]}" unless caller[-1] =~ /(.*)\:\d+/
    ENV["main_script"] = $1
    raise "Main script '#{ENV["main_script"]}' not found." unless main_script.exist?

    ENV["PROGRAM_NAME"] = program_name
    ENV["PROGRAM_IDENT"] = program_name
    ENV["TODAY"] = DateTime.now.strftime("%F")
    require 'socket'
    ENV["HOST"] = open("|hostname") {|f| (f.readlines[0] or "").strip}
    ENV["NET"] = open("|hostname -d") { |f| (f.readlines[0] or "").strip  }
    ENV["USER"] = open("|whoami") {|f| f.readlines[0].strip}
    ENV["STARTDATETIME"] = DateTime.now.strftime("%F-%T")
    # Set directory for temporary files
    ENV["TMPDIR"] ||= "/var/tmp"
    # output of compress and zip programs
    # must be in english to work correctly
    ENV["LANGUAGE"] = "en_US.UTF-8"

    # set benchmarking if defined on evironment 
    if ENV["BENCHMARK"] or ENV["BENCHMARKINK"]
      self.benchmarking = true
    end

    #Catch & log unhandled exceptions        
    at_exit {
      if self.profiling
        profiling_stop
      end

      begin
	pid_file.delete if pid_file.exist?
      rescue
	$log.error("Could not remove pid file #{pid_file}: #{$!}") if $log
      end

      unless $! .class == SystemExit or $!.nil? 
	$log.fatal("#{$!.class.name}: #{$!.to_s}") 
	$@.each {|l| $log.debug{l} } if $log.debug?

	# exit immediately
	exit! 99
      end
    }

    # add lib directory if parent directory of
    # source script has a lib directory
    libdir = Pathname.new(ENV["main_script"]).dirname.parent + "lib"
    $LOAD_PATH.insert(0, libdir.to_s) if libdir.exist?      
  end
  
  def program_name; main_script.basename.to_s; end
  def program_instance; ENV["PROGRAM_INSTANCE"]; end
  def program_instance=(inst); ENV["PROGRAM_INSTANCE"] = inst; end
  def main_script; Pathname.new(ENV["main_script"]); end
  def user; ENV["USER"];  end
  def full_qualified_domainname; "#{ENV["HOST"]}.#{ENV["NET"]}"; end
  def host_name; "#{ENV["HOST"]}"; end  
  
  def paths
    "Could not parse caller: #{caller[-1]}" unless caller[-1] =~ /(.*)\:\d+/
    calling_file = Pathname.new($1).cleanpath
    all_paths = {
      :rails => {
	:config => Pathname.new("config"),
	:binary => Pathname.new("script"),
	:lib => Pathname.new("lib")
      },
      :debian => {
	:data => Pathname.new("/usr/share"),
	:config => Pathname.new("/etc"),
	:binary => Pathname.new("/usr/bin"),
	:lib => Pathname.new("/usr/lib/ruby/1.8"),
      },
      :setup => {
	:data => Pathname.new("data"),
	:config => Pathname.new("conf"),
	:binary => Pathname.new("bin"),
	:lib => Pathname.new("lib"),
	:test => Pathname.new("test"),
      }
    }
    $log.debug("Calling file: #{calling_file}")
    file_type = all_paths.map {|env, files|
      files.map {|type, path|
	# eliminate overlappings
	next if env == :setup and calling_file.to_s =~ /^\/usr\/bin/
	next if env == :setup and calling_file.to_s =~ /rails/

	next type if calling_file.to_s.starts_with?(path.to_s)
	next type if calling_file.dirname.basename.to_s == path.to_s
      }.compact.map {|type| [env,type]}
    }.flatten
    if file_type.length != 2      
      type = :rails if defined?(RAILS_ROOT)
    else
      type = file_type[0]
    end
    raise "Could not determine caller type #{file_type.inspect} from #{calling_file}" unless type

    ret = all_paths[type].dup
    ret.each {|key,val|
      ret[key] = calling_file.dirname.parent + val
    }	
    return ret
  end

  def with_temp_directory(name = nil)
    dir = Pathname.new("/var/tmp/#{program_name}.#{Process.pid}")
    dir.mkdir
    begin
      FileUtils.cd(dir) {
	begin
	  yield
	rescue
	  if $log.debug? and $ui.respond_to?(:shell)
	    $ui.shell if 
	      $ui.question("Error ocurred in temporary directory #{dir}\nError: #{$!.to_s}\nDo you want a shell, before removing directory?",:default => false)
	  end
	  raise
	end
      }
    ensure
      dir.rmtree
    end
  end
    
  def temp_file(name = nil)
    if name.nil?
      @temp_file_num ||= -1
      @temp_file_num += 1
      name = @temp_file_num += 1
    end
    temp_files([name]) {|tf|
      yield tf[0]
    }
  end
  def temp_files(*names)
    files = names.map {|n| Pathname.new("/var/tmp/#{program_name}.#{Process.pid}-#{n}") }
    begin
      yield files
    ensure
      files.each {|f|
	f.delete if f.exist?
      }
    end
  end

  # Profile
  def profiling; $profiling; end
  def profiling=(val)    
    $profiling = val
    if self.profiling
      $log.info("Turned on Profiling")
      require "ruby-prof"
      $log.debug("Starting ruby prof")
      RubyProf.start
    else
      $log.info("Turned off Profiling")
    end
  end
  def profiling_stop
    $log.debug("Stopping ruby prof")
    result = RubyProf.stop
    
    path = Pathname.new(self.profiling)
    raise "Profile path disappeared: #{path}" unless path.exist?
    
    {RubyProf::FlatPrinter => ".txt",
      RubyProf::GraphPrinter => ".txt",
      RubyProf::GraphHtmlPrinter => ".html",
      RubyProf::CallTreePrinter => ".txt"}.each {|printer_class, ending|
      printer = printer_class.new(result)
      output_path = path + "RubyProf_#{printer_class.name}#{ending}"
      $log.debug("Writing #{output_path}")
          output_path.open("w") {|profile_out|
        printer.print(profile_out)
      }
    }
    $profiling = false
  end

  # Benchmark
  def benchmarking; $benchmarking; end
  def benchmarking=(val)    
    $benchmarking = val
    $benchmarks = {}
    if self.benchmarking
      Log.log_level = 2 if Log.log_level > 2
      $log.info("Turned on Benchmarking")
    else
      $log.info("Turned off Benchmarking")
    end
  end

  def benchmark(name = nil, options = {})
    return yield unless benchmarking
    require "benchmark"
    ret = nil
    bench = Benchmark.measure {
      ret = yield
    }
    $log.info("Benchmark #{name}: #{bench.to_s}")
    if $benchmarks[name] 
      $benchmarks[name] += bench
    else
      $benchmarks[name] = bench
    end
    ret
  end

  # BASH
  def bash_eval(expr)
    n_expr = "echo #{expr}".inspect
    t_expr = "" 
    in_quotes = false
    n_expr.length.times {|i|
      ch = n_expr[i..i]
      case ch
      when "'"
	in_quotes = !in_quotes
      when "$"
	if in_quotes
	  t_expr += "\\"
	end
      end
      t_expr += ch
      
    }
    n_expr = t_expr  
    cmd = "/bin/bash -c #{n_expr} "
    #  new_expr = "echo '#{expr.gsub("'","\\\\\\\\'")}'"
    #  print "-----" + expr + "\n"
    #  print "-----" + new_expr + "\n"
    #  cmd = "/bin/bash -c #{new_expr}"
    #  print "-----" + cmd + "\n\n"
    ret = open("| #{cmd}") {|b|
      b.readlines.join.strip
    }
    raise "Error during evalating #{expr.inspect}" unless $?.success?
    $log.debug{"bash_eval: #{expr.inspect} => #{ret.inspect}"}  
    ret
  end
  
  def escape_bash(command)
    command.gsub("\\","\\\\").gsub("\"","\\\"").gsub("\$","\\\$")
  end
  def execute_on_remote_command(remote, command)
    return command if remote.nil? or remote == "localhost" or remote == "127.0.0.1"
    command = "ssh -T #{remote} \"#{escape_bash(command)}\""
  end

  def result_of_system(command, error_ok = false)
    $log.debug{"Execute #{command.inspect}"}
    res = open("|#{command}") {|f| f.readlines.join}
    raise "Error executing #{command.inspect}." if !error_ok and !$?.success?
    $log.debug{"Result is #{res.inspect}"}
    res   
  end
  def source(filename)
    $log.debug{"Sourcing file '#{filename}'"}
    open(filename) {|f|
      f.each {|line|
	begin
	  case line 
	  when /^\s*\#/, /^$/
	    # comment or empty
	  when /\s*(\S+)=(.*)/
	    ENV[$1] =  bash_eval($2)
	  else
	    raise "Unexpected line #{line.inspect} in source file '#{filename}'."
	  end
	rescue
	  raise "Could not parse line #{line.inspect}: #{$!}"
	end
      }
    }
  end
  def save_env
    old = {}
    ENV.each {|key,val|
      old[key] = val
    }
    old
  end
  def load_env(new_env = nil)
    raise "Give either a block or a new environment hash, not both." if 
      !block_given? and new_env.nil?
    
    old_env = nil
    if block_given?
      old_env = save_env      
    end

    if new_env
      new_env.each {|key,val|
	ENV[key] = val
      }
      ENV.each {|key,val|
	ENV.delete(key) unless new_env.key?(key)
      }
    end
    
    if block_given?
      result = yield
    end
    
    load_env(old_env) if old_env    
    result
  end
  
  def command_line_parse(str)
    return str if str.class == Array
    quotes = ["\"","\'"]
    regexp = "(" + (quotes.map {|q| Regexp.escape(q) }.map {|q| "\\#{q}\\#{q}|\\#{q}([^#{q}]|\\\\#{q})*[^\\\\]\\#{q}"} + ["\\S+"]).join("|") + ")"
    regexp = Regexp.new(regexp)
    args = str.scan(regexp).map {|arr| arr.compact[0] }
    args.map {|a| 
      if quotes.include?(a[0..0])
	a = a.gsub("\\#{a[0..0]}","#{a[0..0]}")
	a[1..-2]
      else
	a
      end
    }
  end
  
  # PROGRESS BAR
  # functions now in UI 
  def enable_progress_bar(val = true)
    $ui.enable_progress_bar(val)
  end
  def progress_bar_enabled?
    $ui.progress_bar_enabled?
  end
  def progress_bar(title, total, &block)
    $ui.progress_bar(title, total, &block)
  end
  def progress(count)
    $ui.progress(count)
  end
  def pmsg(action = nil,object = nil)
    $ui.pmsg(action, object)
  end
  def pinc(action = nil, object = nil)
    $ui.pinc(action, object)
  end
  
  # SYSTEM CALLS
  def execute_command_popen3(command, input = nil, working_dir = nil, output_file = nil, error_regexps = {})
    raise "Will not execute command, output_file already exist: #{output_file}" if output_file and Pathname.new(output_file).exist? 
    $log.debug{"Executing command with popen3: #{command.inspect}"}
    $log.debug{"Changing to directory '#{working_dir}'"}
    my_logs = []
    error_ocurred = false
    FileUtils.cd((working_dir or ".")) {
      begin	
	popen3_process = Open3.popen3(*command) { |stdin, stdout, stderr|
	  stderrf = Thread.fork {
	    $log.debug{"Forked stderr redirect."}
	    begin
	      while (line = stderr.readline)
		logged = error_regexps.each {|action, regexps|
		  if regexps.each {|r| break if line =~ r }.nil?
		    my_logs.push [action, regexps, line]
		    if action == :print
		      print line
		    else
		      $log.info("#{action}: #{line}")
		    end
		    break
		  end
		}.nil?
		unless logged
		  $log.error("Popen3 output error: #{line.strip}")
		  error_ocurred = true
		end
	      end
	    rescue EOFError, IOError
	      # OK, this happens ;-)
	    rescue
	      $log.error{"Error in forked stderr '#{$!.class}': #{$!}"}
	    end
	    $log.debug{"End of forked stderr redirect."}
	  }
	  stdoutf = Thread.fork {
	    $log.debug{"Forked stdout redirect."}
	    if output_file
	      bsiz = 65536
	      open(output_file, "w") do |o_file|
		begin
		  while (r = stdout.read(bsiz))
		    o_file.write(r)
		  end
		rescue EOFError; 
		  # OK, this happens ;-)
		end
	      end
	    else
	      begin
		while (line = stdout.readline)
		  $log.info(line.strip)
		end
	      rescue EOFError, IOError
		# OK, this happens ;-)
	      rescue
		$log.error{"Error in forked stdout '#{$!.class}': #{$!}"}
	      end
	    end
	    $log.debug{"End of forked stdout redirect."}
	  }
	  
	  begin
	    if input
	      input.each {|f|
		# DEPRECATED 	      next if f == get_config("DIRLIST_ENTRY")
		$log.debug{"Writing #{f.to_s} to stdin"}
		stdin.write("#{f.to_s}\n")
	      }    
	    end
	    stdin.flush
	    stdin.close
	  rescue
	    raise "Error writing to stdin: #{$!}"
	  end
	  $log.debug{Process.pid}
	  $log.debug{"Joining stderr fork."}
	  stderrf.join
	  $log.debug{"Joining stdout fork."}
	  stdoutf.join
	  $log.debug{"All foks exited."}	
	}
	
	raise "Popen3 command execution error." if error_ocurred
	# These checks fail, probably we are too fast.
	# lOutputFile = Pathname.new(lOutputFile.to_s)
	#  raise "command successful but target file does not exist!" if !lOutputFile.exist?
	#  raise "command successful but target file has size 0!" if lOutputFile.size == 0
      rescue
	$log.error{"Error executing #{command.inspect} in #{Dir.pwd}"}
      raise "Error executing popen3 command: #{$!}"
      end
    }
    my_logs
  end

  # OPTPARSE
  def parse_arguments(description, arguments)
    argument_names = description.split(" ")
    params = {}
    argument_names.each_with_index {|an,i|
      optional = false
      if an =~ /\[(.*)\]/
	an = $1
	optional = true
      end
      if an =~ /\{(.*)\}/
	an = $1
	optional = true
	params[an.downcase.to_sym] = arguments[i..-1]
	raise "After {..} argument no more arguments allowed!" if argument_names.length > (i+1)
	break
      end
      raise "Argument #{an} (##{i}) not provided and argument is not optional" unless
	optional or arguments[i]
      params[an.downcase.to_sym] = arguments[i]
    }
    params
  end

  # usage:
  # args = optparse(:arguments => [["ARG1", "Description of arg1"],["ARG2","Desc arg2"]])
  # args: ["bla","bla"...]
  #   or
  # action, args = optparse(:actions => {"action1 ARG1 ARG2 {ARG3}"
  # action: "action1"
  # args: {:arg1 => "bl", :arg2 => "bla"}
  def optparse(options = {})
    require 'optparse'
    pbar = false

    raise "Cannot parse commandline for #{arguments} and #{actions}" if options[:arguments] and options[:actions]
    argument_names = []
    argument_help = nil
    if options[:arguments]
      argument_names = options[:arguments].map{|name,text| name}
      argument_help = options[:arguments]
    end
    if options[:actions]
      argument_names = [options[:actions].keys.map {|k| k.split(" ")[0]}.sort.join("|"), "ARGS"]
      argument_help = options[:actions].map {|a,b| [a,b]}
    end
    
    opts = OptionParser.new do |o|	
      o.banner += "Usage: #{program_name} [options] [--] #{argument_names.join(" ")}\n"
      if argument_help
	o.banner += "\nArguments:\n" 
	width = argument_help.map {|arg, text| arg.length}.max
	argument_help = argument_help.sort_by {|a| a[0]}      
	argument_help.each {|arg, text|
	  o.banner += "   #{arg.ljust(width)} : #{text}\n"
	}
      end

      if block_given?
	yield o
      end

      o.banner += "\nOptions:\n"

      o.on("-Lb","--benchmark","Print out benchmark information on info log") do
	benchmarking = true	
      end

      o.on("-Lp","--profile DIR","Write profiling information to this directory") do |dir|
        self.profiling = dir
      end

      o.on("-q","--quiet","be quiet, print only errors") do 
	  Log.log_level = Log.log_level + 1
      end 
      o.on("-v","--verbose","be verbose") do
	Log.log_level = Log.log_level - 1
      end
      unless @ui_overwritten
	o.on("--ui <kde,console>","Force userinterface") do |ui|
	  change_ui(ui)
	end
      end
      o.on("--progress","Show progress information") do 
	pbar = true
      end
      o.on("-O","--output FILENAME", "Output to the file. Possible endings (#{Doc.output_endings.inspect})") {|f|
	# -O output.text -O output.txt
	# -O output.html -O output.htm
	# mail html output to fpellanda: -O "output.html>flavio.pellanda@logintas.ch"
	add_output(f)
      }
      o.on("-h", "--help", "This help." ) do
	puts o
	exit
      end

    end

    begin
      $log.debug{"Parsing #{ARGV.inspect}"}
      opts.parse!( ARGV )
    rescue => exc
      $log.error("E: #{exc.message}")      
      if $log.debug?
	exc.backtrace.each {|l| $log.debug(l)}
      end
      STDERR.puts opts.to_s
      exit 1
    end
    # must be set after change_ui
    $ui.enable_progress_bar if pbar

    if options[:arguments]
      min_arguments = argument_names.reject{|a| a =~ /^\{|\[/}.length
      raise "Too few arguments provided (#{ARGV.length} for at least #{min_arguments})." if argument_names and ARGV.length < min_arguments
      return ARGV
    end
    if options[:actions]
      if ARGV[0].nil?
	puts opts 
	exit
      end
      action, desc, text = options[:actions].each {|a,t|
	sp = a.split(" ")
	break [ARGV[0],sp[1..-1].join(" "),t] if sp[0].split("|").include?(ARGV[0])
      }
      raise "Action '#{ARGV[0]}' not supported." unless desc
      params = parse_arguments(desc, ARGV[1..-1])
      return [action, params]
    end
    ARGV
  end

  ## instances
  def pid_file
    if program_instance
      Pathname.new("/tmp/#{program_name}-#{program_instance.gsub(/[^a-zA-Z0-9]/,"_")}-#{program_instance.hash.abs}.pid")
    else
      Pathname.new("/tmp/#{program_name.gsub(/[^a-zA-Z0-9]/,"_")}.pid")
    end
  end
  def ensure_script_not_running_already(error_on_concurrent = true)
    if pid_file.exist?
      pid = pid_file.readlines.join.strip.to_i
      $log.debug{"Pid file exist with pid #{pid}."}
      if system("/bin/ps #{pid} > /dev/null")
	name = program_name
	name += " (#{program_instance})" if program_instance
	if error_on_concurrent
	  $log.fatal("#{name} already running (pid:#{pid}).")
	  exit 1
	else
	  $log.info("#{name} already running (pid:#{pid}). Exiting normally.\n")
	  exit 0
	end
      else
	# process not running anymore
	# TODO: this should have level warn, but the pid file is normally not remove properly in current version
	$log.info("Removing #{pid_file} process #{pid} not runnning anymore.")
	pid_file.delete
      end  
    end
    $log.debug{"Creating pid file for process #{Process.pid}"}
    pid_file.open("w") {|f| f.write(Process.pid.to_s) }
  end

  ## KONSOLE
  @konsole = nil
  @libisi_konsole_sessions = {}
  def open_konsole_session(name)  
    @konsole = open("|dcopstart konsole-script").gets.strip unless @konsole
    session = open("|dcop #{@konsole} konsole newSession").gets.strip
    system("dcop #{@konsole} #{session} renameSession #{name}")
    
    @konsole_sessions[name] = session
  end
  
  def send_command(name, command)
    session = @konsole_sessions[name]
    system("dcop #{@konsole} #{session} sendSession \"#{command}\"")
  end

  ## DCOP
  def dcop_media_list
    media = {}
    open("|dcop kded mediamanager fullList") {|f|
      f.readlines.join.split("---\n").map {|e| 
	e.split("\n")
      }
    }.each {|entry|
      name = entry[1]
      media[name] = {}
      #/org/freedesktop/Hal/devices/volume_uuid_02a67e94_d030_4211_8b21_ebf0a517aac5
      media[name][:id] = entry[0]
      # sdd1
      media[name][:name] = name
      #221M Removable Media
      media[name][:description] = entry[2]
      #
      #media[name][] = entry[3]
      #true
      #media[name][] = entry[4]
      #/dev/sdd1
      media[name][:device] = entry[5]
      #/media/user-fpellanda
      media[name][:mount_point] = entry[6]
      #ext3
      media[name][:fs_type] = entry[7]
      #true
      #media[name][] = entry[8]
      #
      #media[name][] = entry[9]
      #media/removable_mounted_decrypted
      media[name][:mime_type] = entry[10]
      #
      #media[name][] = entry[11]
      #true
      #media[name][] = entry[12]
      #/org/freedesktop/Hal/devices/volume_uuid_3eebb364_b2c9_4491_a4a2_04b193fc20ac
      #media[name][] = entry[13]
    }
    media
  end
  def normalize_device_name(name)
    name = case name
	   when /^media:\/(.*)/
	     $1
	   when /^\/dev\/(.*)/
	     $1
	   when /system:\/media\/(.*)/
	     $1
	   else
	     name
	   end
  end
  def dcop_find_media(name)
    name = normalize_device_name
    $log.debug{"Looking for media #{name}"}
    ml = media_list
    $log.debug{"Found medias: #{ml.keys.inspect}"} 
    media = ml[name]
    raise "Media #{name} not found." unless media
    media
  end

  # system
  def daemonize(options = {})
    save_pid = (pid_file.exist? and pid_file.readlines.join.strip.to_i == Process.pid)

    fork and exit
    if options[:pid_file]
      File.open(options[:pid_file],"w") do |f| 
	f << Process.pid
      end
    end
    
    # child becomes session leader and disassociates controlling tty.
    # namely do Process.setpgrp + \alpha.
    Process.setsid
    
    # at here already the child process have become daemon. the rest
    # is just for behaving well.

    # save new pid to pid_file
    pid_file.open("w") {|f| f.write(Process.pid.to_s) } if save_pid

    # there is now no console anymore
    if $ui.name == "ConsoleUI"
      change_ui("nobody")
      ENV.delete("TERM")
    end
    
    # ensure no extra I/O.
    File.open("/dev/null", "r+") do
      |devnull|
      $stdin.reopen(devnull)
      if options[:log_file]
	$stdout.reopen("#{options[:log_file]}.log")
	$stderr.reopen("#{options[:log_file]}.err")
      else
	$stdout.reopen(devnull)
	$stderr.reopen(devnull)
      end
    end   

    # ensure daemon process not to prevent shutdown process.
    Dir.chdir("/")
  end

  # RAILS STUFF  
  def rails_root
    return Pathname.new(RAILS_ROOT) if defined?(RAILS_ROOT)
    return Pathname.new(ENV["RAILS_ROOT"]) if ENV["RAILS_ROOT"]
    return nil unless ENV["main_script"]
    return Pathname.new(FileUtils.pwd) if main_script.basename.to_s == "rake"
    main_script.realpath.dirname + ".."
  end
  def rails_available?
    return false unless rails_root
    (rails_root + 'config/boot.rb').exist? and
      (rails_root + 'config/environment.rb').exist?
  end

  # include in boot:
  # unless defined?(LIBISI)
  #   require 'libisi'
  #   init_libisi
  #   require "libisi/color"
  #   Doc.change("html", :doc_started => true)
  # end
  # or in script:
  #  initialize_rails
  def initialize_rails
    raise "Rails not available." unless rails_available?
    # add this to load path to avoid real logger.rb class
    # to be loaded
#    $LOAD_PATH.insert(0, "/usr/lib/ruby/1.8/libisi/fake_logger/")

    $log.debug{"Starting rails environment."}
    require rails_root + 'config/boot'
    require rails_root + 'config/environment'
    $log.debug{"Rails environment started."}
  end

end

# from activesupport-1.3.1/lib/active_support/core_ext/enumerable.rb
module Enumerable 
  def group_by
    inject({}) do |groups, element|
      (groups[yield(element)] ||= []) << element
      groups
    end
  end

  def group_bys(*args)
    if args[-1].class == Hash
      options = args[-1]
      functions = args[0..-2]
    else
      options = {}
      functions = args
    end

    of = ((options[:order_functions] and options[:order_functions][0]) or
	  lambda {|e| 
	    if e.respond_to?(:"<=>") then
	      e
	    else
	      e.to_s
	    end
	  }
	  )

    if (gf = functions[0])
      unordered = self.group_by(&gf)            
      # TODO: Would be good but problems with base table
      #res = OrderedHash.new
      res = []
      begin
        ordered_keys = unordered.keys.sort_by{|k| of.call(k)}
      rescue
        $log.warn("Error ocurred sorting keys: #{$!}!")
        ordered_keys = unordered.keys
      end

      ordered_keys.each {|key|
	# TODO: Would be good but problems with base table
	#res[key] = unordered[key].group_bys(*functions[1..-1])
	res << [key, unordered[key].group_bys(*functions[1..-1])]
      }
      
    else
      res = self
    end
    
    res
  end

end

class String
  def starts_with?(other)
    self[0..(other.length-1)] == other
  end
end

include LibIsi
