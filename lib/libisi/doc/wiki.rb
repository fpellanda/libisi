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

require "libisi/doc/base"
class WikiDoc < BaseDoc
  def initialize(options = {})
    super
    @indent = 0
  end

  def tr(options = {}, &block)
    yield
    writer(options, &block) << "||\n"   
  end
  def td(options = {}, &block)
    writer(options, &block) << "|| "
    writer(options, &block) << yield
    writer(options, &block) << " "
  end
  def th(options = {}, &block)
    writer(options, &block) << "|| "
    writer(options, &block) << yield.to_s.upcase
    writer(options, &block) << " "
  end  
  def ul(options = {}, &block)
    @indent += 1
    yield
    @indent -= 1
  end
  def li(options = {}, &block)
    writer(options, &block) << (" " * 2*@indent) + "* "
    writer(options, &block) << yield
    writer(options, &block) << "\n"
  end

  def p(options = {}, &block)
    writer(options, &block) << yield
    writer(options, &block) << "\n\n"
  end

end
