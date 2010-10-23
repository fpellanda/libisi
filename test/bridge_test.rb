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
require "libisi/bridge"

class BridgeTest < Test::Unit::TestCase
  class Req
    def cfg; end
    def str; end
  end
  def test_moin
    Bridge.load("python")
    kapozh_theme = PythonBridge.import "MoinMoin.theme.kapozh"    

    request_module = PythonBridge.import "MoinMoin.request"
    request = request_module.RequestCLI



    p(k = kapozh_theme.Theme(request))
    p k.header(k,{:request => "K"})
return 
    user_module = PythonBridge.import "MoinMoin.user"

    request = request_module.RequestBase()
    
    
#    request.setup_args()
    #    request.args = request.setup_args()
#    request.user = user_module.User(request)


    #    r.normalizePagename("lkj")
    #    p request.Clock.value
    #    p request.RequestBase("")
    
    kapozh_theme.execute(Req.new)
  end

  def test_java_bridge
    Bridge.load("java")
    df = JavaBridge.import("java.text.DateFormat")

    format = df.getDateTimeInstance(df.MEDIUM, df.SHORT);
    
    assert_equal "Tue Nov 04 20:14:00 CET 2003", format.parse("Nov 4, 2003 8:14 PM").toString
  end  


  def test_python_bridge
    Bridge.load("python")

    cPickle=RubyPython.import "cPickle"
    assert_equal "S'RubyPython is awesome!'\n.", cPickle.dumps("RubyPython is awesome!")
    assert_equal "(dp1\nS'a'\nS'b'\ns.", cPickle.dumps({"a" => "b"})
  end

end
