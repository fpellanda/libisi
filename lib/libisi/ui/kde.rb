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
class KdeUI < BaseUI
  def kdialog(option, text)
    $log.debug("Kdialog: #{option.inspect} #{text.inspect}")
    ret = system("kdialog",option, text)
    $log.debug("Kdialog ret: #{ret.inspect}")
    ret
  end
  def question(text, options = {})
    kdialog("--yesno", text)
  end
  def warn(text, options = {})
    kdialog("--sorry", text)
  end
  def info(text, options = {})
    kdialog("--msgbox", text)
  end
  def info_non_blocking(text, options = {})
    system("xmessage", "-timeout", "5", "-center",text)    
  end
  def error(text)
    kdialog("--error", text)
  end
  def password(text)
    $log.debug("Kdialog passwod: #{text.inspect}")
    pw = open("|kdialog --password \"#{text}\"") {|f|
      f.readlines.join.gsub(/\n$/,"")
    }
    if $?.exitstatus == 0
      $log.debug("Pwlength: #{pw.length}")
      pw
    else
      $log.debug("Pw: nil")
      nil
    end
  end

  def progress_bar_implementation(text,total)
    ret = nil
    begin
      @pbar_progress = 0
      @pbar = open("|kdialog --progressbar '#{text.gsub("'","\\'")}' #{total}") {|f| f.readlines.join.strip}
      ret = yield
      pmsg
      system("dcop",@pbar,"close")
      @pbar = nil
    ensure
      if @pbar
	system("dcop",@pbar,"close")
	@pbar = nil
      end
    end
    ret
  end
  def progress(count)
    return unless @pbar
    @pbar_progress = count
    system("dcop",@pbar,"setProgress",count.to_s)
  end

  def progress_message(message)
    return unless @pbar
    system("dcop",@pbar,"setLabel",message.to_s)
  end
  def progress_inc
    progress(@pbar_progress + 1)
  end
  
  def execute_in_console(command, options = {})
    command = command_line_parse(command)
    konsole = ["konsole", "-T", command.join(" "), "--nomenubar","--noframe","-e"]
    new_command = konsole + command
    $log.debug("Executing konsole command #{new_command.inspect}")
    system(*new_command)
  end

end
