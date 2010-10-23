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

class JfreechartGenerator

  def initialize(chart, range_name, options = {})
    @chart = chart
    @range_name = range_name
    @options = options
  end

  def generateToolTip(dataset,row,column)
    row_key = dataset.getRowKey(row).toString
    col_key = dataset.getColumnKey(column).toString
      
    #p ["R", row, row_key,"C",column,col_key]
    "Range: #{@range_name} Row: #{row_key} Col: #{col_key}"
    

    case @options[:tooltip]
    when NilClass
      begin
	data = @chart.ranges[@range_name][row_key][col_key]      
	#p data
	ret = "#{row_key}/#{col_key}"
	ret += " #{data[:start]} - #{data[:end]}" if data[:start]
	ret += " (#{data[:percentage].to_s})" if data[:percentage]
	ret
      rescue
	"#{@range_name}/#{row_key}/#{col_key} (dnf)"
      end
    when Proc
      @options[:tooltip].call(range_name, row_key, col_key)
    when String
      @options[:tooltip]
    else
      raise "Unexpected tooltip class #{options[:tooltip]}"
    end
  rescue
    $log.error($!)
    $log.error($!.backtrace.join("\n"))
    nil
  end

end

=begin
    public class MyGenerator implements CategoryURLGenerator,
					CategoryToolTipGenerator,
					PieURLGenerator,
					PieToolTipGenerator,
					XYURLGenerator,
					XYToolTipGenerator   {
	private String prefix = "index.html";
	private String seriesParameterName = "series";
	private String categoryParameterName = "category";
	private String rangeParameterName = "range";
	private String rangeKey = null;
	private CreateChart createChart = null;

	private CategoryDataset theDataset = null;
	
	public MyGenerator(String prefix, CategoryDataset ds) {
	    super();
	    this.prefix = prefix;
	    this.theDataset = ds;
	}
	
	public MyGenerator(String prefix) {
	    this.prefix = prefix;
	}
	public MyGenerator(String prefix, String rangeKey, CreateChart createChart) {
	    this.prefix = prefix;
	    this.rangeKey = rangeKey;
	    this.createChart = createChart;
	}
	
	public MyGenerator(String prefix,
				      String seriesParameterName,
				      String categoryParameterName) {
	    this.prefix = prefix;
	    this.seriesParameterName = seriesParameterName;
	    this.categoryParameterName = categoryParameterName;
	}

	public MyGenerator(String prefix,
				      String seriesParameterName,
				      String categoryParameterName,
				      String rangeParameterName,
				      String rangeKey) {
	    this.prefix = prefix;
	    this.seriesParameterName = seriesParameterName;
	    this.categoryParameterName = categoryParameterName;
	    this.rangeParameterName = rangeParameterName;
	    this.rangeKey = rangeKey;
	}
	
	public String myGenerateURL(Comparable seriesKey, Comparable categoryKey, Comparable rangeKey) {
	    if (categoryKey.toString().equals("<<REST>>") || 
		seriesKey.toString().equals("<<REST>>") ||
		(rangeKey != null && rangeKey.toString().equals("<<REST>>"))) { return "";}

	    String url = this.prefix;
	    boolean firstParameter = url.indexOf("?") == -1;

	    if (categoryKey.toString().equals("rest_value")) { return "";}
	    if (seriesKey.toString().equals("rest_serie")) { return "";}
	    
	    url += firstParameter ? "?" : "&";
	    try {
		url += this.seriesParameterName + "=" 
		    + URLEncoder.encode(seriesKey.toString(),"UTF-8");
		url += "&" + this.categoryParameterName + "=" 
                + URLEncoder.encode(categoryKey.toString(),"UTF-8");
		if (rangeKey != null) {
		    url += "&" + this.rangeParameterName + "=" 
			+ URLEncoder.encode(rangeKey.toString(),"UTF-8");
		}
	    }
	    catch ( java.io.UnsupportedEncodingException uee ) {
		uee.printStackTrace();
	    }	
	    
	    return url;	   	    	   	    
	}
	
	public String myGenerateToolTip(Comparable seriesKey, Comparable categoryKey, Comparable rangeKey, Number value) {	    
	    String text = "";
	    if (this.rangeKey != null && !this.rangeKey.equals("<<NULL>>")) {
		text += this.rangeKey + ", ";
	    }
	    
	    if (seriesKey != null && !seriesKey.toString().equals("<<NULL>>")) {
		text += seriesKey.toString() + ", ";
	    }

	    text += this.createChart.xAxis + "=" + categoryKey.toString() + ", ";
	
	    text += "value: " + value;
	    return text;	    
	}

	/** Pie **/

	public String generateURL(PieDataset data, Comparable categoryKey, int pieIndex) {    	    
	    Comparable seriesKey = theDataset.getRowKey(pieIndex);
	    return myGenerateURL(seriesKey, categoryKey, null);
 	}
	public String generateToolTip(PieDataset data, Comparable categoryKey) {
	    /** not working **/
	    Comparable seriesKey = theDataset.getRowKey(0);
	    return myGenerateToolTip(seriesKey, categoryKey, null,999);
	}

	
	/** Category **/

	public String generateURL(CategoryDataset dataset,
				  int series, 
				  int category) {	    
	    Comparable seriesKey = dataset.getRowKey(series);
	    Comparable categoryKey = dataset.getColumnKey(category);

	    return myGenerateURL(seriesKey, categoryKey, this.rangeKey);
	}

	public String generateToolTip(CategoryDataset dataset, 
				      int series, int category) {
	    Comparable seriesKey = dataset.getRowKey(series);
	    Comparable categoryKey = dataset.getColumnKey(category);

	    return myGenerateToolTip(seriesKey, categoryKey, this.rangeKey,dataset.getValue(seriesKey,categoryKey));
	}

	/** XY **/
	public String generateURL(XYDataset dataset, int series, int item) {
	    Comparable seriesKey = dataset.getSeriesKey(series);
	    Comparable categoryKey = (Comparable)dataset.getX(series,item);

	    return myGenerateURL(seriesKey, categoryKey, this.rangeKey);
	}

	public String generateToolTip(XYDataset dataset, int series, int item) {
	    Comparable seriesKey = dataset.getSeriesKey(series);
	    Comparable categoryKey = (Comparable)dataset.getX(series,item);

	    return myGenerateToolTip(seriesKey, categoryKey, this.rangeKey,dataset.getY(series,item));
	}


    }
=end
