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
class X11UI < BaseUI
  def info(text, options = {})
    system("xmessage", "-center",text)
  end
  def info_non_blocking(text, options = {})
    system("xmessage", "-timeout", "5", "-center",text)    
  end
  def question(text, options = {})
    system("xmessage", "-buttons","yes,no","-center",text)
    $?.exitstatus == 101
  end

  def password(text)
    Open3.popen3("pinentry") { |stdin, stdout, stderr|
      stdin.write("SETPROMPT Password\n")
      $log.debug(stdout.readline)
      stdin.write("SETDESC " + text.gsub("\n","\\\n") + "\n")
      $log.debug(stdout.readline)
      stdin.write("GETPIN\n")
      $log.debug(stdout.readline)
      ans = stdout.readline
      return nil if ans == "ERR 111 canceled\n"
      unless ans =~ /^D (.*)\n$/
	raise "Unexpected answer #{ans} from pinentry."
      end
      $1.gsub("%25","%")
    }
  end

  def execute_in_console(command, options = {})
    command = command_line_parse(command)
    konsole = ["xterm", "-T", command.join(" "),"-e"]
    new_command = konsole + command
    $log.debug("Executing konsole command #{new_command.inspect}")
    system(*new_command)
  end
end
