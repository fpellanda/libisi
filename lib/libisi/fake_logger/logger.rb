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

# fake logger class, do not load
# logger.rb in ruby api. Include
# functions that are needed for
# rails
module Log4r
  class Logger
    # Logging date-time format (string passed to +strftime+).
    def datetime_format=(datetime_format)
      @default_formatter.datetime_format = datetime_format
    end
    
    def datetime_format
      @default_formatter.datetime_format
    end
    
    def format_message(severity, datetime, progname, msg)
      (@formatter || @default_formatter).call(severity, datetime, progname, msg)
    end


    private
    
    def format_datetime(time)
      if @datetime_format.nil?
        time.strftime("%Y-%m-%dT%H:%M:%S.") << "%06d " % time.usec
      else
        time.strftime(@datetime_format)
      end
    end

    def msg2str(msg)
      case msg
      when ::String
        msg
      when ::Exception
        "#{ msg.message } (#{ msg.class })\n" <<
          (msg.backtrace || []).join("\n")
      else
        msg.inspect
      end
    end

  end
end
