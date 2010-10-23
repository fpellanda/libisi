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

class BaseUri
  
  attr_accessor :uri, :options
  
  def initialize(uri, options = {})
    @uri = uri
    @options = options
  end

  def credential_hash
    uis = (uri.userinfo or "").split(":")
    ret = {}
    # URI unescape to allow special characters, 
    # probably not rfc conform
    ret[:user] = URI.unescape(uis[0]) if uis[0]
    ret[:password] = URI.unescape(uis[1]) if uis[1]
    ret
  end

  def base_uri
    u = uri.dup
    u.path = ""
    u
  end

  def user
    options[:user] or credential_hash[:user]
  end
  def password
    options[:password] or credential_hash[:password] or
      (options[:use_password] and $ui.password("Please enter password for #{base_uri.to_s}"))
  end

  def execute_command(command)
    return command if uri.host == "localhost"
    l = uri.host
    #  l = "#{uri.userinfo}@#{l}" if uri.userinfo
    execute_on_remote_command(l, command)
  end

  def find(*args)
    options = {}
    options = args.pop if args[-1].class == Hash
    
    raise "No more than one argument allowed at the moment" if
      args.length > 1

    m_items = (self.items or [])
    if conditions = options[:conditions]
      conditions.each {|field, value|
	raise "Only unless Symbol => (Regex|String) pairs allowed for conditions:" +
	  "#{field.inspect}(#{field.class.name}) => #{value.inspect}(#{value.class.name})" if
	  field.class != Symbol or ![String,Regexp].include?(value.class)

	$log.debug("Filtering items for #{field} => #{value}")

	case value
	when String
	  compare_proc = Proc.new {|v| v == value }
	when Regexp
	  compare_proc = Proc.new {|v| v =~ value }
	end

	m_items = m_items.select {|i|
	  item_value = i.send(field )
	  case item_value
	  when String
	    compare_proc.call(item_value)
	  when Array
	    item_value.select{|v| compare_proc.call(v)}.length > 0
	  when NilClass
	    false
	  else
	    raise "Item field value #{item_value.inspect} of #{i.inspect} has unexpected type #{item_value.class.name}"
	  end
	}
	$log.debug("There are still #{m_items.length} items after filter #{field} => #{value}")
      }
    end

    case args.first
    when :first then m_items[0]
    when :last  then m_items[-1]
    when :all   then m_items
    else
      key_proc = primary_key
      key_proc = Proc.new {|i| i.send(primary_key)} if primary_key.class == String
      m_items.each {|i|
	return i if key_proc.call(i).to_s == args.first.to_s
      }
      
      raise self.entry_not_found_exception if self.respond_to?(:entry_not_found_exception)
      raise "Item #{args.first} not found"

    end
  end

end
