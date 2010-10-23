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
class ActiveRecordData < BaseUri
  @@num = 0
  
  ADAPTERS = ["mysql","postgresql","sqlite3","sqlite"]

  def ActiveRecordData.split_path(uri)
    return {} unless ADAPTERS.include?(uri.scheme)

    return {} if uri.path.length <= 1
    splited = uri.path[1..-1].split("/")
    case uri.scheme
    when "mysql","postgresql"
      ret = nil
      case splited.length
      when 1
	ret = {:database => splited[0]}
      when 2
	ret = {:database => splited[0], :table => splited[1]}
      else
      ret = {}
      end
    when "sqlite","sqlite3"
      while splited.length > 1 and (exist = Pathname.new(splited[0]).exist?) and Pathname.new(splited[0]).directory?
	$log.debug("#{splited[0]} exist and is a directory")
	splited = [splited[0..1].join("/")] + splited[2..-1]
      end
     
      ret = {:database => splited[0], :table => splited[1]}
    end
    $log.debug("ActiveRecordData split_path: #{uri.inspect} => #{ret.inspect}")
    ret
  end

  def ActiveRecordData.supports?(uri)
    !split_path(uri)[:table].nil?
  end

  attr_reader :adapter, :database, :table
  def initialize(uri, options)
    require "rubygems"
    require "active_record"
    ActiveRecord::Base.logger = $log

    super
        
    @adapter = uri.scheme
    
    vals = ActiveRecordData.split_path(uri)
    @database = vals[:database]
    @table = vals[:table]
    raise "No database given" unless @database
    raise "No table given" unless @table    

    if options[:model]
      require "active_support/core_ext/string/inflections.rb"
      
      $log.info("Loading classes from #{options[:model]}")
      @model_path = Pathname.new(options[:model])
      @class_names = []

      raise "Model path #{@model_path} not found" unless @model_path.exist?
      
      use_activesupport = true
      if use_activesupport
	ActiveSupport::Dependencies.load_paths << @model_path.to_s
      end

      @model_path.find {|p|
	next unless p.to_s =~ /\/([^\/]+)\.rb$/
	
	class_name = $1.camelize
	@class_names << class_name
	
	unless use_activesupport
	  $log.debug("Define autoload: #{class_name.to_sym} => #{p}")
	  autoload(class_name.to_sym, p.to_s)	
	end
      }
    end
  end
 
  def primary_key; active_record_class.primary_key.to_s ;end

  def column_names; active_record_class.column_names; end

  def items; active_record_class.find(:all).to_a; end
  def entry_not_found_exception; ActiveRecord::RecordNotFound; end
  def create(attributes,&block); active_record.create(attributes,&block) ;end
  
  private
  def active_record_class
    return @myclass if @myclass

    if @model_path
      $log.debug("Trying to access class: #{@table.inspect}")
      
      raise "Model path does not define #{@table.inspect}" unless
	@class_names.include?(@table)

      @myclass = eval(@table)
    else
      ActiveRecordData.module_eval("class ActiveRecordClass#{@@num} < ActiveRecord::Base; end")
      @myclass = eval("ActiveRecordClass#{@@num}")
      @@num += 1

      @myclass.set_table_name(table)
      @class_names = [@myclass.name]
    end
    
    @class_names.each {|klass_name|
      #      klass.connection = @myclass.connection
      begin
	klass = eval(klass_name)
	connection_options = {
	  :adapter  => adapter,
	  :host     => uri.host,
	  :port => uri.port,
	  :username => user,
	  :password => password,
	  :database => database
	}
	connection_options[:encoding] = options[:encoding] if options[:encoding]
	
	klass.establish_connection(connection_options) if klass.respond_to?(:establish_connection)
      rescue LoadError, NameError
	raise $! if klass_name == @table
	$log.warn("Error connecting class #{klass_name}, maybe this is not used, continue")
      end

    }
    @myclass
  end

end
