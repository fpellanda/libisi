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

require "libisi/tee"
class Base
  
  def output_types; {};  end
  def self.output_endings
    output_types.map {|key, endings| endings}.flatten.sort
  end
  def self.type_from_ending(ending)
    output_types.each {|t, endings|
      return t if endings.include?(ending)
    }
    nil
  end

  def self.output(file)
    $log.debug("Looking for outputter in #{self.name} for file #{file}")
    return false unless (file.to_s =~ /\.([^\.]+)$/)    
    ending = $1
    t = type_from_ending(ending)
    $log.debug("Type for ending #{ending.inspect} is #{t.inspect}")
    return false unless t

    file = Pathname.new(file)
    
    new_child = create_output(t, ending, file)
    # we have to add this to the
    # global variabel - if this is
    # nil, the method handes itself
    return true unless new_child

    add_output(new_child)
  end

  def self.add_output(new_child)
    curr = global_variable
    $log.debug("Current #{self.name} is #{curr.class.name}")
    case curr
    when NilClass
      $log.debug("Setting new child as only instance.")
      curr = new_child
    when Tee
	$log.debug("Setting new child as tee to #{curr.children.length} other instance.")
      curr.add_child(new_child)
    else
      $log.debug("Setting new child with new tee to another instance.")
      curr = Tee.new([curr, new_child])
    end
    self.global_variable = curr
    curr    
  end

  def self.create_output(type, ending, file)
    $log.debug("Create new output of type #{type} to file #{file}")
    create(type,:writer => file.open("w"))
  end

  def self.init(options = {})
    $log.debug("Initialize #{self.class.name}")
  end

  def self.global_variable
    eval("$#{self.name.downcase}")
  end
  def self.global_variable=(val)
    eval("$#{self.name.downcase} = val")
  end
  
  def self.change(type, options = {})
    $log.debug("Change #{self.class.name} to type #{type} with options #{options.inspect}")
    self.global_variable = create(type, options)
  end

  def self.load(type_name, options = {})
    type_name = type_name.to_s
    raise "Hacking attack!!" unless type_name.class == String
    raise "Unexpected #{self.name} name #{type_name}." unless type_name =~ /^[a-zA-Z][a-zA-Z0-9]*$/
    require "libisi/#{self.name.downcase}/#{type_name}.rb"
    eval("#{type_name.capitalize}#{self.name}")
  end

  def self.create(type_name, options = {})
    klass = load(type_name)
    if klass.respond_to?(:instanciate)
      ret = klass.instanciate(options)
      raise "#{klass.name} created null object!" if ret.nil?
      ret
    else
      klass.new(options)
    end
  end

end
