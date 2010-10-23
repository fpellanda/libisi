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

class BaseCache
  
  attr_accessor :maxcount
  def initialize(options = {})
    @maxcount = (options[:maxcount] or 1000)    
    @cache = OrderedHash.new
  end

  def fetch(key, options = {}, &block)
    if has_key?(key)
      return get(key)
    else
      raise "No block given" unless block
      value = case block.arity
	      when 0
		yield
	      when 1
		yield(key)
	      when 2
		yield(key, options)
	      else
		raise "Unexpected arity count of fetch block #{block.arity}"
	      end
	
      set(key,value)
      value
    end
  end

  def get(key)
    @cache[key]
  end

  def set(key, value)
    while @cache.length >= maxcount
      @cache.delete(@cache.first.keys[0])
    end
    
    @cache[key] = value
  end

  def delete(key)
    @cache.delete(key)
  end

  def has_key?(key)
    @cache.has_key?(key)
  end

end
