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
require "libisi/color"

class ColorTest < Test::Unit::TestCase

  COLORS = {
    "#ff0000" => ["red","Red","RED",:red],
    "#d3d3d3" => ["light_gray","lightgray","LightGRay",:light_gray,:lightgray],
    "#aabbcc" => ["#aabbcc","#aabbcc","aabbcc"],
    "#aabbcc" => ["#abc","#abc","abc"],
  }

  def test_java
    COLORS.each {|rgb, colors| 
      colors.each {|color|
	assert Color.create("java",color), "Could not create java color #{color}"
	assert_equal rgb, Color.create("java",color).html, "Expected java color #{color} to be #{rgb}"
      }
    }
  end

  def test_colortool
    COLORS.each {|rgb, colors| 
      colors.each {|color|
	assert Color.create("colortools",color), "Could not create colortools color #{color}"
	assert_equal rgb, Color.create("colortools",color).html, "Expected colortools color #{color} to be #{rgb}"
      }
    }

    assert_equal "#f12f3f", Color.create("colortools","#f12f3f").html
    c = Color.create("colortools","#f12f3f")
     assert_equal [241,47,63], c.rgb
    assert_equal "#f12f3f", c.html
    c.html = "ff2f3f"
    assert_equal [255,47,63], c.rgb
    c.red = 241
    assert_equal [241,47,63], c.rgb
    c.green = 222
    assert_equal [241,222,63], c.rgb
    c.blue = 7
    assert_equal [241,222,7], c.rgb
  end

end
