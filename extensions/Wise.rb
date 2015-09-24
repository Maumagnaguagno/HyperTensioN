module Fast
  extend self

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not, debug = true)
    puts 'Fast'.center(50,'-'), 'Removing unused propositions from initial state' if debug
    sep = ' '
    state.reject! {|pro|
      unless predicates.include?(pro.first)
        puts "  (#{pro.join(sep)})" if debug
        true
      end
    }
    puts 'Removing precondition contained effects' if debug
    operators.each {|op|
      puts "  #{op.first}"
      op[4].reject! {|eff|
        if op[2].include?(eff)
          puts "    (#{eff.join(sep)})" if debug
          true
        end
      }
      op[5].reject! {|eff|
        if op[3].include?(eff)
          puts "    (not (#{eff.join(sep)}))" if debug
          true
        end
      }
    }
    if debug
      puts 'Side effects'
      operators.each {|op|
        puts "  #{op.first}"
        (preconditions = op[2] + op[3]).uniq!
        (objects = preconditions.inject([]) {|s,pro| s.concat(pro.drop(1))}).uniq!
        side_effects = op[4] - preconditions
        side_effects.each {|pro| puts "    (#{pro.join(sep)})\n      free objects: #{(pro.drop(1) - objects).join(sep)}"} unless side_effects.empty?
        side_effects = op[5] - preconditions
        side_effects.each {|pro| puts "    (not (#{pro.join(sep)}))\n      free objects: #{(pro.drop(1) - objects).join(sep)}"} unless side_effects.empty?
      }
      puts 'Variable identified as constant'
      operators.each {|op|
        puts "  #{op.first}"
        op[1].any? {|var| puts "    missing '?' in #{var}" unless var.start_with?('?')}
        2.upto(5) {|i| op[i].each {|pro| pro.drop(1).each {|term| puts "    missing '?' in #{term} on (#{pro.join(sep)})" if op[1].include?("?#{term}")}}}
      }
    end
    # TODO check if constant term is not a variable with missing prefix
    # TODO count how many times am operator is used by the required tasks (from none to recursive)
    # TODO generate duplicates of such operators
    # TODO cluster sequential operators
    # TODO clean preconditions based on hierarchy
  end
end
