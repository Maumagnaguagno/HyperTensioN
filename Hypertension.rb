#!/usr/bin/env ruby
#-----------------------------------------------
# HyperTensioN
#-----------------------------------------------
# Mau Magnaguagno
#-----------------------------------------------
# Require this module to use
#-----------------------------------------------
# HTN planner based on PyHop
#-----------------------------------------------
# Mar 2014
# - Converted PyHop to Ruby
# - Data structures modified
# Jun 2014
# - converted ND_PyHop to Ruby
# - Data structures modified
# - Using previous state for state_valuation
# - Added support for minimum probability
# - Data structure simplified
# - Override state_valuation and state_copy for specific purposes
# Dec 2014
# - Forked project, probability mode only works for Hypertension_simple
# - STRIPS style operator application instead of imperative mode
# - Backtrack support
# - Operator visibility
# - Unification
# - Plan is built after tasks solved
# - Domain and problem separated
# - Deep copy only used at operator application
# Mar 2014
# - Refactoring of generate
# Jun 2015
# - Unordered tasks with explicit goal check
# Sep 2015
# - Apply method extracted from apply_operator
#-----------------------------------------------
# TODOs
# - Order predicates and test applicability by level (generate)
# - Unordered subtasks
# - Anytime mode
#-----------------------------------------------

module Hypertension
  extend self

  attr_accessor :domain, :state, :debug

  #-----------------------------------------------
  # Planning
  #-----------------------------------------------

  def planning(tasks, level = 0)
    return [] if tasks.empty?
    case decomposition = @domain[(current_task = tasks.shift).first]
    # Operator (true: visible, false: invisible)
    when true, false
      puts "#{'  ' * level}#{current_task.first}(#{current_task.drop(1).join(',')})" if @debug
      old_state = @state
      # If operator applied
      if send(*current_task)
        # Keep decomposing the hierarchy
        if plan = planning(tasks, level)
          # Some operators are not visible
          plan.unshift(current_task) if decomposition
          return plan
        end
        @state = old_state
      end
    # Method
    when Array
      # Keep decomposing the hierarchy
      task_name = current_task.shift
      level += 1
      decomposition.each {|method|
        puts "#{'  ' * level.pred}#{method}(#{current_task.join(',')})" if @debug
        # Every unification is tested
        send(method, *current_task) {|subtasks| return plan if plan = planning(subtasks.concat(tasks), level)}
      }
      current_task.unshift(task_name)
    # Error
    else raise "Decomposition problem with #{current_task.first}"
    end
    nil
  end

  #-----------------------------------------------
  # Applicable?
  #-----------------------------------------------

  def applicable?(precond_pos, precond_not)
    # All positive preconditions and no negative preconditions are found in the state
    precond_pos.all? {|name,*objs| @state[name].include?(objs)} and precond_not.none? {|name,*objs| @state[name].include?(objs)}
  end

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(effect_add, effect_del)
    # Create new state with added or deleted propositions
    @state = Marshal.load(Marshal.dump(@state))
    effect_del.each {|name,*objs| @state[name].delete(objs)}
    effect_add.each {|name,*objs| @state[name] << objs}
    true
  end

  #-----------------------------------------------
  # Apply operator
  #-----------------------------------------------

  def apply_operator(precond_pos, precond_not, effect_add, effect_del)
    # Apply effects if preconditions satisfied
    apply(effect_add, effect_del) if applicable?(precond_pos, precond_not)
  end

  #-----------------------------------------------
  # Generate
  #-----------------------------------------------

  def generate(precond_pos, precond_not, *free)
    # Free variable to set of values
    objects = free.map {|i| [i]}
    # Unification by positive preconditions
    match_objects = []
    precond_pos.each {|name,*objs|
      next unless objs.include?('')
      # Swap free variables with set to match or maintain constant
      pred = objs.map {|p| objects.find {|j| j.first.equal?(p)} or p}
      # Compare with current state
      @state[name].each {|terms|
        next unless pred.each_with_index {|p,i|
          # Free variable
          if p.instance_of?(Array)
            # Not unified
            if p.first.empty?
              match_objects.push(p, i)
            # No match with previous unification
            elsif not p.include?(terms[i])
              match_objects.clear
              break
            end
          # No match with value
          elsif p != terms[i]
            match_objects.clear
            break
          end
        }
        # Add values to sets
        match_objects.shift << terms[match_objects.shift] until match_objects.empty?
      }
      # Unification closed
      pred.each {|i| i.first.replace('X') if i.instance_of?(Array) and i.first.empty?}
    }
    # Remove pointer and duplicates
    objects.each {|i|
      i.shift
      return if i.empty?
      i.uniq!
    }
    # Depth-first search
    stack = []
    level = obj = 0
    while level
      # Replace pointer value with useful object to affect variables
      free[level].replace(objects[level][obj])
      if level != free.size.pred
        # Stack backjump position
        stack.unshift(level, obj.succ) if obj.succ != objects[level].size
        level += 1
        obj = 0
      else
        yield if applicable?(precond_pos, precond_not)
        # Load next object or restore
        if (obj += 1) == objects[level].size
          level = stack.shift
          obj = stack.shift
        end
      end
    end
  end

  #-----------------------------------------------
  # Print data
  #-----------------------------------------------

  def print_data(data)
    data.each_with_index {|d,i| puts "#{i}: #{d.first}(#{d.drop(1).join(', ')})"}
  end

  #-----------------------------------------------
  # Problem
  #-----------------------------------------------

  def problem(start, tasks, debug = false, goal_pos = [], goal_not = [])
    @debug = debug
    @state = start
    puts 'Tasks'.center(50,'-')
    print_data(tasks)
    puts 'Planning'.center(50,'-')
    t = Time.now.to_f
    # Ordered
    if goal_pos.empty? and goal_not.empty?
      plan = planning(tasks)
    # Unordered
    else plan = task_permutations(start, tasks, goal_pos, goal_not)
    end
    puts "Time: #{Time.now.to_f - t}s", 'Plan'.center(50,'-')
    if plan
      if plan.empty?
        puts 'Empty plan'
      else print_data(plan)
      end
    else puts 'Planning failed'
    end
    plan
  rescue Interrupt
    puts 'Interrupted'
  rescue
    puts $!, $@
    STDIN.gets
  end

  #-----------------------------------------------
  # Task permutations
  #-----------------------------------------------

  def task_permutations(state, tasks, goal_pos, goal_not)
    # All permutations are considered
    tasks.permutation {|task_list|
      @state = state
      plan = planning(Marshal.load(Marshal.dump(task_list)))
      return plan if applicable?(goal_pos, goal_not)
    }
    nil
  end

  def task_permutations_partial(state, tasks, goal_pos, goal_not, plan = [])
    # Only first partial plan found is considered
    # TODO requires planning to yield to be complete
    if tasks.empty?
      return plan if applicable?(goal_pos, goal_not)
    else
      tasks.each {|t|
        @state = state
        p = planning([t.dup])
        return p if p and (p = task_permutations(@state, tasks - [t], goal_pos, goal_not, plan + p))
      }
      nil
    end
  end
end