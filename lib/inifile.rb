# Copyright (C) 2004 Gregoire Lejeune <gregoire.lejeune@free.fr>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

class IniFile

  public

  def initialize( file = nil )
    clear( )
    if file.nil? == false and file.empty? == false
      load( file )
    end
  end

  def load( file )
    clear( )
    @hhxData = Hash::new( )
    @sectionList = []
    @xIniFile = file
    parseFile( )
  end

  def write( file = nil )
    xWriteFile = @xIniFile
    if file.nil? == false
      xWriteFile = file
    end

    fIni = open( xWriteFile, "w" )
    @sectionList.each {|xSection|
      hxPairs = @hhData[xSection]
      fIni.print "[", xSection, "]\n"
      hxPairs.each{ |xKey, xValue|
        fIni.print xKey, " = ", xValue, "\n"
      }
      fIni.puts "\n"
    }
    fIni.close( )
  end
  
  def sections
    if @hhxData.nil? == false
      @sectionList.each {|k|
        yield( k )
      }
    end
  end

  def clear
    @hhxData = nil
    @sectionList = nil
    @xIniFile = nil
  end
  
  def [](section)
    if @hhxData.nil? == false
      return @hhxData[section]
    end
  end

  def []=(section, hash)
    if @hhxData.nil? == true
      @hhxData = Hash::new( )
      @sectionList = []
    end

    @hhxData[section] = hash
  end

  private

  @xIniFile
  @hhxData
  @sectionList
  
  def parseFile
    xCurrentSection = nil

    open( @xIniFile, 'r' ) do |f|
      xLine = ''
      until f.eof?
        xLine = f.gets.chomp.gsub(/;.*/, '').strip;
        
        if xLine.empty? == false 
          case xLine
            when /^\[(.*)\]$/
              xCurrentSection = $1
              if @hhxData.has_key?( xCurrentSection ) == false
                @hhxData[xCurrentSection] = Hash::new( )
		@sectionList << xCurrentSection
              end
  
            when /^([^=]+?)=/
              xKey = $1.strip
              xValue = $'.strip
              @hhxData[xCurrentSection][xKey] = xValue
  
            else
              print "ERROR !!!\n"
          end
        end
      end
    end
  end

end
