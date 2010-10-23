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

$LOAD_PATH.insert(0,File.dirname(__FILE__) + "/../lib/")
require 'test/unit'
require "libisi"
init_libisi

class ProfileTest < Test::Unit::TestCase

  def test_prof
    with_temp_directory {
      self.profiling = FileUtils.pwd.to_s
      10.times { 1 + 1}
      self.profiling_stop
      assert Pathname.new("RubyProf_RubyProf::CallTreePrinter.txt").exist?
      assert Pathname.new("RubyProf_RubyProf::FlatPrinter.txt").exist?
      assert Pathname.new("RubyProf_RubyProf::GraphHtmlPrinter.html").exist?
      assert Pathname.new("RubyProf_RubyProf::GraphPrinter.txt").exist?
    }
  end
end
