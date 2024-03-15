module HDDL_Compiler
  extend self

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not)
    negative_preconditions = method_preconditions = false
    declared = {}
    action_str = ''
    # Operators
    operators.each {|op|
      # Header
      action_str << "\n  (:action #{op[0]}\n    :parameters (#{op[1].join(' ')})\n    :precondition (and\n"
      # Preconditions
      op[2].each {|pre| action_str << "      (#{pre.join(' ')})\n"; declared[pre[0]] ||= pre}
      op[3].each {|pre| action_str << "      (not (#{pre.join(' ')}))\n"; declared[pre[0]] ||= pre}
      negative_preconditions = true unless op[3].empty?
      # Effects
      action_str << "    )\n    :effect (and\n"
      op[4].each {|pre| action_str << "      (#{pre.join(' ')})\n"; declared[pre[0]] ||= pre}
      op[5].each {|pre| action_str << "      (not (#{pre.join(' ')}))\n"; declared[pre[0]] ||= pre}
      action_str << "    )\n  )\n"
    }
    # Methods
    methods.each {|met|
      action_str << "\n  (:task #{met[0]} :parameters (#{met[1].join(' ')}))"
      task = "\n    :task (#{met[0]} #{met[1].join(' ')})\n    "
      met.drop(2).each {|dec|
        # Header
        action_str << "\n  (:method #{dec[0]}\n    :parameters (#{(met[1] + dec[1]).join(' ')})#{task}:precondition (and\n"
        # Preconditions
        dec[2].each {|pre| action_str << "      (#{pre.join(' ')})\n"; declared[pre[0]] ||= pre}
        dec[3].each {|pre| action_str << "      (not (#{pre.join(' ')}))\n"; declared[pre[0]] ||= pre}
        method_preconditions = true unless dec[2].empty?
        method_preconditions = negative_preconditions = true unless dec[3].empty?
        # Subtasks
        action_str << "    )\n    :ordered-subtasks (and\n"
        dec[4].each {|task| action_str << "      (#{task.join(' ')})\n"}
        action_str << "    )\n  )\n"
      }
    }
    goal_pos.each {|pre| declared[pre[0]] ||= pre}
    goal_not.each {|pre| declared[pre[0]] ||= pre}
    domain_str = "; Generated by Hype\n(define (domain #{domain_name})
#  (:requirements :hierarchy#{' :negative-preconditions' if negative_preconditions}#{' :method-preconditions' if method_preconditions}#{' :equality' if declared.delete('=')})\n\n  (:predicates\n"
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
    tasks_str = ''
    tasks.drop(1).each {|pre|
      objects.concat(pre.drop(1))
      tasks_str << "    (#{pre.join(' ')})\n"
    }
    unless goal_pos.empty? and goal_not.empty?
      goal_str = "(:goal (and\n"
      goal_pos.each {|pre|
        objects.concat(pre.drop(1))
        goal_str << "    (#{pre.join(' ')})\n"
      }
      goal_not.each {|pre|
        objects.concat(pre.drop(1))
        goal_str << "    (not (#{pre.join(' ')}))\n"
      }
      goal_str << "  ))\n  "
    end
    objects.uniq!
"; Generated by Hype
(define (problem #{problem_name})
  (:domain #{domain_name})
  (:objects\n    #{objects.join(' ')}\n  )
  (:init\n#{start_str}  )
  #{goal_str}(:htn :ordered-tasks (and
#{tasks_str}  ))\n)"
  end
end