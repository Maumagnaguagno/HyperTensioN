#!/usr/bin/env ruby
#-----------------------------------------------
# HyperTensioN simple
#-----------------------------------------------
# Mau Magnaguagno
#-----------------------------------------------
# Require this module
# See simple_travel_example.rb
#-----------------------------------------------
# HTN planner based on PyHop
# Support deterministic and probabilistic mode
#-----------------------------------------------
# Mar 2014
# - Converted from PyHop to Ruby
# - Data structures modified
# Jun 2014
# - converted ND_PyHop to Ruby
# - Data structures modified
# - Using previous state for state_valuation
# - Added support for Minimum probability
# - Data structure simplified
# - Override state_valuation and state_copy for specific purposes
# Dec 2014
# - Project forked, this one becomes simple mode
#-----------------------------------------------
# TODOs
# - Separate operators from methods
# - Use same data structure for both modes
# - Make it more module-like
#-----------------------------------------------

module Hypertension_simple
  extend self

  # Deterministic plan = [operator 0 .. operator n]
  # Probabilistic plan = [PROBABILITY, VALUATION, operator 0 .. operator n]
  PROBABILITY = 0
  VALUATION   = 1

  #-----------------------------------------------
  # Deterministic Planning
  #-----------------------------------------------

  def deterministic_planning(state, actions, tasks, plan = [])
    return plan if tasks.empty?
    task = tasks.first
    decompose = actions[task.first]
    case decompose
    when true # Operator
      p task
      state = send(task.first, state_copy(state), *task.drop(1))
      p state != nil
      if state
        solution = deterministic_planning(state, actions, tasks.drop(1), plan << task)
        return solution if solution
      end
    when Array # Method
      decompose.each {|method|
        p method
        subtasks = send(method, state, *task.drop(1))
        if subtasks
          solution = deterministic_planning(state, actions, tasks.drop(1).unshift(*subtasks), plan)
          return solution if solution
        end
      }
    else raise 'Type problem, actions must point to operator mode (True) or group of possibilities (Array)'
    end
    false
  end

  #-----------------------------------------------
  # Probabilistic Planning
  #-----------------------------------------------

  def probabilistic_planning(state, actions, tasks, min_prob = 0, max_found = 0, plan = [1,0], plans_found = [])
    # Limit test
    if max_found > 0 and plans_found.size == max_found
      plans_found
    elsif tasks.empty?
      plans_found << plan if plan[PROBABILITY] >= min_prob
    else
      task = tasks.first
      decompose = actions[task.first]
      case decompose
      when Numeric # Operator with single outcome
        execute(task.first, decompose, task.drop(1), state, actions, tasks, min_prob, max_found, plan, plans_found)
      when Hash # Operator with multiple outcomes
        decompose.each {|operator, probability|
          execute(operator, probability, task.drop(1), state, actions, tasks, min_prob, max_found, plan, plans_found)
        }
      when Array # Method
        decompose.each {|method|
          subtasks = send(method, state, *task.drop(1))
          if subtasks
            probabilistic_planning(state, actions, tasks.drop(1).unshift(*subtasks), min_prob, max_found, plan, plans_found)
          end
        }
      else raise "Type problem for #{task.first}, actions must point to probability value (Fixnum or Float) or group of possibilities (Array or Hash)"
      end
      plans_found unless plans_found.empty?
    end
  end

  #-----------------------------------------------
  # Execute
  #-----------------------------------------------  

  def execute(operator, probability, arguments, state, actions, tasks, min_prob, max_found, plan, plans_found)
    new_prob = plan[PROBABILITY] * probability
    if new_prob >= min_prob
      new_state = send(operator, state_copy(state), *arguments)
      if new_state
        new_plan = plan.dup << [operator, *arguments]
        new_plan[PROBABILITY] = new_prob
        new_plan[VALUATION] += probability * state_valuation(state)
        probabilistic_planning(new_state, actions, tasks.drop(1), min_prob, max_found, new_plan, plans_found)
      end
    end
  end

  #-----------------------------------------------
  # State Copy
  #-----------------------------------------------

  def state_copy(object)
    Marshal.load(Marshal.dump(object))
  end

  #-----------------------------------------------
  # State Valuation
  #-----------------------------------------------

  def state_valuation(state)
    1
  end

  #-----------------------------------------------
  # Print Deterministic Plan
  #-----------------------------------------------

  def print_deterministic_plan(plan, name = 'found')
    puts "Plan #{name}:",
         '  Operators:'
    plan.each_with_index {|action,i|
      puts "    #{i}: #{action.first}(#{action.drop(1).join(', ')})"
    }
  end

  #-----------------------------------------------
  # Print Probabilistic Plan
  #-----------------------------------------------

  def print_probabilistic_plan(plans)
    puts "Plans found: #{plans.size}"
    plans.each_with_index {|plan,i|
      print_deterministic_plan(plan.drop(2), i)
      puts "  Valuation: #{plan[VALUATION]}",
           "  Probability: #{plan[PROBABILITY]}"
    }
  end
end
