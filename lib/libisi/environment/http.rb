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

require "libisi/environment/base"
require 'net/http'
require 'net/https'

# Environment accessible over http or https
class HttpEnvironment < BaseEnvironment

  def initialize(uri, options = {})
    @uri = uri
    super(nil)
  end

  def type; :http_access; end
  def implementation; :ruby; end
  def uri; @uri; end

  def uri_from_task(task, options = {})
    m_uri = uri.to_s
    m_uri = m_uri[0..-2] if m_uri =~ /\/$/
    m_uri += "/" + task.function.context
    m_uri += "/" + task.function.name
    m_uri += "/" + task.parameter.arguments.join("/")

    params = task.parameter.options.reject {|name, vals|
      [:input_stream,:output_stream].include?(name)      
    }.map {|name, vals|
      case vals
      when Array, NilClass
      when String
	vals = [vals]
      else
	raise "Dont know how to parametrize class #{vals.class}"
      end
      
      vals.map {|val|
p [name, val]
	if val
	  "#{name}=#{CGI.escape(val)}"
	else
	  name
	end
      }
    }.join("&")
    URI.parse(m_uri + "?" + params)
  end

  def execute(task, options = {})
    url = uri_from_task(task, options)

    # TODO: initialize header
    headers = nil
    #headers = {
    #  'Cookie' => @cookie,
    #  'Referer' => 'http://profil.wp.pl/login.html',
    #  'Content-Type' => 'application/x-www-form-urlencoded'
    #}
    request = Net::HTTP::Get.new([url.path,url.query].compact.join("?"), headers)

    # TODO: login
    # request.basic_auth 'account', 'password'
    response = Net::HTTP.start(url.host, url.port) {|http|
      http.request(request)
    }
    
    # TODO: implement more responses
    case response
    when Net::HTTPSuccess     then response
      # only sucess are allowed at the moment
      #$log.info("Request sucessfuly done")
      #  when Net::HTTPRedirection then fetch(response['location'], limit - 1)
    else
      raise response.error!
    end

    # TODO: set cookie environment
    #@cookie = resp.response['set-cookie'] if
    #  resp.response['set-cookie'] if          

    if out = task.parameter.options[:output_stream]
      out.write(response.body)
      out.close_write
      #response.read_body(task.parameter.options[:output_stream])
    else
      response.body
    end
  end
  
end
