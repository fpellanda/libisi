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

require "libisi/bridge/java.rb"
require "libisi/chart/base.rb"
require "libisi/chart/jfreechart_generator.rb"
require "libisi/color.rb"
require "stringio"

JavaBridge.load("/usr/share/java/jfreechart.jar")

[
  "org.jfree.ui.RectangleAnchor",
  "org.jfree.ui.TextAnchor",
  "org.jfree.ui.Layer",
  "org.jfree.chart.plot.CategoryMarker",
  "org.jfree.chart.plot.IntervalMarker",
  "org.jfree.chart.plot.ValueMarker",
  "org.jfree.chart.LegendItemCollection",
  "org.jfree.chart.axis.CategoryLabelPositions",
  "org.jfree.chart.axis.CategoryLabelPosition",
  "org.jfree.chart.axis.CategoryLabelWidthType",
  "org.jfree.chart.ChartColor",
  "java.awt.image.BufferedImage",
  "java.awt.Rectangle",
  "java.awt.TexturePaint",
  "java.awt.Font",
  "org.jfree.text.TextBlockAnchor",
  "org.jfree.util.TableOrder",
  "org.jfree.chart.JFreeChart",
  "org.jfree.chart.ChartFactory",
  "org.jfree.chart.axis.CategoryAxis",
  "org.jfree.chart.axis.ExtendedCategoryAxis",
  "org.jfree.chart.axis.NumberAxis",
  "org.jfree.chart.plot.XYPlot",
  "org.jfree.chart.entity.StandardEntityCollection",
  "org.jfree.chart.ChartUtilities",
  "org.jfree.chart.plot.CombinedRangeCategoryPlot",
  "org.jfree.chart.plot.CombinedDomainCategoryPlot",
  "org.jfree.chart.plot.CombinedRangeXYPlot",
  "org.jfree.chart.plot.CombinedDomainXYPlot",
  "org.jfree.chart.axis.DateAxis",
  # produces already initialized constant DEFAULT_TOOL_TIP_FORMAT_STRING at javabridge.import
  # but this class is not needed
  #  "org.jfree.chart.labels.IntervalCategoryToolTipGenerator",
  "org.jfree.chart.axis.QuarterDateFormat",
  "java.text.DateFormat",
  "org.jfree.chart.plot.CategoryPlot",
  "org.jfree.chart.plot.PlotOrientation",

  # rendering
  "org.jfree.chart.renderer.category.IntervalBarRenderer",
  "org.jfree.chart.renderer.category.GanttRenderer",
  "org.jfree.chart.renderer.xy.StackedXYAreaRenderer2",
  "org.jfree.chart.renderer.category.StackedBarRenderer",
  "org.jfree.chart.ChartRenderingInfo",
  "org.jfree.chart.renderer.category.BarRenderer",
  "org.jfree.chart.plot.MultiplePiePlot",
  "org.jfree.chart.renderer.xy.XYBarRenderer",

  # datasets
  "org.jfree.data.category.DefaultCategoryDataset",
  "org.jfree.data.xy.CategoryTableXYDataset",
  
  "org.jfree.data.gantt.Task",
  "org.jfree.data.gantt.TaskSeries",
  "org.jfree.data.gantt.TaskSeriesCollection",  

  "org.jfree.data.time.SimpleTimePeriod",
  "java.util.Calendar"
].each {|klass|
  if klass == "org.jfree.chart.labels.IntervalCategoryToolTipGenerator"
    p "kde" if defined?(DEFAULT_TOOL_TIP_FORMAT_STRING)
    p "here"
  end

  eval("#{klass.split(".")[-1]} = JavaBridge.import(klass)")
  if klass == "org.jfree.chart.labels.IntervalCategoryToolTipGenerator"
    p "end"
  end
}

# same space
[
  "java.util.Date",
  "java.io.File",
].each {|klass|
  eval("J#{klass.split(".")[-1]} = JavaBridge.import(klass, :prefix => 'J')")
}


class JfreechartChart < BaseChart

  def data(mime_type, options = {})
    raise "No chart defined" unless @chart

    temp_file {|temp_image_file|
      info = ChartRenderingInfo.new(StandardEntityCollection.new)
      ChartUtilities.saveChartAsPNG(JFile.new(temp_image_file.to_s),
				      @chart, width.to_i, height.to_i, info);
      
      case mime_type
      when "image/png"
	temp_image_file.open("r").read
      when "text/html"
	image_file = nil
	image_file = Pathname.new(options[:image_file]) if
	  image_file.nil? and options[:image_file]
	image_file = Pathname.new(image_path) + "jfreechart.png" if 
	  image_file.nil? and options[:image_path]

	image_map_file = nil
	image_map_file = Pathname.new(option[:image_map_file]) if
	  image_map_file.nil? and options[:image_map_file]
	
	image_map_file.open("w") {|f|
	  f.write(ChartUtilities.getImageMap("chart", info))
	} if image_map_file
	
	
	html_file = StringIO.new      
	# write an HTML page incorporating the image with an image map
	if options[:layout].nil? or !options[:layout]
	  html_file.write("<HEAD><TITLE>JFreeChart Image Map</TITLE></HEAD>\n")
	  html_file.write("<BODY>\n");
	end
	html_file.write(ChartUtilities.getImageMap("chart", info));

	if image_file
	  FileUtils.mv(temp_image_file, image_file)
	  html_file.write("<IMG SRC=\"#{image_file.to_s}\" " +
			  "WIDTH=\"#{width}\" HEIGHT=\"#{height}\" BORDER=\"0\" USEMAP=\"#chart\">\n")
	else
	  image_data = Base64.encode64(temp_image_file.open("r").read)
	  html_file.write("<IMG SRC=\"data:image/png;base64,#{image_data}\" " +
			  "WIDTH=\"#{width}\" HEIGHT=\"#{height}\" BORDER=\"0\" USEMAP=\"#chart\">\n")	  
	end
	if options[:layout].nil? or !options[:layout]
	  html_file.write("</BODY>\n");
	  html_file.write("</HTML>\n");
	end
	html_file.string
      else
	raise "Cannot render to #{mime_type.inspect}"
      end   
    }
  end

  private
  def jf_orientation(flipped = false)   
    case orientation 
    when nil, :horizontal
      if flipped
	PlotOrientation.VERTICAL
      else
	PlotOrientation.HORIZONTAL
      end
    when :vertical
      if flipped
	PlotOrientation.HORIZONTAL
      else
	PlotOrientation.VERTICAL
      end
    else
      raise "Unexpected orientation #{orientation.inspect}"
    end
  end

  def configure_renderer(renderer)
    configure_colors(renderer)
  end

  def configure_colors(renderer)
    paint_array = ChartColor.createDefaultPaintArray()
    second_color = Color.create("java","white").java_object
    i = 0
    if (false) 
      paint_array.each {|item|
	renderer.setSeriesPaint(i, GradientPaint.new(0.0, 0.0, item, 1000, 0.0, second_color))
	i += 1;
      }
    else
      paint_array.each {|item|
	renderer.setSeriesPaint(i, item)
	i += 1;
      }
    end
    
    paint_array.each {|item|
      bi = BufferedImage.new(2, 2, BufferedImage.TYPE_INT_RGB);
      big = bi.createGraphics();
      big.setColor(item);
      big.fillRect(0, 0, 1, 1);
      big.fillOval(1, 1, 2, 2);
      big.setColor(second_color);
      big.fillRect(1, 0, 2, 1);
      big.fillOval(0, 1, 1, 2);
      r = Rectangle.new(0, 0, 2, 2);
      renderer.setSeriesPaint(i,TexturePaint.new(bi, r))
      i += 1;
    }
    
    paint_array.each {|item|
      bi = BufferedImage.new(2, 2, BufferedImage.TYPE_INT_RGB);
      big = bi.createGraphics();
      big.setColor(item);
      big.fillRect(0, 0, 1, 1);
      big.fillOval(1, 0, 2, 1);
      big.setColor(second_color);
      big.fillRect(0, 1, 1, 2);
      big.fillOval(1, 1, 2, 2);
      r = Rectangle.new(0, 0, 2, 2);
      renderer.setSeriesPaint(i, TexturePaint.new(bi, r))
      i += 1;     
    }
  end

  def jf_xaxis
    name = [name, xaxis].compact.join(" ")
    case type
    when :line, :xy
      axis_obj = NumberAxis.new(name)
      axis_obj.setAutoRangeIncludesZero(false)
      axis_obj.setAutoRangeStickyZero(false)
      axis_obj.setAutoRange(true)
      axis_obj
    else
      axis_obj = CategoryAxis.new(xaxis)
      #axis_obj.setTickLabelFont(Font.new("SansSerif", Font.PLAIN, 8))
      #axis_obj.setTickLabelPaint(Color.create("java","red").java_object)



      clp = CategoryLabelPositions.new(
				       # TOP
              CategoryLabelPosition.new(
					RectangleAnchor.BOTTOM,
					TextBlockAnchor.BOTTOM_LEFT, 
					TextAnchor.BOTTOM_LEFT, 
					-legend_rotation,
					CategoryLabelWidthType.RANGE, 
					0.40),
				       # BOTTOM
	       CategoryLabelPosition.new(
					 RectangleAnchor.TOP, 
					 TextBlockAnchor.TOP_RIGHT,
					 TextAnchor.TOP_RIGHT, 
					 -legend_rotation,
					 CategoryLabelWidthType.RANGE,
					 0.40),
				       # LEFT
	       CategoryLabelPosition.new(
					 RectangleAnchor.RIGHT,
					 TextBlockAnchor.BOTTOM_RIGHT,
					 TextAnchor.BOTTOM_RIGHT, 
					 -legend_rotation,
					 CategoryLabelWidthType.RANGE,
					 0.40),
				       # RIGHT
		CategoryLabelPosition.new(
					  RectangleAnchor.LEFT,
					  TextBlockAnchor.TOP_LEFT,
					  TextAnchor.TOP_LEFT, 
					  -legend_rotation,
					  CategoryLabelWidthType.RANGE, 
					  0.40)
				       )


      #      clp = CategoryLabelPositions.createUpRotationLabelPositions(legend_rotation)
      
      axis_obj.setCategoryLabelPositions(clp) 
      axis_obj.getCategoryLabelPositions
      #axis_obj.setCategoryLabelPositionOffset(10) 
      
      axis_obj
    end
  end
  def jf_yaxis
    name = [name, yaxis].compact.join(" ")
    case type
    when :gantt
      DateAxis.new(name)
    else      
      axis_obj = NumberAxis.new(name)
      axis_obj.setAutoRangeIncludesZero(false)
      axis_obj.setAutoRangeStickyZero(false)
      axis_obj.setAutoRange(true)
      axis_obj
    end
  end
  def jf_zaxis(name = nil)
    name = [name, zaxis].compact.join(" ")
    CategoryAxis.new(name)
  end

  def jf_yvalue(value)
    case type
    when :gantt
      case value
      when DateTime,Date,Time
	Time.parse(value.strftime("%F %T")).to_f * 1000.0
      else
	Time.parse(value.to_s).to_f * 1000.0
      end
    else
      value.to_f
    end
  end

  # combined plot
  def create_combined_plot_implementation(data, combination_axis = :domain)
    cap_name = combination_axis.to_s.capitalize
    other_name = if combination_axis == :domain then "Range" else "Domain" end
    combined_axis_name = {:range => "yaxis", :domain => "xaxis"}[combination_axis]   

    axis_obj = eval("jf_#{combined_axis_name}")

    case type
    when :line,:xy
      plot_class = eval("Combined#{cap_name}XYPlot")
    else
      plot_class = eval("Combined#{cap_name}CategoryPlot")
    end
    
    plot = plot_class.new(axis_obj)
    
    num = 0
    data.each {|range_name, data|
      range_options = @range_options[range_name] or {}
      subplot = create_plot(range_name,data)
      #subplot.setRangeAxis(nil) if num > 0

      begin
	plot.add(subplot, data.values.map {|h| h.keys}.flatten.length)
      rescue
	$log.warn("Failed to determine weight #{$!}")
	plot.add(subplot)
      end

      eval("subplot.get#{other_name}Axis").setLabel(range_name)

      subplot.setOrientation(jf_orientation(true)) rescue $log.warn("Orientation not set #{$!}")
    }
    plot.setOrientation(jf_orientation) rescue $log.warn("Orientation not set #{$!}")    
    
    lis = plot.getLegendItems
    new_legend_collection = LegendItemCollection.new
    legend_labels = []
    lis.getItemCount.times {|i|
      li = lis.get(i)
      unless legend_labels.include?(li.getLabel)
	new_legend_collection.add(li)
	legend_labels << li.getLabel
      end
    }
    plot.setFixedLegendItems(new_legend_collection)
    plot
  end

  def create_plot_implementation(range_name, data, options = {})      
    range_options = @range_options[range_name] or {}
    range_options = @range_options.values[0] if range_name.nil? 

    case @type
    when :bar
      if stacked
	my_renderer = StackedBarRenderer.new
      else
	my_renderer = BarRenderer.new
      end
      
      #ItemLabelPosition position1 = new ItemLabelPosition(ItemLabelAnchor.OUTSIDE12, TextAnchor.BOTTOM_CENTER);
      #ItemLabelPosition position2 = new ItemLabelPosition(ItemLabelAnchor.OUTSIDE6, TextAnchor.TOP_CENTER);
      #renderer.setPositiveItemLabelPosition(position1);
      #renderer.setNegativeItemLabelPosition(position2);	
      #renderer.setDrawBarOutline(false);
      configure_renderer(my_renderer)

      #MyGenerator generator = new MyGenerator(this.URLPrefix, this.rangeNames[range], this);
      #my_renderer.setBaseItemURLGenerator(generator);
      #my_renderer.setBaseToolTipGenerator(generator);
      
      plot = CategoryPlot.new(create_category_dataset(data), 
			      jf_xaxis,
			      jf_yaxis,
			      my_renderer)
    when :line
      if @stacked
	my_renderer = StackedXYAreaRenderer2.new;
      else
	raise "not impl"
	my_renderer = StandardXYItemRenderer.new(StandardXYItemRenderer.SHAPES_AND_LINES);
      end
      configure_renderer(my_renderer)
      #MyGenerator generator = new MyGenerator(@URLPrefix, @rangeNames[range], this);
      #      my_renderer.setURLGenerator(generator);
      #      my_renderer.setBaseToolTipGenerator(generator);
      #
      #
      
      plot = XYPlot.new(create_xy_dataset(data),
			jf_xaxis, 
			jf_yaxis,
			my_renderer)
    when :gantt      
      my_renderer = GanttRenderer.new

      my_renderer.setBaseItemURLGenerator(StandardCategoryURLGenerator.new) if 
	enable_urls
      
      configure_renderer(my_renderer)
      
      plot = CategoryPlot.new(create_task_series_collection(data),
			      jf_xaxis, jf_yaxis, my_renderer)
    when :pie
      plot = MultiplePiePlot.new(create_category_dataset(data));
      plot.setDataExtractOrder(TableOrder.BY_ROW);
      plot.setOutlineStroke(nil);
      
#      if (enable_tooltips) 
#	tooltipGenerator = StandardPieToolTipGenerator.new();
#	pp = plot.getPieChart().getPlot();
#	pp.setToolTipGenerator(tooltipGenerator);
#      end
      
      if (enable_urls)
	urlGenerator = new StandardPieURLGenerator();
	pp = plot.getPieChart().getPlot();
	pp.setURLGenerator(urlGenerator);
      end
      
#      plot = @chart.getPlot();	
#      subchart = plot.getPieChart();
    
#    p = subchart.getPlot();
    # /*       p.setLabelGenerator(new StandardPieItemLabelGenerator("{0}"));*/
    #    p.setLabelFont(Font.new("SansSerif", Font.PLAIN, 8));
#    p.setInteriorGap(0.30);
    #generator = MyGenerator.new(this.URLPrefix,this.category_datasets[0]);
    #p.setURLGenerator(generator);
    #	// p.setToolTipGenerator(generator);


    else
      raise "Unexpected chart type #{@type}"
    end

    if enable_tooltips and my_renderer and my_renderer.getClass.toString =~ /category/
      generator = JfreechartGenerator.new(self, range_name)
      generator = Rjb::bind(generator, "org.jfree.chart.labels.CategoryToolTipGenerator")
      my_renderer.setBaseToolTipGenerator(generator) rescue "Unable to set tooltip generator: #{$!}"
    end

    plot.setOrientation(jf_orientation) rescue $log.warn("Orientation not set #{$!}")
    
    @options ||= {}
    range_options ||= {}
    ((@options[:markers] or []) + (range_options[:markers] or [])).each {|marker|
      new_maker = nil

      case marker[:type]
      when :value
	# value marker
	marker[:layer] ||= :front
	new_marker = ValueMarker.new(jf_yvalue(marker[:value]))
	new_marker.setLabelTextAnchor(TextAnchor.TOP_LEFT)
	new_marker.setLabel(marker[:name])
      when :interval
	# range marker
	marker[:layer] ||= :back
	new_marker = IntervalMarker.new(jf_yvalue(marker[:start]),jf_yvalue(marker[:end]));
	new_marker.setLabelTextAnchor(TextAnchor.CENTER_LEFT)
	new_marker.setLabelAnchor(RectangleAnchor.LEFT)
	new_marker.setLabel(marker[:name])
      when :category
	marker[:layer] ||= :back
	new_marker = CategoryMarker.new_with_sig("Ljava.lang.Comparable;",marker[:key])
      end
      
      new_marker.setLabelFont(Font.new("SansSerif", Font.BOLD, 11))
      new_marker.setPaint(Color.create("java",(marker[:color] or "red")).java_object)
      new_marker.setAlpha(1.0)

      case marker[:layer].to_s
      when "foreground", "front",""
	layer = Layer.FOREGROUND
      when "back","background"
	layer = Layer.BACKGROUND
      else
	raise "Unexpected layer value #{marker[:layer].inspect}"
      end

      case marker[:axis]
      when :range
	plot.addRangeMarker(new_marker,layer)
      when :domain
	plot.addDomainMarker(new_marker,layer)
      else
	raise "Unexpected marker axis"
      end
    }
    

    if range_color = range_options[:color]	
      plot.setBackgroundPaint(Color.create("java",range_color).java_object)
    else
      plot.setBackgroundPaint(Color.create("java","LightGray").java_object)
    end

    plot.setDomainGridlinePaint(Color.create("java","white").java_object) rescue $log.warn("setDomainGridlinePaint failed: #{$!}")
    plot.setRangeGridlinePaint(Color.create("java","white").java_object) rescue $log.warn("setRangeGridlinePaint failed: #{$!}")
    #plot.clearDomainAxes();    

    plot
  end

  def create_chart_implementation(plot)  
    @chart = JFreeChart.new(@title, nil, plot, display_legend)
    @chart.setBackgroundPaint(Color.create("java","white").java_object)
    
    @chart
  end
	     
  def to_date(obj)
    c = Calendar.getInstance
    case obj
    when String
      obj = DateTime.parse(obj) rescue raise("#{$!}: #{obj}")
    when Date,DateTime
    else
      raise "Unexpected data class #{obj.class}"
    end
    # !month is 0 based in java!
    c.set(obj.year, obj.month - 1, obj.day, obj.hour, obj.min, obj.sec)
    c.getTime()
  end


  # Data Sets
  def create_xy_dataset(data)
    # STRING x VAL x VAL
    # means STRING x STRING x VAL
    # means SERIE x CATEGORY x ARRAY[0]
    
    # add(Number x, Number y, String seriesName, boolean notify)
    xy_dataset = CategoryTableXYDataset.new
    data.each {|serie_name, category|
      category.each {|category_name, val|    
	xy_dataset.add(category_name.to_f, val.to_f, serie_name)
      }
    }
    xy_dataset
  end

  def create_category_dataset(data)
    # STRING x STRING x VAL
    # means SERIE x CATEGORY x ARRAY[0]    
    category_dataset = DefaultCategoryDataset.new    
    data.each {|serie_name, category|
      category.each {|category_name, val|
	# addValue(Number value, Comparable rowKey, Comparable columnKey)
	category_dataset._invoke("addValue",
				 "Ljava.lang.Number;Ljava.lang.Comparable;Ljava.lang.Comparable;",
				 val.to_i,category_name,serie_name)
      }
    }
    category_dataset    
  end

  # Task Series
  def create_task_series_collection(data)
    # STRING x TASK
    m_series = TaskSeriesCollection.new
    data.each {|serie_name, values|
      m_serie = TaskSeries.new((serie_name or ""))

      values.each {|key, value|
	task = create_task(key,value)	  
	m_serie.add(task)	  	 
	if value.class == Hash and  value[:children]
	  value[:children].each {|key, value|
	    task.addSubtask(create_task(key,value))
	  }
	end
      }
      m_series.add(m_serie)
    }
    m_series
  end

  # data: [start,end,percentage] or {:start => start, :end => end, :percentage}
  def create_task(name, data)
    data = [data[:start],data[:end], data[:percentage]] if data.class == Hash
    
    $log.debug("Create Task #{name.inspect}: #{data[0].inspect} - #{data[1].inspect} (#{data[2].inspect})")
    period = SimpleTimePeriod.new(to_date(data[0]),to_date(data[1]))
    task = Task.new(name.to_s,period)
    task.setPercentComplete(data[2].to_f) if data[2]
    task
  end
end
=begin
    public GanttDemo1(final String title) {

        super(title);

        final IntervalCategoryDataset dataset = createDataset();
        final JFreeChart chart = createChart(dataset);

        # add the chart to a panel...
        final ChartPanel chartPanel = new ChartPanel(chart);
        chartPanel.setPreferredSize(new java.awt.Dimension(500, 270));
        setContentPane(chartPanel);

    

        final TaskSeriesCollection collection = new TaskSeriesCollection();
        collection.add(s1);
        collection.add(s2);

        return collection;
    }

    /**
     * Utility method for creating <code>Date</code> objects.
     *
     * @param day  the date.
     * @param month  the month.
     * @param year  the year.
     *
     * @return a date.
     */
    private static Date date(final int day, final int month, final int year) {

        final Calendar calendar = Calendar.getInstance();
        calendar.set(year, month, day);
        final Date result = calendar.getTime();
        return result;

    }
        
    /**
     * Creates a chart.
     * 
     * @param dataset  the dataset.
     * 
     * @return The chart.
     */
    private JFreeChart createChart(final IntervalCategoryDataset dataset) {
    }
    
    /**
     * Starting point for the demonstration application.
     *
     * @param args  ignored.
     */
    public static void main(final String[] args) {

        final GanttDemo1 demo = new GanttDemo1("Gantt Chart Demo 1");
        demo.pack();
        RefineryUtilities.centerFrameOnScreen(demo);
        demo.setVisible(true);

    }

end
=end
