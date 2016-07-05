module Markdown_Compiler
  extend self

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not)
    output = "# #{domain_name.capitalize}\n## Predicates\n"
    predicates.each {|k,v| output << "- #{k}: #{v ? 'mutable' : 'invariant'}\n"}
    output << "\n## Operators"
    operators.each {|op|
      output << "\n#{op.first.capitalize} | #{op[1].join(' ')}\n--- | ---\n***Preconditions*** | ***Effects***"
      op[2].each {|pre| output << "\n(#{pre.join(' ')}) |#{" **not** (#{pre.join(' ')})" if op[5].include?(pre)}"}
      op[3].each {|pre| output << "\n**not** (#{pre.join(' ')}) |#{" (#{pre.join(' ')})" if op[4].include?(pre)}"}
      op[4].each {|pre| output << "\n| (#{pre.join(' ')})" unless op[3].include?(pre)}
      op[5].each {|pre| output << "\n| **not** (#{pre.join(' ')})" unless op[2].include?(pre)}
      output << "\n"
    }
    output << "\n## Methods"
    methods.each {|met|
      output << "\n**#{met.first.capitalize}(#{met[1].join(' ')})**"
      met.drop(2).each {|met_case|
        output << "\n- #{met_case.first}(#{met[1].join(' ')})\n  - Preconditions:"
        met_case[2].each {|pre| output << "\n    - (#{pre.join(' ')})"}
        met_case[3].each {|pre| output << "\n    - **not** (#{pre.join(' ')})"}
        output << "\n  - Subtasks:"
        met_case[4].each {|task| output << "\n    - (#{task.join(' ')})"}
      }
      output << "\n"
    }
    output
  end

  #-----------------------------------------------
  # Compile problem
  #-----------------------------------------------

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename)
    output = "# #{problem_name.capitalize} of #{domain_name.capitalize}\n## Initial state"
    state.each {|pre| output << "\n- (#{pre.join(' ')})"}
    output << "\n\n## Tasks"
    unless tasks.empty?
      ordered = tasks.shift
      output << (ordered ? "\n**ordered**" : "\n**unordered**")
      tasks.each {|task| output << "\n- (#{task.join(' ')})"}
      tasks.unshift(ordered)
    end
    output << "\n\n## Goal state"
    goal_pos.each {|pre| output << "\n- (#{pre.join(' ')})"}
    goal_not.each {|pre| output << "\n- **not** (#{pre.join(' ')})"}
    output
  end
end