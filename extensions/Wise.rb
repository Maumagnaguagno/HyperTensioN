module Wise
  extend self

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = true)
    puts 'Wise'.center(50,'-') if debug
    sep = ' '
    state.reject! {|pre|
      unless predicates.include?(pre.first)
        puts "Initial state predicate removed: (#{pre.join(sep)})" if debug
        true
      end
    }
    operators.each {|op|
      name, parameters, precond_pos, precond_not, effect_add, effect_del = op
      # Variable prefix
      parameters.each {|var|
        unless var.start_with?('?')
          puts "#{name} parameter #{var} modified to ?#{var}" if debug
          var.insert(0,'?')
        end
      }
      2.upto(5) {|i|
        op[i].each {|pre|
          pre.drop(1).each {|term|
            if term.start_with?('?')
              unless parameters.include?(term)
                puts "#{name} never declared variable #{term} from (#{pre.join(sep)}), adding to parameters" if debug
                parameters << term
              end
            elsif parameters.include?("?#{term}")
              puts "#{name} contains probable variable #{term} from (#{pre.join(sep)}), modified to ?#{term}" if debug
              term.insert(0,'?')
            end
          }
        }
      }
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
  end
end