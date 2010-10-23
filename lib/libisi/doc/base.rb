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

class BaseDoc

  def initialize(options = {})
    @writer = options[:writer] if options[:writer]
    @init = options[:doc_started] if options[:doc_started]
  end

  def print(options = {}, &block)
    writer(options, &block) << yield
  end
  def p(options = {}, &block)
    writer(options, &block) << yield + "\n\n"
  end
  
  def title(text, options = {}, &block)
    @title_depth ||= 0
    @title_depth += 1
    generate_title(text, options, &block)
    @title_depth -= 1
  end

  def flatten_columns(columns, options)
    # we will use this for grouping
    options[:columns] ||= []

    case columns
    when Array
      options[:columns] << columns
    when Hash
      options[:group_bys] ||= []      
      columns.each {|key,columns|
	unless key.nil?
	  options[:group_bys] << Proc.new {|element| 
	    case element
	    when Hash
	      element[key]
	    else
	      element.send(key)
	    end
	  }
	end
	flatten_columns(columns, options)
      }
    else 
      raise "Unexpected columns type #{columns.class.name}"
    end
    options
  end

  def generate_table(options = {}, &block); generate_bare_table(options, &block) end
  def generate_bare_table(options = {},&block) 
    return yield if options[:columns].nil? and options[:items].nil?

    options = flatten_columns(options.delete(:columns),options) if options[:columns].class == Hash
    
    if options[:group_bys]      
      raise "No items given" unless options[:items]
      # group the items
      benchmark("Table group bys") {
	options[:items] = options[:items].group_bys(*options[:group_bys])
      }
      options[:grouped] = true
    end
    
    if options[:items] and options[:columns] and not options[:no_header]
      # create header
      tr(options) { options[:columns].flatten.each_with_index{|c,i| th(options) {
	    if f = options[:header_function]
	      case f
	      when Proc
		if f.arity == 1
		  f.call(c)
		else
		  f.call(c,i)
		end
	      when Symbol, String
		c.send(f)
	      else
 		raise "Unexpected header function #{f.inspect}"
	      end
	    else
	      c
	    end
	  }}}
    end

    if options[:items]
      options[:header_function].call(options_for_functions(options) ) if options[:header_function]
      table_items(options[:items],options,&block)
      options[:footer_function].call(options_for_functions(options) ) if options[:footer_function]
    else
      options[:columns].flatten.each_with_index {|column, column_index|
	tr(options) {
	  th(options) {column}
	  #	  td(options) {
	  # problem with tee here
	  td {options[:columns].inspect}
	  case block.arity
	  when 2
	    yield(column,column_index)
	  else
	    yield(column)
	  end
	}
	#	}
      }
    end
  end
  def bare_table(options = {}, &block)
    generate_bare_table(options, &block)
  end
  def table(options = {}, &block)
#    options[:writer] = writer(options, &block) unless options[:writer]
    generate_table(options,&block)
  end

  def options_for_functions(options)
    options[:item_tree] = options[:items].to_hash(true) unless options[:item_tree]
    o = options.dup
    if o[:group_bys]
      benchmark("Doc.options_for_functions") {
	total_groupings = o[:group_bys].length
	if o[:group_column_index]
	  # we are at item output
	  depth = o[:group_column_index]
	else
	  # we are at grouping
	  depth = (o[:group_keys] or []).length - 1
	end
	
	# correct group_keys because we are maybe already
	# in a gouping
	o[:group_keys] = (o[:group_keys] or []).dup[0..depth]

	o[:group_tree] = options[:item_tree]

	o[:group_keys].each {|k|
	  o[:group_tree] = o[:group_tree][k]
	}
	
	o[:group_items] = o[:group_tree]
	o[:group_items] = o[:group_items].values.flatten if o[:group_items].class == Hash
	#      while !o[:group_items].nil? and o[:group_items][0].class == Hash
	(total_groupings - depth - 2).times {
	  o[:group_items] = o[:group_items].map {|h| h.values}.flatten
	}
	#      end
      }
    end
    o
  end


  def options_for_functions_orig(options)
    o = options.dup
    if o[:group_bys]
      benchmark("Doc.options_for_functions") {
	total_groupings = o[:group_bys].length
	if o[:group_column_index]
	  # we are at item output
	  depth = o[:group_column_index]
	else
	  # we are at grouping
	  depth = o[:group_keys].length - 1
	end
	
	# correct group_keys because we are maybe already
	# in a gourping
	o[:group_keys] = o[:group_keys].dup[0..depth]

	o[:group_tree] = options[:items].to_hash(true)
	o[:group_keys].each {|k|
	  o[:group_tree] = o[:group_tree][k]
	}
	
	o[:group_items] = o[:group_tree]
	o[:group_items] = o[:group_items].values.flatten if o[:group_items].class == Hash
	#      while !o[:group_items].nil? and o[:group_items][0].class == Hash
	(total_groupings - depth - 2).times {
	  o[:group_items] = o[:group_items].map {|h| h.values}.flatten
	}
	#      end
      }
    end
    o
  end

  def call_total_function(function_name, options = {})
    level = options[:group_keys].length - 1
    function = options[(function_name.to_s + level.to_s).to_sym]
    return unless function
    function.call(options_for_functions(options))
  end

  def table_items(items, options = {}, &block)
    redo_item = false
    if options[:grouped]
      options[:group_elements] ||= []
      options[:group_keys] ||= []
      options[:item_index] ||= 0

      if items[0].class == Array and 
	  items[0].length == 2
	# this is still a group
	items.each_with_index {|val, group_index|
	  key, group = val
	  options[:group_elements] << key
	  options[:group_keys] << key
	  call_total_function(:before_group_function, options)
	  table_items(group, options, &block)
	  call_total_function(:after_group_function, options)
	  options[:group_elements].pop
	  options[:group_keys].pop
	}
      else
	# finished grouping, do output
	if options[:return_group_at_once]
	  tr(options) {	    
	    redo_item = table_item(items, options[:item_index], options, &block)
	  }	  
	else
	  items.each_with_index {|item, item_index|
	    tr(options) {
	      redo_item = table_item(item, options[:item_index], options, &block)
	    }
	    redo if redo_item
	  }
	end
      end
    else
      options[:items].each_with_index {|item, item_index|
	tr(options) {
	  redo_item = table_item(item, item_index, options, &block)
	}
	redo if redo_item
      }      
    end
  end
  
  def table_item(item, item_index, options = {}, &block)    
    redo_item = false
    options[:item_index] += 1 if options[:item_index]
    if (cols = options[:columns])
      # yield one per column
      column_index = -1

      # cols in format 
      #  [ [groupcol,groupcol,groupcol], # columns for group element 1
      #    [groupcol,groupcol,groupcol], # columns for group element 2
      #    col,col,col ] 
      cols.each_with_index {|subcolumns, group_column_index|
	options[:group_column_index] = group_column_index

	if subcolumns.class == Array
	  # ok these are subcolumns of a group
	else
	  subcolumns = [subcolumns]
	end
	
	subcolumns.each_with_index {|column,subcol_index|
	  # column_index counts trough each column (including group cols)
	  column_index += 1

	  el = item

	  group_column = (options[:group_elements] and 
	      options[:group_elements].length > group_column_index)
	  if group_column
	    # This is a group column
	    
	    if options[:group_elements][group_column_index] == NilClass 
	      # we already yielded this group element
	      td(options) {} 
	      next
	    else
	      el = options[:group_elements][group_column_index]
	      # mark group element as visited if all group columns
	      # for that group element have been yielded
	      if (subcolumns.length - 1) == subcol_index
		options[:group_elements][group_column_index] = NilClass 
		if options[:span_grouping]
		  redo_item = true 
		  
		  # TODO: this is not right, but works for group items with one column
		  total_columns = options[:columns].flatten.length
		  grouped_columns = (options[:group_elements].length - 1)
		  
		  options = { :colspan => total_columns - grouped_columns}.merge(options)		    
		  #		    td({:colspan => grouped_columns}.merge(options)) {} unless grouped_columns == 0
		  #		    th({:colspan => total_columns - grouped_columns}.merge(options)) {yield(key}
		end
											
	      end

	      if block_given? and block.arity == 1		
		td(options) {
		  if options[:span_grouping]
		    # we already printed grouping
		    ""
		  else
		    el.to_s
		  end
		} 
		next
	      end	  
	    end
	  end
  
	  next td(options){el.to_s} unless block_given?
	  case block.arity
	  when 2
	    td(options) {yield(el,column)}
	  when 3
	    td(options) {yield(el,column,item_index)}
	  when 4
	    td(options) {yield(el,column,item_index,column_index)}
	  when 5
	    o = options_for_functions(options)	    
	    td(options) {yield(el,column,item_index,column_index,o)}
	  else
	    yield(el)
	    # class is handling columns themself
	    break
	  end
	  if redo_item
	    options.delete(:group_column_index)
	    return true 
	  end
	}
	options.delete(:group_column_index)
      }
      false
    else
      if options[:group_elements]
	options[:group_elements].each_with_index {|group_element, group_element_index|	  
	  if group_element
	    td(options) { group_element} 
	  else
	    td(options) {} 
	  end
	  options[:group_elements][group_element_index] = nil
	}
      end

      return td(options) {item.to_s} unless block_given?

      case block.arity
      when 2
	yield(item,item_index)
      else
	return yield(item)
      end
    end
  end

  def tn(options = {}, &block); 
    options[:text_align] ||= "right"
    td(options, &block)
  end
  
  def start_doc; end
  def end_doc; end

  def close
    to_stdout(@writer)
    @writer.close if @writer and @writer.respond_to?(:close)
  end

  private
  def to_stdout(text)
    STDOUT << ("#{text.inspect}\n")
  end

  def writer(options = {}, &block)
    @writer = options[:writer] if options[:writer]
    if @writer and @writer.respond_to?(:call)
      @writer = @writer.call(block)
    end

    unless @init
      @init = true
      self.start_doc
    end

    return @writer if @writer
    return STDOUT
#    klass = eval("self.class",block.binding)
#    case klass
#    when BaseDoc
  end
  
  def generate_title(text, options, &block)
    print(options) { text.to_s.upcase + "\n"}
    yield
  end

end
