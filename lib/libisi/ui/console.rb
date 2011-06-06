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

require "libisi/ui/base.rb"
class ConsoleUI < BaseUI
  def bell(options = {})
    print "\007"
  end
  def info(text, options = {})
    bell
    print "#{text} [hit ENTER]"
    STDIN.readline
  end
  def info_non_blocking(text, options = {})
    print("#{text}\n")   
  end
  def question(text, options = {})
    default = nil
    unless options[:default].nil?
      default = (options[:default] ? "y" : "n")
    end    
    
    while true
      case default
      when "y"
	print(text + "(Y/n)")
      when "n"
	print(text + "(y/N)")
      else
	print(text + "(y/n)")
      end
      answer = STDIN.readline.to_s.strip.downcase
      answer = default if answer == ""
      case answer
      when "y"
	return true
      when "n"
	return false
      end
    end
  end
  
  def password(text)
    begin
      print "#{text}: "
      system "stty -echo"    
      pw = STDIN.gets.chomp
      print "\n"
    ensure
      system "stty echo"
    end
    pw
  end

  # TEXT UI
  def select(list, multi_select = false, options = {})
    texts = []
    list.each_with_index {|val, index|
      if block_given?
	item_text = yield(val)
      else
	item_text = val.to_s
      end
      if item_text.include?("\n")
	item_text = item_text.split("\n").map {|l| "  #{l}"}.join("\n")
      end
      print "#{index + 1}: #{item_text}\n"
      texts << item_text
    }

    ret = nil
    while ret.nil?
      begin
	if multi_select
	  print "Please make your choice. (Comma seperated list or 'all' for all.)\n"
	else
	  print "Please make your choice:"
	end
	select = STDIN.readline

	if select.strip == "all" or select.strip == "a"
	  indexes = (0..(list.length-1)).to_a
	else
	  values = select.split(",").map {|s| s.strip}

	  indexes = values.map {|n| n.strip}.map {|sel| sel.to_i - 1}.sort.uniq
	  indexes = indexes.select {|i| i>=0 }

	  if indexes.length < values.length
	    indexes = values.map {|s| texts.index(s) }.compact.sort.uniq	   
	  end
	  
	  raise "Not all values could be found!" if indexes.length < values.length	  
	end
	ret = indexes.map {|sel|
	  raise "Unexpected input, please enter a number!" if sel < 0
	  raise "Item with index '#{sel + 1}' not found." unless list[sel]
	  list[sel]
	}
	  
	if ret.length > 1 and !multi_select
	  raise "Only one item allowe"
	end   
      rescue
	print "#{$!}\n"
	ret = nil
      end   
    end
    return indexes if options[:return_indexes]      
    ret
  end

  CONSOLE_COLOR_STRINGS = {
    :gray   => [1,30], :black       => [30],
    :light_red    => [1,31], :red    => [31],
    :light_green  => [1,32], :green  => [32],
    :light_yellow => [1,33], :yellow => [33],
    :light_blue   => [1,34], :blue   => [34],
    :light_purple => [1,35], :purple => [35],
    :light_cyan   => [1,36], :cyan   => [36],
    :white  => [1,37], :light_gray  => [37],
    :underscore => [4],
    :blink => [5],
    :inverse => [7],
    :concealed => [8],
    :default => [0]
  }
  CONSOLE_COLORS = CONSOLE_COLOR_STRINGS.keys
   
  def test_colors
    CONSOLE_COLORS.sort_by{|n| n.to_s}.each {|color|
      print "#{color}: " + colorize(color) { "****" } + "\n"
    }
  end

  def console_commands(commands) ; commands.map {|number| "\e[#{number}m"}.join ;end

  def colorize(color)
    unless defined?(@support_colors)
      res = %x{/usr/bin/tput colors 2> /dev/null}
      @support_colors = (($? == 0) and !(res =~ /-1/))
      $log.debug("Terminal supports colors: #{@support_colors} (#{res.inspect}, #{ENV["TERM"].inspect})")
    end
    return yield unless @support_colors

    raise "Unexpected color: #{color}" unless CONSOLE_COLORS.include?(color)    
    console_commands(CONSOLE_COLOR_STRINGS[color]) +
      yield +
      console_commands(CONSOLE_COLOR_STRINGS[:default])
  end

  def progress_bar_implementation(text,total)
    ret = nil
    begin
      require "progressbar"
      @pbar = ProgressBar.new(text, total)
      #      $pbar.format = "%-#{title.length+10}s %3d%% %s %s"
      ret = yield
      pmsg
      @pbar.finish
      @pbar = nil
    ensure
      if @pbar
	@pbar.halt
	@pbar = nil
      end
    end
    ret
  end
  def progress(count)
    @pbar.set(count) if @pbar
  end

  def progress_message(message)
    return unless @pbar
    width = (@pbar.instance_eval("get_width")) - 6
    if message.length > width then
      message = message[0..(width/2)] + ">..<" + message[-(width/2)..-1]
    end
    
    STDERR.print("\n")
    STDERR.print("\e[K")
    STDERR.print(message.to_s)
    STDERR.print("\e[#{message.to_s.length}D")
    STDERR.print("\e[1A")
  end
  def progress_inc
    return unless @pbar
    @pbar.inc
  end

  def execute_in_console(command, options = {})
    system(command)
  end

  def shell
    shell_name = "bash"
    print("\nFallen into #{shell_name} shell\n")
    print("(CTRL-D) for exit\n\n")
    system("/bin/#{shell_name} < /dev/tty > /dev/tty 2> /dev/tty")
  end

  def diff(file1, file2, options = {})
    text = result_of_system("diff -r -u '#{file1}' '#{file2}'",true)
    color1 = :green
    color2 = :red
    # additional lines
    text = text.gsub(/^\+.*$/) {|l| colorize(color1) { l }}
    # removed lines
    text = text.gsub(/^\-.*$/) {|l| colorize(color2) { l }}
    print text
    $?.success?    
  end
  
# single character input  
#       require 'termios'
#     
#     # Set up termios so that it returns immediately when you press a key.
#     # (http://blog.rezra.com/articles/2005/12/05/single-character-input)
#     t = Termios.tcgetattr(STDIN)
#     t.lflag &= ~Termios::ICANON
#     Termios.tcsetattr(STDIN,0,t)
#     c = ''
#     while c != 'q' do
#       c = STDIN.getc.chr
#       puts "You entered: " + c.inspect
#     end


end

