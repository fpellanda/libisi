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

require "libisi/bridge/base"

raise "Java home is not set" unless
  ENV["JAVA_HOME"]

ld_path = [ENV["LD_LIBRARY_PATH"],
  Pathname.new("#{ENV["JAVA_HOME"]}/jre/lib/i386").realpath.to_s,
  Pathname.new("#{ENV["JAVA_HOME"]}/jre/lib/i386/client").realpath.to_s].compact.join(":")

ENV["LD_LIBRARY_PATH"] = ld_path unless ENV["LD_LIBRARY_PATH"]

$log.debug("JAVA_HOME is #{ENV["JAVA_HOME"]}")
$log.debug("LD_LIBRARY_PATH is #{ENV["LD_LIBRARY_PATH"]}")

# maybe this must be executed to work
# ln -s /usr/lib/jvm/java-1.5.0-sun-1.5.0.14/jre/lib/i386/libmlib_image.so /usr/lib

require 'rjb'

class JavaBridge < BaseBridge  
  DEFAULT_LIBRARIES = [
    "/usr/share/java/jcommon.jar",
    ENV["LD_LIBRARY_PATH"]
  ]    

  def self.load(jar_files)
    jar_files = [jar_files] if jar_files.class == String
    Rjb::load(classpath = (DEFAULT_LIBRARIES + jar_files).join(":"), jvmargs=[])
  end

  def self.import(class_name, options = {})
    @classes ||= []

    import_command = "Rjb::import('#{class_name}')"    

    new_class_name = "#{class_name.split(".")[-1]}"
    if options[:prefix]
      new_class_name = "#{options[:prefix]}#{new_class_name}"
    end

    if @classes.include?(new_class_name)
      #      $log.warn("#{new_class_name} already imported") 
      return eval("#{new_class_name}")
    end

    eval_string = "#{new_class_name} = #{import_command}"
    
    $log.info("Loading java class by #{eval_string.inspect}")
    res = eval(eval_string)
    @classes << new_class_name
    res
  end 
  
end
