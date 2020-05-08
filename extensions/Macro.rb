module Macro
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = false)
    puts 'Macro'.center(50,'-') if debug
    # Macro sequential operators
    macro = []
    methods.each {|met|
      met.drop(2).each {|dec|
        new_subtasks = []
        dec[4].each {|subtask|
          # Add operators to macro and skip methods
          unless subtask.first.end_with?('_dup')
            if op = operators.assoc(subtask.first)
              macro << [op, subtask.drop(1)]
            else
              add_macro_to_subtasks(operators, macro, new_subtasks, debug)
              new_subtasks << subtask
            end
          end
        }
        add_macro_to_subtasks(operators, macro, new_subtasks, debug)
        dec[4] = new_subtasks
      }
    }
  end

  #-----------------------------------------------
  # Add macro to subtasks
  #-----------------------------------------------

  def add_macro_to_subtasks(operators, macro, new_subtasks, debug)
    if macro.size > 1
      name = 'invisible_'
      parameters = []
      precond_pos = []
      precond_not = []
      effect_add = []
      effect_del = []
      index = new_subtasks.size
      first_task = false
      macro.each {|op,param|
        # Header
        unless first_task
          name << '_and_'
          first_task = true
        end
        name << op.first.sub(/^invisible_/,'')
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
        # Duplicate visible operators without preconditions or effects to keep plan consistent
        unless op.first.start_with?('invisible_')
          new_subtasks << param.unshift(name_dup = "#{op.first}_dup")
          unless operators.assoc(name_dup)
            operators << [name_dup, variables, [], [], [], []]
            puts "Duplicate operator #{op.first}" if debug
          end
        end
      }.clear
      parameters.uniq!
      unless operators.assoc(name)
        operators << [name, parameters, precond_pos, precond_not, effect_add, effect_del]
        puts "Macro operator #{name}" if debug
      end
      new_subtasks.insert(index, [name, *parameters])
    elsif macro.size == 1
      op, param = macro.shift
      new_subtasks << param.unshift(op.first)
    end
  end
end