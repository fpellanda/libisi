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

$LOAD_PATH.insert(0,File.dirname(__FILE__) + "/../lib/")
require 'test/unit'
require "libisi"
init_libisi
require "libisi/chart"

class ChartTest < Test::Unit::TestCase
  TEMP_DIR = Pathname.new("/tmp/chart_test/")

  def save_chart(chart, name)
    TEMP_DIR.mkdir unless TEMP_DIR.exist?
    chart.save(TEMP_DIR + "#{name}.png")
    chart.save(TEMP_DIR + "#{name}.html", :image_file => TEMP_DIR + "#{name}_html.png")
    chart.save(TEMP_DIR + "#{name}_inline.html")
  end

  def test_bar_chart
    chart = Chart.create("jfreechart")
    chart.type = :bar

    chart.range("Range 1") {
      chart.serie("Serie 1") {
	chart.value("Value 1", 1)
	chart.value("Value 2", 3)
	chart.value("Value 3", 2)
	chart.value("Value 4", 2)
      }
      chart.serie("Serie 2") {
	chart.value("Value 1", 6)
	chart.value("Value 2", 7)
	chart.value("Value 3", 8)
      }
    }
    chart.range("Range 2") {
      chart.serie("Serie 1") {
	chart.value("Value 1", 7)
	chart.value("Value 2", 4)
	chart.value("Value 3", 1)
	chart.value("Value 4", 1)
      }
      chart.serie("Serie 2") {
	chart.value("Value 1", 1)
	chart.value("Value 2", 7)
	chart.value("Value 3", 2)
      }
    } 
    
    chart.create_chart(nil, :combined_axis => :domain)
    save_chart(chart,"bar1")
    chart.create_chart(nil, :combined_axis => :range)
    save_chart(chart,"bar2")
  end

  def test_line_chart
    chart = Chart.create("jfreechart")
    chart.type = :line

    chart.serie("Serie 1") {
      chart.value("1", 1)
      chart.value("2", 3)
      chart.value("3", 2)
      chart.value("4", 2)
    }
    chart.serie("Serie 2") {
      chart.value("1", 6)
      chart.value("2", 7)
      chart.value("3", 8)
    }

    save_chart(chart,"line")
  end

  def test_pie_chart
    chart = Chart.create("jfreechart")
    chart.type = :pie

    chart.serie("Serie 1") {
      chart.value("Value 1", 1)
      chart.value("Value 2", 3)
      chart.value("Value 3", 2)
      chart.value("Value 4", 2)
    }
    chart.serie("Serie 2") {
      chart.value("Value 1", 6)
      chart.value("Value 2", 7)
      chart.value("Value 3", 8)
    }

    chart.create_chart(nil, :combined_axis => :domain)
    save_chart(chart,"pie_domain")
    chart.create_chart(nil, :combined_axis => :range)
    save_chart(chart,"pie_range")
  end

  def test_gantt_chart
    chart = Chart.create("jfreechart")
    working_col = Color.create("colortools", "#f12f3f")

    chart.mark("Burn","2009-08-01","2009-08-04", :color => :red, :layer => :foreground)
    
    chart.range("Superproject 1", :color => working_col.html) {
      working_col.brightness("20%")
      chart.mark("Summer","2009-07-01","2009-09-31", :color => working_col.html)
      
      chart.serie("Project 1") {
	chart.mark("Birthday","2009-08-25", :color => :green)
	chart.time_span("Task1","2009-01-01","2009-01-31")
	chart.time_span("Task2","2009-01-01","2009-02-27", :percentage => 0.9)
	chart.time_span("LongTask3","2009-01-15","2009-06-26")
      }
      
      chart.serie("Project 2") {
	chart.time_span("Task1","2009-05-01","2009-09-30")
	chart.time_span("Task2","2009-08-01","2009-09-30", :percentage => 0.4) {
	  chart.time_span("Sub Task2.1","2009-08-07","2009-09-30", :percentage => 0.4)
	}
	chart.time_span("Task4","2009-07-15","2009-12-26", :percentage => 0.7) {
	chart.time_span("Sub Task4.1","2009-07-15","2009-11-26", :percentage => 1.0)
	  chart.time_span("Sub Task4.2","2009-12-01","2009-12-20", :percentage => 0.3)
	}
      }
    }

    chart.range("Superproject 2", :color => "yellow") {
      working_col.hue("-20%")
      chart.mark("Summer","2009-07-01","2009-09-31", :color => working_col.html)
      chart.mark("Now",DateTime.now)

      chart.serie("Project 1") {
	chart.time_span("Task1","2009-04-01","2009-04-30")
	chart.time_span("Task2","2009-04-01","2009-05-31", :percentage => 0.9)
	chart.time_span("Task3","2009-04-15","2009-09-26")
      }
      
      chart.serie("Project 2") {
	chart.mark(:color => "blue") {
	  chart.time_span("Task1","2009-05-01","2009-10-31")
	chart.time_span("Task2","2009-08-01","2009-11-30", :percentage => 0.4) {
	  chart.time_span("Sub Task2.1","2009-08-07","2009-10-12", :percentage => 0.4)
	}
	}
	chart.time_span("Task4","2009-07-15","2009-12-26", :percentage => 0.7) {
	  chart.time_span("Sub Task4.1","2009-07-15","2009-11-26", :percentage => 1.0)
	  chart.time_span("Sub Task4.2","2009-12-01","2009-12-20", :percentage => 0.3)
	}
      }
    }
    chart.range("Superproject 3", :color => "yellow") {
      working_col.brightness("20%")
      chart.mark("Summer","2009-07-01","2009-09-31", :color => working_col.html)
      chart.serie("Project 1") {
	chart.time_span("Task3","2009-04-15","2009-09-26")
      }      
    }  

    chart.create_chart(nil, :combined_axis => :range)
    save_chart(chart,"gantt1_range")
    chart.create_chart(nil, :combined_axis => :domain)
    save_chart(chart,"gantt1_domain")
  end

end
