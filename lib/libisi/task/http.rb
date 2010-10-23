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

require "libisi/task/base"
require "libisi/function/base"
require "libisi/parameter/base"
require "cgi"
class HttpTask < BaseTask

  # Splits the rest of the uri path into context,
  # function name and arguments.
  # 
  # First regular expression match as context
  # Second regular expression match as function name
  # the rest of the matches as arguments
  DEFAULT_CONTEXT_NAME_ARG_REGEXP =
    /^\/?([^\/]+)\/([^\/]+)\/(.+)$/

  def HttpTask.from_path(path, options = {})
    unless path =~ DEFAULT_CONTEXT_NAME_ARG_REGEXP
      raise "context name arg regular expression did not match #{path.inspect}"
    end
    context = $1
    function_name = $2
    arguments = $3.split("/")

    # function
    func = BaseFunction.new(context, function_name)

    # parameter
    params = BaseParameter.new
    params.arguments = arguments

    HttpTask.new(func, params)
  end

  def HttpTask.from_path_with_parameters(full_path, options = {})
    path, query = full_path.split("?",2)
    task = HttpTask.from_path(path, options)
    if query
      n_opts = {}
      CGI::parse(query).each {|key,val|
	n_opts[key.to_sym] = val
      }
      task.parameter.options = task.parameter.options.merge(n_opts)
    end
      
    task
  end

  def HttpTask.from_browser(io, options = {})
    p "gets"
    request_line = io.gets
    p "request_line: #{request_line}"
    # base from webrick/httprequest.rb read_request_line(socket)
    if /^(\S+)\s+(\S+)(?:\s+HTTP\/(\d+\.\d+))?\r?\n/mo =~ request_line
      request_method = $1
      unparsed_uri   = $2
      http_version   = ($3 ? $3 : "0.9")

      request = HttpTask.from_path_with_parameters(unparsed_uri)
      request.parameter.options[:http_version] = http_version
      request.parameter.options[:request_method] = $1
      request.parameter.options[:input_stream] = io
      request.parameter.options[:output_stream] = io
      request

      # TODO: read parameters
    else
      rl = request_line.sub(/\x0d?\x0a\z/o, '')
      raise "Bad request #{rl.inspect}"
    end
  end
	

end
