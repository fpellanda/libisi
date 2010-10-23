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

require "libisi/base.rb"
require "libisi/concept/base.rb"
class Concept < Base

  def self.create(klass, options = {})
    if defined?(ActiveRecord::Base) and 
	klass.superclass == ActiveRecord::Base
      require "libisi/concept/activerecord.rb"
      # this is a activerecord concept
      return ActiverecordConcept.new(klass, options)
    end

    return BaseConcept.new(klass, options)
  end

end
