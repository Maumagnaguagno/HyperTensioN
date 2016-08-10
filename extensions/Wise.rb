module Wise
  extend self

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = true)
    puts 'Wise'.center(50,'-') if debug
    sep = ' '
    # Initial state
    state.reject! {|pre|
      unless predicates.include?(pre.first)
        puts "Initial state predicate removed: (#{pre.join(sep)})" if debug
        true
      end
    }
    # Operators
    operators.each {|op|
      name, param, precond_pos, precond_not, effect_add, effect_del = op
      prefixed_variables(name, param, debug)
      defined_variables(name, param, op, 2, 5, debug)
      # Effect contained in precondition
      effect_add.reject! {|pre|
        if precond_pos.include?(pre)
          puts "#{name} effect removed: (#{pre.join(sep)})" if debug
          true
        end
      }
      effect_del.reject! {|pre|
        if precond_not.include?(pre)
          puts "#{name} effect removed: (not (#{pre.join(sep)}))" if debug
          true
        end
      }
      # Unknown previous state of predicate
      if debug
        (precond_all = precond_pos + precond_not).uniq!
        side_effects = effect_add - precond_all
        side_effects.each {|pre| puts "#{name} contains side effect: (#{pre.join(sep)})"} unless side_effects.empty?
        side_effects = effect_del - precond_all
        side_effects.each {|pre| puts "#{name} contains side effect: (not (#{pre.join(sep)}))"} unless side_effects.empty?
      end
    }
    # Methods
    methods.each {|met|
      name, param, *decompositions = met
      prefixed_variables(name, param, debug)
      decompositions.each {|dec|
        label, free, precond_pos, precond_not, subtasks = dec
        param.each {|p| puts "#{label} shadowing variable #{p}" if free.include?(p)} if debug
        prefixed_variables(label, free, debug)
        defined_variables(name, param + free, dec, 2, 4, debug)
      }
    }
  end

  def prefixed_variables(name, param, debug)
    param.each {|var|
      unless var.start_with?('?')
        puts "#{name} parameter #{var} modified to ?#{var}" if debug
        var.prepend('?')
      end
    }
  end
  
  def defined_variables(name, param, group, min, max, debug)
    min.upto(max) {|i|
      group[i].each {|pre|
        pre.drop(1).each {|term|
          if term.start_with?('?')
            unless param.include?(term)
              puts "#{name} never declared variable #{term} from (#{pre.join(sep)}), adding to parameters" if debug
              param << term
            end
          elsif param.include?("?#{term}")
            puts "#{name} contains probable variable #{term} from (#{pre.join(sep)}), modified to ?#{term}" if debug
            term.prepend('?')
          end
        }
      }
    }
  end
end