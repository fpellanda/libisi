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

class BaseUI

  def name
    self.class.name
  end
  
  def not_implemented
    raise "Not implemented in UI #{self.name}"
  end

  def bell(options = {}); not_implemented;  end
  def question_yes_no(text, options = {}); info_non_blocking(text);select([:yes,:no],false, options)[0]; end
  def question_yes_no_retry(text, options = {}); info_non_blocking(text); select([:yes,:no,:retry],false,options)[0]; end
  def question(text, options = {}); not_implemented; end
  def info(text, options = {}); not_impelmented; end
  def info_non_blocking(text, options = {}); info(text, options); end

  def error(text, options = {})
    info("/!\\ ERROR: #{text}")
  end
  def warn(text, options = {})
    info("/!\\ WARNING: #{text}")
  end

  def select(list, multi_select = false, options = {}) ; not_implemented; end 
  def select_index(list, multi_select = false, &block)
    select(list, multi_select, {:return_indexes => true}, &block)
  end

  def colorize(color, options={}); yield; end

  def execute_in_console(command, options = {}); not_implemented; end

  # progress 
  def progress_bar(text,elements,&block)
    elements = elements.call if elements.class == Proc
    
    raise "Please provide an array if you expect elements for your block." if
      block.arity == 1 and elements.class == Fixnum
    
    if progress_bar_enabled?
      if block.arity == 1	
	progress_bar_implementation(text, elements.length) {
	  index = 0
	  elements.map {|el|
	    r = yield(el)
	    progress(index)
	    index += 1
	    r
	  }
	}
      else
	progress_bar_implementation(text, elements, &block)
      end      
    else
      if block.arity == 1	
 	elements.map {|el|
	  yield(el)
	}	
      else
	yield
      end     
    end 
  end
  
  def progress_bar_implementation(text, total, &block); not_implemented if progress_bar_enabled?; end
  def progress(count);  not_implemented if progress_bar_enabled?; end    
  def progress_message(message); not_implemented if progress_bar_enabled?; end
  def progress_inc ; not_implemented if progress_bar_enabled?; end

  def pmsg(action = nil,object = nil)
    return unless progress_bar_enabled?
    if action
      @max_action_withs ||= []
      @max_action_withs.insert(0,action.to_s.length)
      @max_action_withs = @max_action_withs[0..5] 
      action = action.ljust(@max_action_withs.max)
    end
    message = [action,object].compact.map {|s| s.to_s}.join(": ")
    progress_message(message)
  end
  def pinc(action = nil, object = nil)
    return unless progress_bar_enabled?
    progress_inc
    pmsg(action, object) if action or object
  end
  def enable_progress_bar(val = true)  
    old_val = @progress
    @progress = val
    if block_given?
      yield
      @progress = old_val
    end
  end
  def progress_bar_enabled?    
    @progress
  end

end
