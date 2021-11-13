module PDDL_Compiler
  extend self

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not)
    negative_preconditions = false
    declared = {}
    action_str = ''
    # Operators
    operators.each {|op|
      # Header
      action_str << "\n  (:action #{op.first}\n    :parameters (#{op[1].join(' ')})\n    :precondition (and\n"
      # Preconditions
      op[2].each {|pre| action_str << "      (#{pre.join(' ')})\n"; declared[pre.first] ||= pre}
      op[3].each {|pre| action_str << "      (not (#{pre.join(' ')}))\n"; declared[pre.first] ||= pre}
      negative_preconditions = true unless op[3].empty?
      # Effects
      action_str << "    )\n    :effect (and\n"
      op[4].each {|pre| action_str << "      (#{pre.join(' ')})\n"; declared[pre.first] ||= pre}
      op[5].each {|pre| action_str << "      (not (#{pre.join(' ')}))\n"; declared[pre.first] ||= pre}
      action_str << "    )\n  )\n"
    }
    goal_pos.each {|pre| declared[pre.first] ||= pre}
    goal_not.each {|pre| declared[pre.first] ||= pre}
    domain_str = "; Generated by Hype\n(define (domain #{domain_name})
  (:requirements :strips#{' :negative-preconditions' if negative_preconditions}#{' :equality' if declared.delete('=')})\n\n  (:predicates\n"
    declared.each_value {|pre|
      (pre = pre.join(' ?')).squeeze!('?')
      domain_str << "    (#{pre})\n"
    }
    domain_str << "  )\n" << action_str << ')'
  end

  #-----------------------------------------------
  # Compile problem
  #-----------------------------------------------

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename)
    objects = []
    start_str = ''
    state.each {|pre,k|
      objects.concat(k.each {|terms|
        start_str << "    (#{terms.unshift(pre).join(' ')})\n"
        terms.shift
      }.flatten(1)) if pre != '=' and predicates.include?(pre)
    }
    tasks.drop(1).each {|_,*terms| objects.concat(terms)}
    goal_str = ''
    goal_pos.each {|pre|
      objects.concat(pre.drop(1))
      goal_str << "    (#{pre.join(' ')})\n"
    }
    goal_not.each {|pre|
      objects.concat(pre.drop(1))
      goal_str << "    (not (#{pre.join(' ')}))\n"
    }
    objects.uniq!
"; Generated by Hype
(define (problem #{problem_name})
  (:domain #{domain_name})
  (:objects\n    #{objects.join(' ')}\n  )
  (:init\n#{start_str}  )
  (:goal (and\n#{goal_str}  ))\n)"
  end
end