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
require "libisi/request/http"
require "libisi/environment/http"
require "libisi/function/base"
require "libisi/task/base"
require "libisi/task/http"
require "libisi/parameter/base"
require "libisi/reciever/socket"

class RequestTest < Test::Unit::TestCase

  FULL_URI = URI.parse("http://www.example.com/context/function/arg1/arg2?param1=val1&param2=val2")
  ARGS = ["arg1","arg2"]
  OPTIONS = {:param1 => ["val1"], :param2 => ["val2"]}
  BODY_CONTENT = "<html></html>"

  def test_http_parse
    req = HttpRequest.from_uri(FULL_URI)

    assert req
    assert_equal HttpRequest, req.class
    assert req.environment
    assert_equal "http://www.example.com/", req.environment.uri.to_s
    assert task = req.task

    assert task.function
    assert_equal "context", task.function.context
    assert_equal "function", task.function.name
    assert task.parameter
    assert ARGS, task.parameter.arguments
    assert_equal(OPTIONS, task.parameter.options)
       
  end

  def test_http_parse_rev
    param = BaseParameter.new
    param.options = OPTIONS
    param.arguments = ARGS

    r = HttpRequest.new(HttpEnvironment.new(URI.parse("http://www.example.com/")),
			BaseTask.new(
				     BaseFunction.new("context","function"),
				     param
				     )
			)
    assert_equal FULL_URI, r.environment.uri_from_task(r.task)
  end

  def test_socket
    reciever = SocketReciever.new(3333) {|io|
      task = HttpTask.from_browser(io)
      # task.parameter.stdin.gets
    }
    success = false
    t = Thread.new { 
      begin
	sleep 0.1
	req = HttpRequest.from_uri(FULL_URI)
	req.environment = HttpEnvironment.new(URI.parse("http://127.0.0.1:3333"))
	assert_equal BODY_CONTENT, req.execute    
	success = true
      rescue
	print "#{$!}\n"
	$!.backtrace.each {|l| print "#{l}\n"}
      end
    }
    
    p "Start recieving"
    task = reciever.get
    assert task
    assert task.function.context
    assert task.function
    assert_equal "context", task.function.context
    assert_equal "function", task.function.name
    assert task.parameter
    assert ARGS, task.parameter.arguments

    opts = task.parameter.options.dup
    input = opts.delete(:input_stream)
    output = opts.delete(:output_stream)
    assert_equal({:http_version => "1.1",:request_method => "GET"}.merge(OPTIONS), opts)
    assert input
    assert output
    
    
    input.write("HTTP/1.0 200 OK\n\n" + BODY_CONTENT)
#Content-Type: text/html
#
#<html>
#  <body>
#    <h1>Hello World</h1>
#  </body>
#</html>
#EOF
    input.close_write

    t.join
    assert success, "Thread failure"
  end

end
