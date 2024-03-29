module Macro
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    puts 'Macro'.center(50,'-') if debug
    # Task counter
    counter = Hash.new(0)
    methods.each {|met| met.drop(2).each {|dec| dec[4].each {|t,| counter[t] += 1}}}
    ordered = tasks.shift
    tasks.each {|t,| counter[t] += 1}
    # Macro sequential operators
    macro = []
    clear_ops = {}
    methods.each {|met|
      met.drop(2).each {|dec|
        macro_sequential_operators(operators, macro, dec[4], dec[4] = [], counter, clear_ops, debug)
      }
    }
    # Macro sequential top ordered operators
    case ordered
    when true
      macro_sequential_operators(operators, macro, tasks, new_subtasks = [ordered], counter, clear_ops, debug)
      tasks.replace(new_subtasks)
    when false
      tasks.each {|t,|
        if op = operators.assoc(t) and clear_ops.include?(op)
          unless methods.assoc(name = "macro_#{t}")
            puts "Macro method #{name}" if debug
            methods << [name, op[1], ['case_0', [], [], [], [[op_name = "invisible_#{name}", *op[1]], [t, *op[1]]]]]
            unless operators.assoc(op_name)
              operators << [op_name, op[1], op[2], op[3], op[4], op[5]]
              puts "Macro operator #{op_name}" if debug
            end
          end
          t.replace(name)
        end
      }.unshift(ordered)
    end
    # Clear operators
    clear_ops.each_key {|op|
      op[2] = []
      op[3] = []
      op[4] = []
      op[5] = []
    }
  end

  #-----------------------------------------------
  # Macro sequential operators
  #-----------------------------------------------

  def macro_sequential_operators(operators, macro, subtasks, new_subtasks, counter, clear_ops, debug)
    subtasks.each {|subtask|
      # Add operators to macro and skip methods
      if op = operators.assoc(subtask[0])
        macro << [op, subtask]
      else
        add_macro_to_subtasks(operators, macro, new_subtasks, counter, clear_ops, debug)
        new_subtasks << subtask
      end
    }
    add_macro_to_subtasks(operators, macro, new_subtasks, counter, clear_ops, debug)
  end

  #-----------------------------------------------
  # Add macro to subtasks
  #-----------------------------------------------

  def add_macro_to_subtasks(operators, macro, new_subtasks, counter, clear_ops, debug)
    if macro.size > 1
      name = nil
      parameters = []
      precond_pos = []
      precond_not = []
      effect_add = []
      effect_del = []
      index = new_subtasks.size
      macro.each {|op,subtask|
        unless op[0].start_with?('invisible_')
          clear_ops[op] = nil
          new_subtasks << subtask
        end
        # Header
        (name ? name << '_and_' : name = 'invisible_macro_') << op[0]
        parameters.concat(param = subtask.drop(1))
        variables = op[1]
        # Preconditions
        op[2].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[variables.index(p)] : p}
          if precond_not.include?(pre) and not effect_add.include?(pre) or effect_del.include?(pre)
            raise "#{op[0]} precondition (#{pre.join(' ')}) will never be satisfied"
          else precond_pos << pre unless precond_pos.include?(pre) or effect_add.include?(pre)
          end
        }
        op[3].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[variables.index(p)] : p}
          if precond_pos.include?(pre) and not effect_del.include?(pre) or effect_add.include?(pre)
            raise "#{op[0]} precondition (not (#{pre.join(' ')})) will never be satisfied"
          else precond_not << pre unless precond_not.include?(pre) or effect_del.include?(pre)
          end
        }
        # Effects
        op[5].each {|pre|
          effect_add.delete(pre = pre.map {|p| p.start_with?('?') ? param[variables.index(p)] : p})
          effect_del << pre unless precond_not.include?(pre) or effect_del.include?(pre)
        }
        op[4].each {|pre|
          effect_del.delete(pre = pre.map {|p| p.start_with?('?') ? param[variables.index(p)] : p})
          effect_add << pre unless precond_pos.include?(pre) or effect_add.include?(pre)
        }
      }.clear
      parameters.uniq!
      unless operators.assoc(name)
        operators << [name, parameters, precond_pos, precond_not, effect_add, effect_del]
        puts "Macro operator #{name}" if debug
      end
      new_subtasks.insert(index, [name, *parameters])
    elsif macro.size == 1
      op, subtask = macro.shift
      if counter[op[0]] != 1 and not op[0].start_with?('invisible_')
        unless operators.assoc(name = "invisible_macro_#{op[0]}")
          clear_ops[op] = nil
          operators << [name, op[1], op[2], op[3], op[4], op[5]]
          puts "Macro operator #{name}" if debug
        end
        new_subtasks << subtask.drop(1).unshift(name)
      end
      new_subtasks << subtask
    end
  end
end