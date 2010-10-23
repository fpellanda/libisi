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

require 'rubygems'
require 'rake'
require 'echoe'

# Echoe
# See http://blog.evanweaver.com/files/doc/fauna/echoe/files/README.html

Echoe.new('libisi', '0.3.0') do |p|
  p.description    = "Library for easy and fast shell script developing"
  p.url            = "http://rubyforge.org/projects/libisi/"
  p.author         = "Pellanda Flavio, Copyright Logintas AG"
  p.email          = "flavio.pellanda@logintas.ch"
#  p.ignore_pattern = ["svn_user.yml", "svn_project.rake"]
#  p.project = "ucbrb"
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }