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

class BaseValue

  attr_reader :source, :instance
  
  def initialize(source, instance, options = {})
    @source = source
    @instance = instance
  end

  def unit; source.respond_to?(:unit) and source.unit; end
  def type; source.respond_to?(:type) and source.type; end
  def name; source.name; end

  def data_object; instance.send(name); end
  def to_s; data_object.to_s; end
  def inspect; "#{to_s} <#{type or "?"}/#{unit or "?"}>"; end

  def to_doc(options)
    raise "No doc initialized" unless $doc
    
    case type
    when :integer
      i = data_object
      if i < 0
	$doc.print(:color => "red") {
	  i.to_s
	}
      else
	$doc.print { 
	  i.to_s
	}
      end
      }
    when :text
      $doc.p { data_object.to_s }
    end
  end
end
