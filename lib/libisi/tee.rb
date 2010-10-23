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

class Tee
  attr_accessor :children
  
  def deep_clone(obj)
    case obj
    when NilClass
      obj
    when Fixnum,Bignum,Float,NilClass,FalseClass,
	TrueClass,Continuation, Symbol, Rational
      klone = obj
    when Hash
      klone = obj.clone
      obj.each{|k,v| klone[k] = deep_clone(v)}
    when Array
      klone = obj.clone
      klone.clear
      obj.each{|v| klone << deep_clone(v)}      
    else
      klone = obj.clone
    end
    klone.instance_variables.each {|v|
      klone.instance_variable_set(v,deep_clone(klone.instance_variable_get(v)))
    }
    klone
  end


  def initialize(children = [])
    @children = children
  end

  def signature(method_id, *arguments, &block)
    "#{method_id}(#{arguments.map {|a| a.inspect}.join(",")}#{",&block" if block})"
  end

  def method_missing(method_id, *arguments, &block)
    if block
      function_results, block_results = call_child(0, method_id, arguments, block)
      function_results[0]
    else
      $log.debug{"Calling #{signature(method_id, *arguments, &block)} sequentially"}
      # no block given, we can execute 
      # methods sequentially
      result = nil
      children.each_with_index {|child, index|
	if index < (children.length-1)
	  child.send(method_id, *(deep_clone(arguments)))
	else
	  result = child.send(method_id, *arguments)
	end
      }
      result
    end
  end

  def call_child(child_id, method_id, arguments, block)    
    raise "child with id #{child_id} does not exist" unless 
      children[child_id]

    original_arguments = arguments
    arguments = deep_clone(arguments)

    raise "no block given" unless block
    signature = signature(method_id, *arguments, &block)
    $log.debug("Child ##{child_id}: Calling #{signature}")

    vars = []
    if block.arity > 0
      block.arity.times {|i| vars.push("a#{i}")}      
    else
      (-block.arity - 1).times {|i| vars.push("a#{i}")}      
      vars.push("*a")
    end
    block_text = ""
    block_text += "proc {|#{vars.join(",")}|\n"
    if child_id < (children.length-1)
      block_text += "  call_count += 1\n"
      block_text += "  function_results, block_results = call_child(child_id + 1, method_id, original_arguments, block) if call_count == 1\n"
      block_text += "  br = block_results[(call_count-1)]\n"
      block_text += "  br = deep_clone(br)\n"
#      block_text += "  p [#{vars.join(",")}]\n"
      block_text += "  br\n"
    else
      $log.debug("Last child, collecting results")
      # this is the last child
      # here we must collect all
      # block results
      block_text += "  br = block.call(#{vars.join(",")})\n"
      block_text += "  $log.debug{\"Result of block is: \#\{br.inspect}\"\}\n"
      block_text += "  block_results << deep_clone(br)\n"
      block_text += "  call_count += 1\n"
      block_text += "  br\n"
    end
    block_text += "}\n"
    block_results = []
    function_results = []
    call_count = 0
    new_block = eval(block_text)
    raise "Not same arity" if new_block.arity != block.arity

    if child_id < (children.length-1)
      function_results << children[child_id].send(method_id, *(deep_clone(arguments)), &new_block)
    else
      function_results << children[child_id].send(method_id, *original_arguments, &new_block)
    end
    raise "#{signature} master block execute #{block_results.length - 1} " + 
      "times child block ##{child_id} #{call_count} times." if 
      call_count != (block_results.length)
    [function_results, block_results]
  end
end

=begin
   case @state
   when 0
      # first call
      @state = 1
      @arguments = arguments
      @block = block

      master.call(method_id, *arguments, &block)
      calling master function
    when 1
      # recall of other function 
      # while executing master      
      @state = 2
      @second_arguemtns = arguments
      @second_block = block
      calling children with arguments
      # now all children have
      # same calls, going to state 0
      # again      
      method_missing(method_id, *arguments, &block)
    when 2
      # ok, this is a child call,
      # should have the same arguments
      # as those in state 1
      raise "Second arguemtns are not equal" unless
	@second_arguments == @arguments
    end
  end
      
    
  def method_missing(method_id, *arguments, &block)
    if @child_processing_number

    end

    signature = "#{method_id}(#{arguments.map {|a| a.inspect}.join(",")})"
    $log.debug("Teeing #{signature} to #{children.length} children (#{children.map{|c| "#{c.class.name}(#{c.object_id})"}.join(",")})")

    block_args = []
    block_result = nil
    
    if block
    end

    # call first child and get arguments and result of the block

    children[1..-1].each_with_index {|child,i|
      unless i == 0
	@call_stack.push([method_id, arguments, slave_block])
      else
	@child_processing_number = i	
      end
      
      if block
	master.send(method_id, *arguments, master_block)
      else
	master.send(method_id, *arguments)
      end
      
      my_block = if i == 0
		   #print master_block_text
		 else
		   #print slave_block_text
		 end if block
      
      $log.debug("Call##{i} #{signature}")
      if my_block	
	child.send(method_id, *arguments, &my_block)
      else
	child.send(method_id, *arguments)
      end
      $log.debug("The arguments of child #{i} of #{signature} were #{block_args[i].inspect} with result #{block_result.inspect}")
    }
  end

  def method_missing_old(method_id, *arguments, &block)
    $log.debug("Teeing #{method_id} to #{children.length} children (#{children.map{|c| "#{c.class.name}(#{c.object_id})"}.join(",")})")      

    o_args = nil
    o_res = nil
    block_result = nil
     
    ch = children
    threads = []
    block_args = []

    mutex = Mutex.new
    state = :new
    def set_state(s)
      mutex.synchronize {
	state = s
      }
    end
    
    get_args_block = nil
    i = nil
    if block
      vars = []
      if block.arity > 0
	block.arity.times {|i| vars.push("a#{i}")}      
      else
	(-block.arity - 1).times {|i| vars.push("a#{i}")}      
	vars.push("*a")
      end
      block_start = "proc {|#{vars.join(",")}| block_args[i] = [#{vars.join(",")}]"
      master_proc_text =  block_start + " ; start_lock.unlock ; block_result = yield(#{vars.join(",")})}"
      slave_proc_text =  block_start + " master_lock.synchronize {} block_result }"
      master_block = eval(master_block_text)
      slave_block = eval(slave_block_text)
    end
    
    first = true
    children.each_with_index {|c,index|
      threads[index] = Thread.fork(index) { |i|

	master = false
	mutex.synchronize {
	  master = true if first
	  first = false
	}

 	if master
	  # get arguments
	  # wati until all got their arguments
	  # call
	  # return result
	  # after call
	else
	  # before call
	  # call
	  # after call
	end
	

	my_block = nil
	start_lock.lock
	if first
	  # i am master
	  first = false
	  return_lock.lock
	  my_block = master_block if block
	else
	  start_lock.unlock
	  my_block = slave_block if block
	end
	
	# p [method_id,step_in,block_args,block_result]
	if my_block
	  c.send(method_id, *arguments, &get_args_block)
	  return_lock.unlock
	else
	  c.send(method_id, *arguments)
	  start_lock.unlock
	  return_lock.unlock
	end
      }
    }
    threads.each {|th| th.join }
    
    # call the block
    block.call(*block_args[0])
    
  end
end
   
=end
