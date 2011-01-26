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

# dirty fix to avoid namespace collision,
# see ColortoolsClolor.in_colortool
module Libisi;end
Libisi::Color = Color
Object.send(:remove_const,"Color")

require "color.rb"
require "color/rgb.rb"
require "color/hsl.rb"  
module Colortools;end

Colortools::Color = Color
Object.send(:remove_const,"Color")

Color = Libisi::Color

class ColortoolsColor < BaseColor

  def ColortoolsColor.in_colortool
    @@count ||= 0
    @@count += 1
    Object.send(:remove_const,"Color")    
    Object.const_set("Color", Colortools::Color)
    yield    
  ensure
    @@count -= 1
    if @@count == 0
      Object.send(:remove_const,"Color")    
      Object.const_set("Color", Libisi::Color)
    end
  end

  def ColortoolsColor.get_color(name)
    normalized_name = name.to_s.split("_").map {|n| n.capitalize}.join

    ColortoolsColor.in_colortool{
      Color::RGB.constants.each {|c|
        if c == normalized_name or
            c.scan(/[A-Z][a-z]*/).map {|n| n.downcase}.join.capitalize == normalized_name
          return ColortoolsColor.new(Color::RGB.const_get(c))
        end
      }
    }
    return nil 
  end
  
  attr_accessor :rgb_color

  def initialize(options = {})    
    #Color::RGB.new(32, 64, 128)
    #Color::RGB.new(0x20, 0x40, 0x80)
    case options.class.name
    when "Color::RGB"
      @rgb_color = options
    when "ColortoolsColor"
      @rgb_color = options.rgb_color.dup      
    else
      raise "Require html color from options got: #{options.inspect}" unless 
        options.class == String or options.class == Symbol
      if col = ColortoolsColor.get_color(options)
        @rgb_color = col.rgb_color
      else
        # try html color
        begin
          ColortoolsColor.in_colortool{
            @rgb_color = Color::RGB.from_html(options)
          }
        rescue ArgumentError
          raise "Color #{options} not found"
        end
      end
    end   
  end

  def data(mime_type)
    case mime_type
    when "text/htmlcolor"
      return @rgb_color.html
    else
      raise "Dont know how to be a #{mime_type}"
    end
  end
  
  def html=(value)
    @rgb_color = ColortoolsColor.in_colortool { Color::RGB.from_html(value)}
  end

  def html
    @rgb_color.html
  end

  def hue_percentage_implementation(percentage)
    @rgb_color = ColortoolsColor.in_colortool{@rgb_color.adjust_hue(percentage)}
  end

  def brightness_implementation; ColortoolsColor.in_colortool{@rgb_color.brightness}; end
  def brightness_percentage_implementation(percentage)
    @rgb_color = ColortoolsColor.in_colortool{@rgb_color.adjust_brightness(percentage)}
  end 

  def saturation_percentage_implementation(percentage)
    @rgb_color = ColortoolsColor.in_colortool{@rgb_color.adjust_saturation(percentage)}
  end 

end
