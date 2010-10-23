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
require "libisi/concept"
require "libisi/instance"

class ConceptTest < Test::Unit::TestCase

  def test_concept
    assert c = Concept.create(String)
    # a base ruby class has no attributes
    assert_equal [], c.attributes
  end

  def test_activerecord
    sqlite = Uri.create("sqlite3://localhost/#{File.dirname(__FILE__) + "/fixtures/test.db/t1"}")
    first_record = sqlite.find(:first)
    ar_class = first_record.class
    
    assert c = Concept.create(ar_class)
    assert c.class == ActiverecordConcept
    assert_equal ["data", "num", "t1key", "timeEnter"],
      c.attribute_names.sort

    assert c.value_accessors

    attrs = c.attributes.sort_by {|a| a.name}
    assert_equal [:text, :float, :integer, :date],attrs.map {|a| a.type}    

    assert inst = Instance.create(first_record)
    assert val = inst.value("data")

    assert_equal "", val.inspect
  end

  

end
