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

class BaseEnvironment

  attr_reader :parent

  def initialize(parent, options = nil)
    #parent = RootEnvironment.new if parent.nil?
  end

  def type; raise "Not implemented"; end
  def implementation; raise "Not implemented"; end
  def instance; raise "Not implemented"; end
  def execute(task); raise "Not implemented"; end

  def user; parent.user; end
  def uri; parent.uri; end
  def name; parent.name; end
  def language; parent.language; end

end
