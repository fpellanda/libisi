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

require "libisi/ui/base.rb"
class RailsUI < BaseUI
  $progress_names = {}
  def info(text, options = {})
    print "#{text}\n"
  end

  # PROGRESS    
  def enable_progress_bar(val = true, &block)
    raise "Need block around progress for rails ui." unless block_given?
    params = eval("params",block.binding)
    if val and not params[:no_progress]
      @progress = true
      
      progress_name = params[:progress_name]
      
      if progress_name
	eval("@progress_name = #{progress_name.inspect}",block.binding)
	if params[:real_task]
	  # now this processid will stay until
	  # the task is finished, takover the file
	  orig_file = progress_file(progress_name)
	  new_file = progress_file(current_progress_name)
	  begin
	    FileUtils.mv(orig_file,new_file)
	    orig_file.make_symlink(new_file)

	    $progress_cache[Process.pid] = load_progress
	  
	    # this is the real task, go for it
	    yield
	    eval('render :layout => false', block.binding)
	  ensure
	    orig_file.delete if orig_file.exist?
	    new_file.delete if new_file.exist?
	    $progress_cache[Process.pid] = nil
	  end
	else
	  # this is the progressbar call, render it
	  eval('render :layout => false, :action => "../application/progress_bar"', block.binding)
	end
      else
	# this is the initialization step
	# create a new id for the progressbar
	# this name must be able to be an id of a html tag
	progress_name = current_progress_name
	# make it unique
	progress_name += "#{Time.now.to_i}"
	eval("@progress_name = #{progress_name.inspect}",block.binding)
	
	$progress_cache[Process.pid] = {}
	save_progress(progress_name)
	$progress_cache[Process.pid] = nil
	
	# render a page with progressbar
	# and a content for the main page
	eval('render :action => "../application/progress_page"', block.binding)
      end
    else
      @progress = false
      yield
    end
    @progress = false
  end

  def progress_bar_implementation(text, total, &block)
    if progress_bar_enabled?
      $progress_cache[Process.pid] = {:count => total.to_i, :current => 0, :text => text}
      save_progress
      yield
      $progress_cache[Process.pid] = nil
      save_progress
    else
      yield
    end
  end

  def progress(count)
    $progress_cache[Process.pid][:current] = count
    save_progress
  end
  def progress_inc
    $progress_cache[Process.pid][:current] += 1
    save_progress
  end
  def progress_message(text)
    $progress_cache[Process.pid][:text] = text
    save_progress
  end
  
  def progress_values(name)
    load_progress(name)
  end
  private
  $progress_cache = {}
  $progress_mutex ||= Mutex.new
  def current_progress_name
    "P#{Process.pid}"
  end

  def progress_file(name = nil)
    name = current_progress_name if name.nil?
    Pathname.new("/tmp/progress_#{name}")
  end

  def save_progress(name = nil)
    name = current_progress_name if name.nil?
    $progress_mutex.synchronize {
      f = progress_file(name)
      # save if more than 2 seconds
      # have been passed till last 
      # save
      if !f.exist? or ((Time.new - f.mtime) > 2)
	yaml = $progress_cache[Process.pid].to_yaml
	f.open("w") {|f| f.write(yaml) }
      end
    }
  end

  def load_progress(name = nil)
    name = current_progress_name if name.nil?
    $progress_mutex.synchronize {
      f = progress_file(name)
      if f.exist?
	YAML::load(f.readlines.join)
      else
	nil
      end
    }
  end

end

