#-----------------------------------------------
# HyperTensioN
#-----------------------------------------------
# Mau Magnaguagno
#-----------------------------------------------
# HTN planner
#-----------------------------------------------

module Hypertension
  extend self

  FAST_OUTPUT = true

  attr_accessor :domain, :state, :debug

  #-----------------------------------------------
  # Planning
  #-----------------------------------------------

if FAST_OUTPUT

  def planning(tasks, level = 0)
    return tasks if tasks.empty?
    case decomposition = @domain[(current_task = tasks.shift).first]
    # Operator (true: visible, false: invisible)
    when true, false
      puts "#{'  ' * level}#{current_task.first}(#{current_task.drop(1).join(' ')})" if @debug
      old_state = @state
      begin
        # Keep decomposing the hierarchy if operator applied
        if send(*current_task) and plan = planning(tasks, level)
          # Add visible operator to plan
          return decomposition ? plan.unshift(current_task) : plan
        end
      rescue SystemStackError then @nostack = true
      end
      @state = old_state
    # Method
    when Array
      # Keep decomposing the hierarchy
      task_name = current_task.shift
      level += 1
      begin
        decomposition.each {|method|
          puts "#{'  ' * level.pred}#{method}(#{current_task.join(' ')})" if @debug
          # Every unification is tested
          send(method, *current_task) {|subtasks| return plan if plan = planning(subtasks.concat(tasks), level)}
        }
      rescue SystemStackError then @nostack = true
      end
      current_task.unshift(task_name)
    # Error
    else raise "Domain defines no decomposition for #{current_task.first}"
    end
    nil
  end

else

  def planning(tasks, level = 0)
    return tasks if tasks.empty?
    index, current_task = tasks.shift
    case decomposition = @domain[current_task.first]
    # Operator (true: visible, false: invisible)
    when true, false
      puts "#{'  ' * level}#{current_task.first}(#{current_task.drop(1).join(' ')})" if @debug
      old_state = @state
      begin
        # Keep decomposing the hierarchy if operator applied
        if send(*current_task) and plan = planning(tasks, level)
          # Add visible operator to plan
          return decomposition ? plan.unshift([index, current_task]) : plan
        end
      rescue SystemStackError then @nostack = true
      end
      @state = old_state
    # Method
    when Array
      # Keep decomposing the hierarchy
      task_name = current_task.shift
      level += 1
      old_index = @index
      begin
        decomposition.each {|method|
          puts "#{'  ' * level.pred}#{method}(#{current_task.join(' ')})" if @debug
          # Every unification is tested
          send(method, *current_task) {|subtasks|
            subtasks.map! {|t| [(@index += 1 if @domain[t.first]), t]}
            new_index = @index
            if plan = planning(subtasks.concat(tasks), level)
              @decomposition.unshift("#{index} #{task_name} #{current_task.join(' ')} -> #{method[task_name.size+1..-1]} #{(old_index+1..new_index).to_a.join(' ')}")
              return plan
            end
            @index = old_index
          }
        }
      rescue SystemStackError
        @index = old_index
        @nostack = true
      end
      current_task.unshift(task_name)
    # Error
    else raise "Domain defines no decomposition for #{current_task.first}"
    end
    nil
  end

end

  #-----------------------------------------------
  # Applicable?
  #-----------------------------------------------

  def applicable?(precond_pos, precond_not)
    # All positive preconditions and no negative preconditions are found in the state
    precond_pos.all? {|pre,*terms| @state[pre].include?(terms)} and precond_not.none? {|pre,*terms| @state[pre].include?(terms)}
  end

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(effect_add, effect_del)
    # Create new state with added or deleted predicates
    @state = @state.map(&:dup)
    effect_del.each {|pre,*terms| @state[pre].delete(terms)}
    effect_add.each {|pre,*terms| @state[pre] << terms}
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
    objects = free.zip
    # Unification by positive preconditions
    match_objects = []
    precond_pos.each {|pre,*terms|
      next unless terms.include?('')
      # Swap free variables with matching set or maintain constant term
      terms.map! {|p| objects.find {|j,| j.equal?(p)} || p}
      # Compare with current state
      @state[pre].each {|objs|
        next unless terms.each_with_index {|t,i|
          # Free variable
          if t.instance_of?(Array)
            # Not unified
            if t.first.empty?
              match_objects.push(t, i)
            # No match with previous unification
            elsif not t.include?(objs[i])
              match_objects.clear
              break
            end
          # No match with value
          elsif t != objs[i]
            match_objects.clear
            break
          end
        }
        # Add values to sets
        match_objects.shift << objs[match_objects.shift] until match_objects.empty?
      }
      # Unification closed
      terms.each {|i| i.first.replace('X') if i.instance_of?(Array) and i.first.empty?}
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
      obj += 1
      if level != free.size.pred
        # Stack backjump position
        stack.unshift(level, obj) if objects[level][obj]
        level += 1
        obj = 0
      else
        yield if applicable?(precond_pos, precond_not)
        # Load next object or restore
        unless objects[level][obj]
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
    data.each_with_index {|d,i| puts "#{i}: #{d.first}(#{d.drop(1).join(' ')})"}
  end

  #-----------------------------------------------
  # Problem
  #-----------------------------------------------

if FAST_OUTPUT

  def problem(state, tasks, debug = false, ordered = true)
    @nostack = false
    @debug = debug
    @state = state
    puts 'Tasks'.center(50,'-')
    print_data(tasks)
    puts 'Planning'.center(50,'-')
    t = Time.now.to_f
    plan = ordered ? planning(tasks) : task_permutations(state, tasks)
    puts "Time: #{Time.now.to_f - t}s", 'Plan'.center(50,'-')
    if plan
      if plan.empty? then puts 'Empty plan'
      else print_data(plan)
      end
    else abort(@nostack ? 'Planning failed, try with more stack' : 'Planning failed')
    end
    plan
  rescue Interrupt
    puts 'Interrupted'
  rescue
    puts $!, $@
  end

else

  def problem(state, tasks, debug = false, ordered = true)
    @nostack = false
    @debug = debug
    @state = state
    @index = -1
    puts 'Tasks'.center(50,'-'), tasks.map! {|t| [@index += 1, t]}.map {|d| d.join(' ')}
    @decomposition = []
    @index -= 1 if tasks[-1][1][0] == :invisible_goal
    root = "root #{(0..@index).to_a.join(' ')}"
    puts 'Planning'.center(50,'-')
    t = Time.now.to_f
    plan = ordered ? planning(tasks) : task_permutations(state, tasks)
    puts "Time: #{Time.now.to_f - t}s", 'Plan'.center(50,'-')
    if plan
      puts 'Empty plan' if plan.empty?
      puts '==>', plan.map {|d| d.join(' ')}, root, @decomposition, '<=='
    else abort(@nostack ? 'Planning failed, try with more stack' : 'Planning failed')
    end
    plan
  rescue Interrupt
    puts 'Interrupted'
  rescue
    puts $!, $@
  end

end

  #-----------------------------------------------
  # Task permutations
  #-----------------------------------------------

  def task_permutations(state, tasks)
    goal = tasks.pop if tasks[-1][1][0] == :invisible_goal
    # All permutations are considered
    tasks.permutation {|task_list|
      @state = state
      plan = planning(Marshal.load(Marshal.dump(task_list)) << goal)
      return plan if yield
    }
    nil
  end
end