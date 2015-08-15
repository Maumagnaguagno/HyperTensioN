module Hop
  extend self

  attr_reader :actions

  @actions = {}

  def declare_operators(*operators)
    operators.each {|i| @actions[i] = true}
  end

  def declare_methods(task_name, *method_list)
    @actions[task_name] = method_list
  end

  def clear
    @actions.clear
  end

  def plan(state, tasks, verbose = 0)
    t = Time.now.to_f
    puts "DEBUG verbose: #{verbose}:","\tstate: #{state[:name]}","\ttasks: #{tasks}" if verbose > 0
    result = seek_plan(state, tasks, [], 0, verbose)
    puts "DEBUG Result: #{result.inspect}" if verbose > 0
    puts Time.now.to_f - t
    result
  end

  def search_operators(state, tasks, plan, task, depth, verbose)
    puts "depth #{depth} action #{task}" if verbose > 2
    newstate = send(task.first, Marshal.load(Marshal.dump(state)), *task.drop(1))
    if verbose > 2
      puts "depth #{depth} new state:"
      puts "\t" << newstate.inspect
    end
    if newstate
      solution = seek_plan(newstate, tasks.drop(1), plan << task, depth+1, verbose)
      return solution if solution
    end
  end

  def search_methods(state, tasks, plan, task, depth, verbose)
    puts "depth #{depth} method instance #{task}" if verbose > 2
    relevant = @actions[task.first]
    relevant.each {|method|
      subtasks = send(method, state, *task.drop(1))
      puts "depth #{depth} new tasks: #{subtasks}" if verbose > 2
      if subtasks
        tasks.shift
        tasks.unshift(*subtasks)
        solution = seek_plan(state, tasks, plan, depth.succ, verbose)
        return solution if solution
      end
    }
  end

  def seek_plan(state, tasks, plan, depth, verbose = 0)
    puts "depth #{depth} tasks #{tasks}" if verbose > 1
    if tasks.empty?
      puts "depth #{depth} returns plan #{plan}" if verbose > 2
      return plan
    end
    task = tasks.first
    case @actions[task.first]
    when true # Primitive
      search_operators(state, tasks, plan, task, depth, verbose)
    when Array # Complex
      search_methods(state, tasks, plan, task, depth, verbose)
    else
      puts "depth #{depth} returns failure" if verbose > 2
    end
  end
end
