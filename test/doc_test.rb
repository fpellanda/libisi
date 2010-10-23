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

  # TODO
  #    test_doc("text", "text")
  #    test_doc("html")
  #    test_doc("html", "html")
  #    test_doc("text", "html")
  #    test_doc("html","text")
  
  
  def test_text
    do_test("text")
  end
  def test_html
    do_test("html")
  end
 
  def do_test(doc, together_with = nil)
    Doc.change(doc)
    output_document = Pathname.new("/tmp/test.#{together_with}")
    
    if together_with
      output_document.delete if output_document.exist?    
      add_output(output_document)
      # the output to file should be first
      $doc.children = $doc.children.reverse if $doc.class == Tee
    end
    
    title_call_count = 0
    td_call_count = 0
    table_call_count = 0
    $doc.title("Title 1") {
      title_call_count += 1
      raise "Called title block the 2nd time" if title_call_count == 2
      $doc.table(:columns => ["a","bb","ccc"]) {|col, index|
	$log.debug("Called table block #{col} #{index}")
	table_call_count += 1
	#      raise "Called table block the 1st time" if table_call_count == 1
	raise "Called table block the 4th time" if table_call_count == 4      
	raise "col is nil" if col.nil?
	
	# still a problem here:
	# table calls td td, td td, td td in 3 blocks (see doc/base.rb)
	# the teed will call td td td td td,, because it exits not
	# out of the table call function
	$doc.td { 
	  td_call_count += 1
	  raise "Called td block the 4th time" if td_call_count == 4
	col + "1" 
	}  
	$doc.td { col + "2" }  
      }
    }
    raise "Call count is not 3 its #{table_call_count}" unless td_call_count == 3
    raise "Call count is not 3 its #{td_call_count}" unless td_call_count == 3
    
    $doc.title("Title 2") {
      $doc.title("Title 2.1") {
	$doc.table(:items => ["x","yy","zzz"]) {|item, index|
	  raise "item is nil" if item.nil?
	  $doc.th { item.upcase }
	  $doc.td { item + "a"}
	  $doc.td { item + "b"}
	}
	
	$doc.table(:items => ["x","yy","zzz"]) {|item|
	  raise "item is nil" if item.nil?
	  $doc.th { item.upcase }
	  $doc.td { item + "a"}
	  $doc.td { item + "b"}
	}
      }
      $doc.title("Title 2.2") {
	$doc.table(:columns => ["a","bb","ccc"], :items => ["xxx","yy","z"]) {|item, col, item_index, column_index|
	  raise "item is nil" if item.nil?
	  raise "col is nil" if col.nil?
	  "#{item}.#{col}"
	}
      }
      
    }
    
    gba = ["aaa","bbb","ccc","aaab","aaac","bbbd"]
    
    $doc.table(:items => gba, :group_bys => [lambda {|e| e.length},lambda {|e| e[0..1] }])
    $doc.table(:items => gba, :group_bys => [lambda {|e| e.length},lambda {|e| e[0..1] }]) {|e|
      $doc.td {e.upcase}
    }
    
    call_times = 0
    $doc.table(:items => gba, 
	       :columns => ["length","first", "item_text1","item_text2"],
	       :group_bys => [lambda {|e| e.length},lambda {|e| e[0..0] }]) {|e,col,i1,i2|
      call_times += 1
      raise "Block called #{call_times} times instead of 19"  if call_times == 20
      [e,col, i1,i2].inspect
    }
    raise "Block called #{call_times} times instead of 19"  if call_times != 19


    gba = ["aaa","bbb","ccc","aaab","aaac","bbbd","aaA","AaA"]
    # ok, some more complicated grouping with different options
    options = 
    $doc.table(:items => gba,
	       :style => "border:1 solid black;",
	       :writer => Pathname.new("/tmp/test.html").open("w"),
	       :before_group_function0 => Proc.new {|options|
		 $doc.tr { $doc.th(:colspan => 5) { "BeforeTotal0 #{options[:group_items].inspect}"}}
	       },
	       :after_group_function0 => Proc.new {|options|
		 $doc.tr { $doc.th(:colspan => 5) { "Total0       #{options[:group_items].inspect}"}}
	       },
	       :before_group_function1 => Proc.new {|options|
		 $doc.tr { $doc.th(:colspan => 5) { "BeforeTotal1 #{options[:group_items].inspect}"}}
	       },
	       :after_group_function1 => Proc.new {|options|
		 $doc.tr { $doc.th(:colspan => 5) { "Total1       #{options[:group_items].inspect}"}}
	       },
	       :span_grouping => true,
	       :columns => [
		 [:length, ["length","textagain"]],
		 [:capitalize, ["capitalized", "again"]],
		 [nil, ["item"]]
	       ].to_hash
	       ) {|object, column, item_index, column_index, options|
      #      call_times += 1
      #      raise "Block called #{call_times} times instead of 19"  if call_times == 20
      #      [e,col, i1,i2].inspect
      #p column
#      "Col:" + column.inspect + 
#	" Obj:" +  object.inspect + 
		" Gk:" + options[:group_keys].inspect + 
#		" Ge:" + options[:group_elements].inspect +
		" Gi:" + options[:group_items].inspect + 
#		" Gci:" + options[:group_column_index].inspect +
	""
    }
    

    $doc.end_doc
    $doc.close
    p benchmark("bla") { "jk" }
    if together_with
      raise "#{o.to_s} does not exist!" unless output_document.exist?
      raise "#{o.to_s} has size zero" if output_document.size == 0
      raise "Output not equal to fixture" unless system("diff fixtures/output.#{together_with} #{output_document}")
    end
  end
end
