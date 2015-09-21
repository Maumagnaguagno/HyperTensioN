module Fast
  extend self

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = true)
    puts 'Fast'.center(50,'-'), 'Removing unused propositions from initial state' if debug
    state.reject! {|pro|
      unless predicates.include?(pro.first)
        puts "  (#{pro.join(' ')})" if debug
        true
      end
    }
    puts 'Removing precondition contained effects' if debug
    operators.each {|op|
      puts "  #{op.first}"
      op[4].reject! {|eff|
        if op[2].include?(eff)
          puts "    (#{eff.join(' ')})" if debug
          true
        end
      }
      op[5].reject! {|eff|
        if op[3].include?(eff)
          puts "    (not (#{eff.join(' ')}))" if debug
          true
        end
      }
    }
    # TODO count how many times am operator is used by the required tasks (from none to recursive)
    # TODO generate duplicates of such operators
    # TODO cluster sequential operators
    # TODO clean preconditions based on hierarchy
  end
end