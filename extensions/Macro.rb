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
          if op = operators.assoc(subtask.first)
            macro << [op, subtask.drop(1)]
          else
            add_macro_to_subtasks(operators, macro, new_subtasks, debug)
            new_subtasks << subtask
          end
        }
        add_macro_to_subtasks(operators, macro, new_subtasks, debug)
        dec[4] = new_subtasks
      }
    }
    # TODO pull up preconditions based on hierarchy
    # TODO compress variable/method/invisible operator names
    # TODO compress predicate names (changes final state description)
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
      macro.each_with_index {|(op,param),i|
        # Header
        next if op.first.end_with?('_dup')
        name << '_and_' unless i.zero?
        name << op.first.sub(/^invisible_/,'')
        parameters.concat(param)
        # Preconditions
        op[2].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          puts "Precondition (not (#{pre.join(' ')})) will never be satisfied" if debug and (precond_not.include?(pre) or effect_del.include?(pre))
          precond_pos << pre unless precond_pos.include?(pre) or effect_add.include?(pre)
        }
        op[3].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          puts "Precondition (#{pre.join(' ')}) will never be satisfied" if debug and (precond_pos.include?(pre) or effect_add.include?(pre))
          precond_not << pre unless precond_not.include?(pre) or effect_del.include?(pre)
        }
        # Effects
        op[4].each {|pre|
          effect_del.delete(pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p})
          effect_add << pre unless effect_add.include?(pre)
        }
        op[5].each {|pre|
          effect_add.delete(pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p})
          effect_del << pre unless effect_del.include?(pre)
        }
        # Duplicate visible operators without preconditions or effects to keep plan consistent
        unless op.first.start_with?('invisible_')
          new_subtasks << param.unshift(name_dup = "#{op.first}_dup")
          unless operators.assoc(name_dup)
            operators << [name_dup, op[1], [], [], [], []]
            puts "Duplicate operator #{op.first}" if debug
          end
        end
      }.clear
      parameters.uniq!
      unless operators.assoc(name)
        operators << [name, parameters, precond_pos, precond_not, effect_add, effect_del]
        puts "Macro operator #{name}" if debug
      end
      new_subtasks.unshift([name, *parameters])
    elsif macro.size == 1
      op, param = macro.shift
      new_subtasks << param.unshift(op.first)
    end
  end
end