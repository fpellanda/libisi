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

require "libisi/doc/base"
class HtmlDoc < BaseDoc
  
  def start_doc(options = {}, &block)
    writer(options, &block) << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"' +
      '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' +
      '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">'
  end
  def end_doc(options = {}, &block)
    writer(options, &block) << '</html>'
  end


  def tr(options = {}, &block); generate_tag("tr", false, options) {yield; nil} end
  def td(options = {}, &block); generate_tag("td", true, options, &block); end
  def th(options = {}, &block); generate_tag("th", true, options, &block); end  
  def ul(options = {}, &block); generate_tag("ul", false, options, &block); end  
  def li(options = {}, &block); generate_tag("li", true, options, &block); end  
  def p(options = {}, &block); generate_tag("p", true, options, &block); end  

  private
  def generate_attributes(tag_name, options)
    ret = ""
    case tag_name.to_s
    when "table"
      ret += " border='#{options[:style].delete(:border)}'" if (options[:style][:border] rescue nil)
      ret += " class='#{options[:css_class]}'" if (options[:css_class] rescue nil)
      ret += " id='#{options[:id]}'" if (options[:id] rescue nil)
    when "td","th"
      ret += " colspan='#{options.delete(:colspan)}'" if options[:colspan]
      ret += " rowspan='#{options.delete(:rowspan)}'" if options[:rowspan]
    end
      
    style = ""
    
    case options[:style]
    when NilClass      
    when String; style += options[:style]
    when Hash
      options[:style].each {|key, val| style += "#{key.to_s.gsub("_","-")}:#{val};"}
    else
      raise "Unexpected style type #{options[:style].inspect}"
    end
	
    style += "text-align:#{options[:text_align]}" if options[:text_align]
    ret += " style='#{style}'" if style != ""
      ret
  end

  def generate_tag(name, content_tag, options = {}, &block)    
    writer(options, &block) << "<#{name}#{generate_attributes(name,options)}>"
    if content_tag
      writer(options, &block) << yield
    else
      yield
    end
    writer(options, &block) << "</#{name}>\n"
    nil
  end

  def generate_table(options = {}, &block); generate_tag("table", false, options) {super;nil} end
  
  def generate_title(text, options = {}, &block)
    generate_tag("h#{(@title_depth or 0) + 1}", true, options) { text}
    yield
  end

end
