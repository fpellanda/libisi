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

require "libisi/doc/base.rb"
require "text/format.rb"
class TextDoc < BaseDoc

  def tr(options = {}, &block); 
    @rows.push([])
    #writer(options, &block) << "|"
    yield
    #writer(options, &block) << "\n"
  end
  def th(options = {}, &block);    
    #writer(options, &block) << " #{yield.inspect.upcase} |"
    @rows[-1].push(yield.to_s.upcase.gsub("\n",""))
#    options[:colspan].times {@rows[-1].push(nil} if options[:colspan]
  end
  def td(options = {}, &block); 
    #    writer(options, &block) << " #{yield.inspect} |"
    @rows[-1].push(yield.to_s.gsub("\n",""))
    options[:colspan].times {@rows[-1].push(-1)} if options[:colspan]
  end
  
  def ul(options = {}, &block)
#    writer(options, &block) << "#{yield}"    
    yield
  end
  def li(options = {}, &block)
    writer(options, &block) << " * #{block(yield,3).strip}\n"
  end

  private
  def generate_bare_table(options = {}, &block);
    @rows = []
    #    writer(options, &block) << "<<<TABLE>>>\n"
    super
    #    writer(options, &block) << "<<<END TABLE>>>\n"

    max_cols = @rows.map {|r| r.length}.max
    col_lengths = []
    max_cols.times {|i|
      col_lengths[i] = @rows.map {|r| 
	(r[i] or "").to_s.length
      }.max
    }
    
    @rows.each {|r|
      r.length.times{|i|
	r[i] = (r[i] or "").to_s.ljust(col_lengths[i])
      }
      writer(options, &block) << ("| " + r.join(" | ") + " |\n")
    }    
  end

  def block(text, left_margin = 0, width = 60)
    f1 = Text::Format.new
    f1.first_indent = 0 #left_margin
    f1.left_margin = left_margin
    f1.columns = width

    text.split("\n").map {|t|
      f1.format(t).sub(/\n$/,"")	
    }.join("\n")
  end

  class WriterWrapper
    def initialize(writer, depth)
      @w = writer
      @d = (depth or 0).to_i
    end
    def <<(text)
      #$log.debug("Write: #{text}")
      raise "text is nil" if text.nil?
#      STDOUT << ("\n" + text.inspect + "\n")
      text = text.to_s.gsub(/^/m,(" " * @d))
      @w << text
    end
  end
  
  def writer(options = {}, &block)
    WriterWrapper.new(super, @title_depth)    
  end
end
