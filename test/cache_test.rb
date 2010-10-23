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
require "libisi/cache"

class CacheTest < Test::Unit::TestCase

  def test_base_cache
    cache = Cache.create(:base)
    assert_equal 1000, cache.maxcount

    block_visited = false
    val = cache.fetch("key") {|key|
      assert_equal "key", key
      block_visited = true
      "value"
    }

    assert block_visited, "Block not called"
    assert_equal "value", val

    block_visited = false

    val = cache.fetch("key") {|key|
      assert false, "Block called but should be cached"
    }

    assert_equal "value", val
    assert cache.has_key?("key"), "Value is not stored in cache"
    
    1000.times {|i| cache.set(i,i) }
    # now our value should be disappeared
    assert !cache.has_key?(val)
    
    block_visited = false
    val = cache.fetch("key") {|key|
      assert_equal "key", key
      block_visited = true
      "value"
    }

    assert block_visited, "Block not called"
    assert_equal "value", val
    assert !cache.has_key?(0)
  end

end
