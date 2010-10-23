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

class BaseChart

  BAR_TYPES = [:bar, :pie, :gantt, :xy]

  attr_accessor :title, :height, :width, :stacked, :type, :legend_rotation, :legend_chart_ratio

  DEFAULT_HEIGHT = 480
  DEFAULT_WIDTH = 640
  DEFAULT_STACKED = false
  DEFAULT_CHART_TYPE = :bar
  DEFAULT_LEGEND_ROTATION = 0.0 #Math::PI / 6.0
  DEFAULT_LEGEND_CHART_RATIO = 0.4

  def initialize(options = {})
    @height =  DEFAULT_HEIGHT
    @width  =  DEFAULT_WIDTH
    @stacked = DEFAULT_STACKED
    @legend_chart_ratio = DEFAULT_LEGEND_CHART_RATIO
    @options = options
    @options ||= {}
    @axes = []
  end
  
  def display_legend; data_dimension > 1; end
  def enable_urls; false; end
  def enable_tooltips; true; end
  def orientation
    return @orientation if @orientation
    if @type == :gantt
      :horizontal
    else
      :vertical
    end
  end
  def legend_rotation; @legend_rotation or DEFAULT_LEGEND_ROTATION; end

  # data
  def save(filename, options = {})
    create_chart unless @chart
    case filename
    when /.html$/
      Pathname.new(filename).open("w") {|f|
	f.write(data("text/html",options))
      }
    when /.png$/
      Pathname.new(filename).open("w") {|f| f.write(data("image/png",options))}
    else
      raise "Dont know how to save to file #{filename}"
    end
  end

  def ranges
    @ranges
  end

  # axes
  def xaxis; @axes[0]; end
  def xaxis=(val); @axes[0] = val; end
  def yaxis; @axes[1]; end
  def yaxis=(val); @axes[1] = val; end
  def zaxis; @axes[2]; end
  def zaxis=(val); @axes[2] = val; end
  
  # markers
  def mark(name, from = nil, to = nil, options = {})
    raise "Marker value may not be nil" if 
      from.nil? and !block_given?
    if to.class == Hash
      options = to 
      to = nil
    end
      
    if name.class == Hash
      options = name
      name = nil
    end

    options ||= {}
    options = options.dup
   
    if from.nil?
      options[:type] = :category
      options[:key] = name
    else 
      if to.nil?
	options[:type] = :value
	options[:value] = from
      else
	options[:type] = :interval
	options[:start] = from
	options[:end] = to
      end
    end
    options[:name] = name

    if block_given?      
      # this is a domain marker
      # add all values that has been added
      # yield
      options[:axis] = :domain
      previous_keys = @current_serie.keys.dup
      yield
      current_keys = @current_serie.keys.dup
      new_keys = current_keys.reject {|k| previous_keys.include?(k)}
      
      @current_range_options[:markers] ||= []
      new_keys.each {|k|
	o = options.dup
	o[:key] = k
	@current_range_options[:markers] << o
      }
    else
      options[:axis] = :range
      add_to = @options
      add_to = @current_range_options if @current_range_options
      
      add_to[:markers] ||= []
      add_to[:markers] << options   
    end
  end
  alias :marker :mark
  
  # Adding values  
  def range(name = nil, options = {})
    @range_options ||= {}
    @ranges ||= OrderedHash.new        

    raise "Range #{name.inspect} already exist" unless 
      @ranges[name].nil?

    @range_options[name] = options
    @current_range_options = @range_options[name]

    @current_range = OrderedHash.new
    @ranges[name] = @current_range
    yield
    @current_range = nil
  end

  def serie(name = nil, options = {})
    unless @current_range
      range {
	return serie(name) {
	  yield
	}
      }
    end

    @series_options ||= {}
    @series_options[name] = {}

    @current_serie = OrderedHash.new
    @current_range[name] = @current_serie
    yield
    @current_serie = nil
  end

  def value(name, value)
    @current_serie[name] = value
  end

  def time_span(name, start_time, end_time, options = {})   
    raise "No current serie." unless @current_serie
    @type ||= :gantt
    raise "No time_spans allowed for chart type #{@type}" unless
      @type == :gantt

    new_span = {:start => start_time, :end => end_time}
    new_span[:percentage] = options[:percentage] if options[:percentage]

    old_span = @current_timespan
    if @current_timespan
      # ok, we are already in a timespan block
      # add children
      @current_timespan[:children] ||= OrderedHash.new
      raise "There is already a timespan called #{name.inspect}" if
	@current_timespan[:children][name]
      @current_timespan[:children][name] = new_span 
    else
      @current_timespan = new_span
      raise "There is already a timespan called #{name.inspect}" if
	@current_serie[name]
      @current_serie[name] = @current_timespan
    end
    
    yield if block_given?
    @current_timespan = old_span
    new_span
  end

  def data_dimension
    # RANGE x SERIE x CATEGORY x ARRAY
    return 0 unless @ranges
    return 4 if @ranges.keys.length > 1
    return 3 if @ranges[0].nil? or @ranges[0].keys > 1
    return 2 if @ranges[0][0].nil? or @ranges[0][0].keys > 1
    return 1
  end

  # old fashioned loading from alois
  def load(input)
    input = input.split("\n").reverse
    #	System.out.println("Chart title?");
    @title = input.pop
    
    #	System.out.println("Width?");
    @options[:width] = input.pop.to_i

    #	System.out.println("Height?");
    @options[:height] = input.pop.to_i

    #	System.out.println("X-Axis?");
    @axes = []
    @axes[0] = input.pop
    
    #	System.out.println("Y-Axis?");
    @axes[1] = input.pop
    
    #	System.out.println("Series count?");
    serie_count = input.pop.to_i

    #	System.out.println("Range count?");
    range_count = input.pop.to_i
    	  
    @ranges = OrderedHash.new
    range_count.times {|range|
      range_name = input.pop
      range_name = nil if range_name == "<<NULL>>"
      
      current_range = OrderedHash.new
      @ranges[range_name] = current_range
      
      serie_count.times {|serie|
	serie_name =  input.pop
	serie_name = nil if serie_name == "<<NULL>>"
	$log.debug("Serie name: #{category_name}")
	
	current_serie = OrderedHash.new(serie_name)
	current_range[serie_name] = current_serie
	
	rowCount = input.pop.to_i
	columnCount = input.pop.to_i
	
	rowCount.times {|row|
	  category_name = input.pop
	  category_name = nil if category_name == "<<NULL>>"
	  $log.debug("Category name: #{category_name}")
	  
	  current_category = []
	  current_serie[category_name] = current_category
	  
	  columnCount.times {|col|
	    current_category << input.pop
	  }
	}
      }
    }


  end
  
  def create_chart(type = nil, options = {})
    t = (type or @type or DEFAULT_CHART_TYPE)
    
    case options[:combined_axis]
    when nil, :x, "x",:xaxis, "xaxis", :domain, "domain"
      options[:combined_axis] = :domain
    when nil, :y, "y",:yaxis, "yaxis", :range, "range"
      options[:combined_axis] = :range
    else
      raise "Unexpected combined axis option: #{options[:combined_axis].inspect}"
    end
    
    case t
    when :bar, :line, :gantt, :pie
      plot = nil
      case data_dimension
      when 4
	plot = create_combined_plot(@ranges, options[:combined_axis])
      when 3
	plot = create_plot(nil,@ranges.values[0])
      else
	raise "Unexpected data dimension #{data_dimension}"
      end
      
      create_chart_implementation(plot)
      return @chart
    when :xy
      raise "Not implemented yet chart type #{t}"
    else
      raise "Unknown chart type #{t}"
    end    
  end

  def create_combined_plot(data, combination_axis = :category)
    create_combined_plot_implementation(data,combination_axis)
  end

  def create_plot(name, data)
    create_plot_implementation(name,data)
  end

end
