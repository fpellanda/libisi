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
class LdapData < BaseUri
  @@num = 0
  
  require "active_ldap"

  def initialize(uri, options = {})
    super
  end
  
  def primary_key; ldap_class.dn_attribute ;end

  def column_names;     
    return @column_names if @column_names
    $log.debug("Finding column names")
    @column_names = items.map {|i| i.attribute_names}.flatten.uniq.compact.sort
  end

  def items; ldap_class.find(:all); end
  def entry_not_found_exception; ActiveLdap::EntryNotFound; end
  def create(attributes,&block); ldap_class.create(attributes,&block) ;end
  def new(attributes, &block); ldap_class.new(attributes, &block); end

  private
  def ldap_class
    return @myclass if @myclass
    
    LdapData.module_eval("class LdapClass#{@@num} < ActiveLdap::Base; end")
    @myclass = eval("LdapClass#{@@num}")
    @@num += 1

    path_items = uri.path.split("/")[1..-1]
    base = path_items[0]
    $log.debug("Base dn: #{base}")
    $log.debug("Bind dn: #{user}")

    @myclass.setup_connection(
				      :host => uri.host,
				      :port => (uri.port or 389),
				      :base => base,
				      :logger => $log,
				      :bind_dn => user,
				      :password_block => Proc.new { password },
				      :allow_anonymous => false,
				      :try_sasl => false,
				      :method => (options[:method] or "tls") #:tls, :ssl, :plain
				      )
    klass = path_items[1..-2].reverse.join(",")
    $log.debug("prefix: #{klass}")
    dn = path_items[-1]
    $log.debug("dn_attribute: #{dn}")
    @myclass.ldap_mapping :prefix => klass,:dn_attribute => dn
  end

end
