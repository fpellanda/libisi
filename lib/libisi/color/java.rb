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

require "libisi/color/base.rb"
require "libisi/bridge/java.rb"

class JavaColor < BaseColor

  def method_missing(m, *args)
    @obj.send(m, *args)
  end

  attr_accessor :java_object

  def initialize(options = {})
    # create javacolor out of color-tools
    options = Color.create("colortools",options) if
      options.class == String or options.class == Symbol

    raise "Cannot create color out of #{options}" unless
      options.respond_to?(:rgb)
    rgb = options.rgb
    @java_object = JavaBridge.import("java.awt.Color").new(*rgb)    
  end
  
  def html
    "#" + [@java_object.getRed.to_s(16),@java_object.getGreen.to_s(16),@java_object.getBlue.to_s(16)].map {|v| v.ljust(2,"0")}.join
  end

end
