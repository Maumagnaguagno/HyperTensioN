module Wise
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = true)
    puts 'Wise'.center(50,'-') if debug
    # Initial state
    state.reject! {|pre|
      unless predicates.include?(pre.first)
        puts "Initial state predicate removed: (#{pre.join(' ')})" if debug
        true
      end
    }
    # Operators
    operators.each {|name,param,precond_pos,precond_not,effect_add,effect_del|
      prefix_variables(name = "operator #{name}", param, debug)
      define_variables(name, param, [precond_pos, precond_not, effect_add, effect_del], debug)
      # Precondition contradiction
      (precond_pos & precond_not).each {|pre| puts "#{name} preconditions contains contradiction (#{pre.join(' ')}) and (not (#{pre.join(' ')}))"} if debug
      # Effect contradiction
      (effect_add & effect_del).each {|pre| puts "#{name} effects contains contradiction (#{pre.join(' ')}) and (not (#{pre.join(' ')}))"} if debug
      # Effect contained in precondition
      effect_add.reject! {|pre|
        if precond_pos.include?(pre)
          puts "#{name} effect removed: (#{pre.join(' ')})" if debug
          true
        end
      }
      effect_del.reject! {|pre|
        if precond_not.include?(pre)
          puts "#{name} effect removed: (not (#{pre.join(' ')}))" if debug
          true
        end
      }
      # Unknown previous state of predicate
      if debug
        precond_all = precond_pos | precond_not
        (effect_add - precond_all).each {|pre| puts "#{name} contains side effect: (#{pre.join(' ')})"}
        (effect_del - precond_all).each {|pre| puts "#{name} contains side effect: (not (#{pre.join(' ')}))"}
      end
    }
    # Methods
    methods.each {|met|
      name, param, *decompositions = met
      prefix_variables(name = "method #{name}", param, debug)
      decompositions.each {|label,free,precond_pos,precond_not,subtasks|
        label = "#{name} #{label}"
        param.each {|p| puts "#{label} shadowing variable #{p}" if free.include?(p)} if debug
        (precond_pos & precond_not).each {|pre| puts "#{label} preconditions contains contradiction (#{pre.join(' ')}) and (not (#{pre.join(' ')}))"} if debug
        prefix_variables(label, free, debug)
        define_variables(label, param + free, [precond_pos, precond_not, subtasks], debug)
      }
    }
  end

  #-----------------------------------------------
  # Prefix variables
  #-----------------------------------------------

  def prefix_variables(name, param, debug)
    param.each {|var|
      unless var.start_with?('?')
        puts "#{name} parameter #{var} modified to ?#{var}" if debug
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
            unless param.include?(term)
              puts "#{name} never declared variable #{term} from (#{pre.join(' ')}), adding to parameters" if debug
              param << term
            end
          elsif param.include?("?#{term}")
            puts "#{name} contains probable variable #{term} from (#{pre.join(' ')}), modifying to ?#{term}" if debug
            term.prepend('?')
          end
        }
      }
    }
  end
end