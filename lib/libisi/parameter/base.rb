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

# object:
# Object to work on
# * a Class: For class methods
# * a Object: For instance methods
# * a Hash of Attributes: For pseudo instance functions
# * nil: For normal functions without context (default)
#
# arguments:
# Array of arguments (ARGV?)
# default: []
#
# parameters:
# Hash of options
# default: {}
class BaseParameter

  attr_accessor :object, :arguments, :options  
  def initialize
    @object = nil
    @arguments = []
    @options = {}    
  end

end
