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
require "libisi/chart"

class ChartOrderedHash < Test::Unit::TestCase
  
  def test_array_to_hash
    test_array = [[:key1, "value1"],[:keyb,"value2"],["key3",[[:a,"v"],[:b,"w"]]]]

    assert test_array.can_be_a_hash?
    
    assert_equal '{:key1=>"value1", :keyb=>"value2", "key3"=>[[:a, "v"], [:b, "w"]]}',
      test_array.to_hash.inspect
      
    assert_equal '{:key1=>"value1", :keyb=>"value2", "key3"=>{:a=>"v", :b=>"w"}}',
      test_array.to_hash(true).inspect
      
  end

end
