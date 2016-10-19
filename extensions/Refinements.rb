module Refinements
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = true)
    puts 'Refinements'.center(50,'-'), 'Simplify' if debug
    # Simplify
    # Initial state
    state.reject! {|pre|
      # Unused predicate
      unless predicates.include?(pre.first)
        puts "Initial state unused predicate: remove (#{pre.join(' ')})" if debug
        true
      end
    }
    # Operators
    # TODO remove invisible operators without preconditions and effects
    operators.each {|name,param,precond_pos,precond_not,effect_add,effect_del|
      prefix_variables(name = "operator #{name}", param, debug)
      define_variables(name, param, [precond_pos, precond_not, effect_add, effect_del], debug)
      # Precondition contradiction
      (precond_pos & precond_not).each {|pre| puts "#{name} preconditions: contains contradiction (#{pre.join(' ')}) and (not (#{pre.join(' ')}))"} if debug
      # Remove effect contradiction
      (effect_add & effect_del).each {|pre|
        puts "  operator #{name} effect contradiction: remove (not (#{pre.join(' ')}))" if debug
        effect_del.delete(pre)
      }
      # Effect contained in precondition
      effect_add.reject! {|pre|
        if precond_pos.include?(pre)
          puts "  operator #{name} effect present in precondition: remove (#{pre.join(' ')})" if debug
          true
        end
      }
      effect_del.reject! {|pre|
        if precond_not.include?(pre)
          puts "  operator #{name} effect present in precondition: remove (not (#{pre.join(' ')}))" if debug
          true
        end
      }
      # Unknown previous state of predicate
      if debug
        precond_all = precond_pos | precond_not
        (effect_add - precond_all).each {|pre| puts "  operator #{name} contains side effect: (#{pre.join(' ')})"}
        (effect_del - precond_all).each {|pre| puts "  operator #{name} contains side effect: (not (#{pre.join(' ')}))"}
      end
    }
    # Methods
    # TODO test arity of subtasks
    methods.each {|met|
      name, param, *decompositions = met
      prefix_variables(name = "method #{name}", param, debug)
      decompositions.each {|label,free,precond_pos,precond_not,subtasks|
        label = "#{name} #{label}"
        param.each {|p| puts "  #{label} shadowing variable #{p}" if free.include?(p)} if debug
        (precond_pos & precond_not).each {|pre| puts "  #{label} preconditions contains contradiction (#{pre.join(' ')}) and (not (#{pre.join(' ')}))"} if debug
        prefix_variables(label, free, debug)
        define_variables(label, param + free, [precond_pos, precond_not, subtasks], debug)
      }
    }
    # Macro sequential operators
    puts 'Macro' if debug
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
  # Prefix variables
  #-----------------------------------------------

  def prefix_variables(name, param, debug)
    param.each {|var|
      unless var.start_with?('?')
        puts "  #{name} parameter #{var} modified to ?#{var}" if debug
        var.prepend('?')
      end
    }
  end

  #-----------------------------------------------
  # Define variables
  #-----------------------------------------------

  def define_variables(name, param, group, debug)
    group.each {|predicates|
      predicates.each {|pre|
        pre.drop(1).each {|term|
          if term.start_with?('?')
            raise "#{name} never declared variable #{term} from (#{pre.join(' ')})" unless param.include?(term)
          elsif param.include?("?#{term}")
            puts "  #{name} contains probable variable #{term} from (#{pre.join(' ')}), modifying to ?#{term}" if debug
            term.prepend('?')
          end
        }
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
      macro.each_with_index {|(op,param),i|
        # Header
        name << '_and_' unless i.zero?
        name << op.first.sub(/^invisible_/,'')
        parameters.concat(param)
        # Preconditions
        op[2].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          puts "  Precondition (not (#{pre.join(' ')})) will never be satisfied" if debug and (precond_not.include?(pre) or effect_del.include?(pre))
          precond_pos << pre unless precond_pos.include?(pre) or effect_add.include?(pre)
        }
        op[3].each {|pre|
          pre = pre.map {|p| p.start_with?('?') ? param[op[1].index(p)] : p}
          puts "  Precondition (#{pre.join(' ')}) will never be satisfied" if debug and (precond_pos.include?(pre) or effect_add.include?(pre))
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