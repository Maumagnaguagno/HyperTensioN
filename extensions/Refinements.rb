module Refinements
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = true)
    puts 'Refinements'.center(50,'-'), 'Macro' if debug
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
    # TODO compress predicate/variable/method/invisible operator names (changes final state description)
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
        name << '_and_' unless i.zero?
        name << op.first.sub(/^invisible_/,'')
        parameters.concat(param)
        # Preconditions
        op[2].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          puts "  Precond (not (#{pre.join(' ')})) will never be satisfied" if debug and (precond_not.include?(pre) or effect_del.include?(pre))
          precond_pos << pre unless precond_pos.include?(pre) or effect_add.include?(pre)
        }
        op[3].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          puts "  Precond (#{pre.join(' ')}) will never be satisfied" if debug and (precond_pos.include?(pre) or effect_add.include?(pre))
          precond_not << pre unless precond_not.include?(pre) or effect_del.include?(pre)
        }
        # Effects
        op[4].each {|pre|
          effect_add << pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          effect_del.delete(pre)
        }
        op[5].each {|pre|
          effect_del << pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          effect_add.delete(pre)
        }
        # Duplicate visible operators without preconditions or effects to keep plan consistent
        unless op.first.start_with?('invisible_')
          new_subtasks << param.unshift(name_dup = "#{op.first}_dup")
          unless operators.assoc(name_dup)
            operators << [name_dup, op[1], [], [], [], []]
            puts "  Duplicate operator #{op.first}" if debug
          end
        end
      }
      parameters.uniq!
      # TODO name may not be enough to match, variable usage may require a new macro operator
      unless operators.assoc(name)
        operators << [name, parameters, precond_pos, precond_not, effect_add, effect_del]
        puts "  Macro operator #{name}"
      end
      new_subtasks.unshift([name, *parameters])
      macro.clear
    elsif macro.size == 1
      op, param = macro.shift
      new_subtasks << param.unshift(op.first)
    end
  end
end