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
class Doc < Base

  def self.output_types
    {"text" => ["txt","text"],
      "html" => ["html","htm"]}      
  end
     
  def self.create(doc, options = {})
    doc = doc.to_s
    raise "Hacking attack!!" unless doc.class == String
    raise "Unexpected Doc name #{doc}." unless doc =~ /^[a-zA-Z][a-zA-Z0-9]*$/
    require "libisi/doc/#{doc}.rb"
    klass = eval("#{doc.capitalize}Doc")
    klass.new(options)
  end

end
