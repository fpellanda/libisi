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

class BaseConcept

  VALUE_TYPES = [:attributes, :properties, :relations]

  attr_reader :base_class

  def initialize(base_class, options = {})
    @base_class = base_class
  end

  # There are by default no attributes
  def attribute_names; []; end
  def attributes; []; end

  def property_names
    ans = attribute_names
    rns = relation_names
    base_class.instance_methods.reject {|mn|
      base_class.instance_method(mn).arity != 0 or
	mn =~ /^to_/ or
	mn =~/^get_/ or
	mn =~/^set_/ or
	mn =~ /=$/ or
	mn =~ /_type$/ or
	mn =~ /_unit$/ or
	ans.include?(mn) or
	rns.include?(mn)
    }
  end
  
  def properties
    property_names.map {|p| 
      Property.create(base_class, p)
    }
  end

  def value_accessors
    VALUE_TYPES.map {|vt| self.send(vt)}.flatten
  end
  
end
