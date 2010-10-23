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

require "libisi/uri/base"
class FileData < BaseUri
  
  def initialize(uri, options = {})
    super
    raise "Only local files allowed. Host is #{uri.host}" unless
      ["127.0.0.1","localhost"].include?(uri.host)
    @file = Pathname.new(uri.path[1..-1])
  end

  def file; @file; end
  def pathname; @file; end

  def primary_key; Proc.new {|pathname| pathname.basename.to_s}; end

  def column_names; ["size","dirname","basename"]; end

  def items
    if @file.directory?
      @file.entries
    else
      @file.readlines
    end
  end

end
