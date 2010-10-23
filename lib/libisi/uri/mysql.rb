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

require "libisi/uri/base"
class MysqlData < BaseUri
  
  def initialize(uri, options = {})
    super
    self.database
  end

  def database
    db = uri.path
    db = db[1..-1] if db =~ /^\//
    raise "Unexpected database name #{db}" if db =~ /\//
    db
  end

  def mysql_command(command = "mysql")
    cmd = command
    cmd += " -u #{user}" if user
    cmd += " -p#{password}" if password
    cmd
  end
  def execute_mysql(sql)
    execute_command("echo '#{sql}' | " + mysql_command)
  end

  def source_command
    cmd = mysql_command("mysqldump")
    if uri.path
      cmd += " #{database}"
    else
      cmd += " --all-databases"
    end
    cmd
  end

  def target_command
    cmd = mysql_command
    cmd += " #{database}" if uri.path
    cmd
  end  

  def copy_command(target = nil)    
    raise "Convert mysql to #{target.class} not implemented." unless target.class == self.class or target.class == NilClass
    raise "You must specify a source database if you give a target database." if database.nil? and database
    
    ret = execute_command(source_command)
    if target
      ret += "|" + target.execute_command(target.target_command)
    end
    ret
  end

  def readable_command
    if database
      execute_command("echo 'show tables' | " + mysql_command + " #{database} 2>&1 > /dev/null")
    else
      execute_command("echo 'show databases' | " + mysql_command + " 2>&1 > /dev/null")
    end
  end

  def make_readable_command
    if database
      execute_mysql("GRANT SELECT, LOCK TABLES ON #{database}.* TO #{user}@localhost IDENTIFIED BY \"#{password}\"")
    else
      execute_mysql("GRANT SELECT, LOCK TABLES ON *.* TO #{user}@localhost IDENTIFIED BY \"#{password}\"")
    end
  end

  def create_command
    execute_mysql("CREATE DATABASE #{database}")
  end

  def make_writable_command
    if database
      execute_mysql("GRANT ALL ON #{database}.* TO #{user}@localhost IDENTIFIED BY \"#{password}\"")
    else
      execute_mysql("GRANT ALL ON *.* TO #{user}@localhost IDENTIFIED BY \"#{password}\"")
    end
  end
  
end
