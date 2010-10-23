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

class UiTest < Test::Unit::TestCase

  def do_test(ui)
    change_ui(ui)

    assert_equal :yes, $ui.question_yes_no("Select yes")
    assert_equal :no, $ui.question_yes_no("Select no")
    assert_equal :retry, $ui.question_yes_no_retry("Select retry")

    sel = $ui.select(["A","B","C"])
    $ui.info("You selected #{sel.inspect}")
    sel = $ui.select_index(["A","B","C"])
    $ui.info("You selected indexes #{sel.inspect}")
    
    $ui.info_non_blocking("Test nonblocking")
    $ui.info("Information")
    $ui.warn("Warning")
    $ui.error("Error")
    
    pw = "abcd/\\"
    assert_equal pw, $ui.password("Please enter password '#{pw}'")
    
    assert $ui.question("Say yes", {:default => true})
    assert !$ui.question("Say no", {:default => false})

  end
  
  def test_console
    do_test("console")
  end

  def test_x11
    do_test("x11")
  end

  def test_kde
    do_test("kde")
  end

end
