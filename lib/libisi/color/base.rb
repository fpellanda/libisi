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

class BaseColor

  def object(type_name)
    case type_name
    when "java", "java/paint"
      Color.create("java", self)
    end
  end

  def red; rgb[0]; end
  def red=(val); self.rgb=[val,green,blue]; end
  def green; rgb[1]; end
  def green=(val); self.rgb=[red,val,blue]; end
  def blue; rgb[2]; end  
  def blue=(val); self.rgb=[red,green,val]; end
  def rgb
    h = html
    h = $1 if h =~ /^\#(.*)\;?$/    
    case h.length
    when 3
      [h[0..0].hex,h[1..1].hex,h[2..2].hex]
    when 6
      [h[0..1].hex,h[2..3].hex,h[4..5].hex]
    else
      raise "Unexpected html value #{html.inspect}"
    end
  end

  def rgb=(values)
    r,g,b = values
    self.html = r.to_s(16).rjust(2,"0") + g.to_s(16).rjust(2,"0") + b.to_s(16).rjust(2,"0")
  end

  def hue(value=nil); adjust(:hue, value); end
  def brightness(value=nil); adjust(:brightness, value); end
  def saturation(value=nil); adjust(:saturation, value); end

  def adjust(property, value=nil)
    return self.send("#{property.to_s}_implementation") if value == nil

    case value
    when /^((\+|\-)?\d+\.?\d*)%/
      self.send("#{property.to_s}_percentage_implementation",$1.to_f)
    else
      raise "Not implemented hue #{value}"
    end    
  end

end
