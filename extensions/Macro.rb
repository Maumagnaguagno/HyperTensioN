module Macro
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    puts 'Macro'.center(50,'-') if debug
    # Subtask counter
    counter = Hash.new(0)
    methods.each {|met| met.drop(2).each {|dec| dec.last.each {|subtask,| counter[subtask] += 1}}}
    # Macro sequential operators
    macro = []
    clear_ops = {}
    methods.each {|met|
      met.drop(2).each {|dec|
        new_subtasks = []
        dec.last.each {|subtask|
          # Add operators to macro and skip methods
          if op = operators.assoc(subtask.first)
            macro << [op, subtask]
          else
            add_macro_to_subtasks(operators, macro, new_subtasks, counter, clear_ops, debug)
            new_subtasks << subtask
          end
        }
        add_macro_to_subtasks(operators, macro, new_subtasks, counter, clear_ops, debug)
        dec[4] = new_subtasks
      }
    }
    clear_ops.each_key {|op|
      op[2] = []
      op[3] = []
      op[4] = []
      op[5] = []
    }
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
        param = subtask.drop(1)
        clear_ops[op] = nil
        # Header
        (name ? name << '_and_' : name = 'invisible_macro_') << op.first.sub(/^invisible_/,'')
        parameters.concat(param)
        variables = op[1]
        # Preconditions
        op[2].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[variables.index(p)] : p}
          puts "Precondition (not (#{pre.join(' ')})) will never be satisfied" if debug and (precond_not.include?(pre) or effect_del.include?(pre))
          precond_pos << pre unless precond_pos.include?(pre) or effect_add.include?(pre)
        }
        op[3].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[variables.index(p)] : p}
          puts "Precondition (#{pre.join(' ')}) will never be satisfied" if debug and (precond_pos.include?(pre) or effect_add.include?(pre))
          precond_not << pre unless precond_not.include?(pre) or effect_del.include?(pre)
        }
        # Effects
        op[4].each {|pre|
          effect_del.delete(pre = pre.map {|p| p.start_with?('?') ? param[variables.index(p)] : p})
          effect_add << pre unless effect_add.include?(pre)
        }
        op[5].each {|pre|
          effect_add.delete(pre = pre.map {|p| p.start_with?('?') ? param[variables.index(p)] : p})
          effect_del << pre unless effect_del.include?(pre)
        }
        new_subtasks << subtask
      }.clear
      parameters.uniq!
      unless operators.assoc(name)
        operators << [name, parameters, precond_pos, precond_not, effect_add, effect_del]
        puts "Macro operator #{name}" if debug
      end
      new_subtasks.insert(index, [name, *parameters])
    elsif macro.size == 1
      op, subtask = macro.shift
      if counter[op.first] != 1
        unless operators.assoc(name = "invisible_macro_#{op.first}")
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