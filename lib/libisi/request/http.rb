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

require "libisi/request/base"
require "libisi/environment/http"
require "libisi/function/base"
require "libisi/task/base"
require "libisi/parameter/base"
require "uri"
require "cgi"

class HttpRequest < BaseRequest


  # Splits a ordinary http url into 
  # * HttpEnvironment
  # * Task(Function and Parameters)
  def HttpRequest.from_uri(uri, options = {})
    raise "Unexpected uri provided #{uri.parse}" unless uri.class == URI::HTTP
    options = {
      :root => URI::HTTP.build(:scheme => uri.scheme,
		       :userinfo => uri.userinfo,
		       :host => uri.host,
		       :port => uri.port,
		       :path => "/")
    }.merge(options)
        
    unless uri.to_s.starts_with?(options[:root].to_s)
      raise "URI #{uri.to_s} does not start with root #{options[:root].to_s}"
    end

    # take the rest of the path as context, function name and arguments
    path_rest = uri.path[options[:root].path.length..-1]
    
    # environment
    env = HttpEnvironment.new(options[:root])

    # task
    task = HttpTask.from_path_with_parameters(path_rest + "?" + uri.query)

    HttpRequest.new(env, task)
  end
  
end
=begin
#!/usr/bin/ruby

# hello.pl -- my first perl script!


cgi = CGI.new('html4')

page = nil
page = $1 if cgi["old_link"] =~ /([^\/]+\.cgi)/

NEW_ROOT = "https://todo.kapozh.imsec.ch/kapozilla/"
unless page
 uri = NEW_ROOT
else
  uri = URI.parse("#{NEW_ROOT}#{page}")

  ps = cgi.params.map {|name, vals|
   next if name == "old_link"
   vals.map {|val| "#{name}=#{CGI.escape(val)}"}
  }.compact.flatten.join("&")
  uri = uri.to_s + "?" + ps
end

uri = uri.to_s

# Ask the cgi object to send some text out to the browser.
cgi.out {
 cgi.html {
   cgi.body {
     cgi.h1 { 'KapoZilla ist umgezogen' } +
     cgi.p { 'Die von Ihnen gew&auml;hlte URL ist nicht mehr g&uuml;ltig. Sie zeigt auf eine fr&uuml;here Instanz von KapoZilla.'} +
     cgi.p {
      if page
        'Der neue, richtige Link lautet: ' +
        cgi.a(uri) { uri }
      else
        'Die neue Instanz befindet sich hier: ' + cgi.a(uri) {uri}
      end +
      '<br><br>Bitte passen Sie Ihre URL entsprechend an.'
     }
   }
 }
}

exit 0

print "Content-type: text/html\n\n"

print <<EOF
<HTML>
<HEAD>
<TITLE>KapoZilla Moved</TITLE>
</HEAD>

<BODY>
<H1>KapoZilla ist umgezogen</H1>

<P>
Die von Ihnen gew&auml;hlte URL ist nicht mehr g&uuml;ltig. Sie zeigt auf eine f&uuml;hrere
Instaz von KapoZilla.

Der neue, richtige Link ist<br>
#{URI.parse(ARGV[0]).inspect}<br>
Bitte passen Sie Ihre URL entsprechend an.
</P>

</BODY>
</HTML>
EOF
=end
