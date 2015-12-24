module Markdown_Compiler
  extend self

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not)
    output = "# #{domain_name.capitalize}\n## Predicates\n"
    predicates.each {|k,v| output << "- #{k}: #{v ? 'mutable' : 'constant'}\n"}
    output << "## Operators"
    operators.each {|op|
      output << "\n#{op.first.capitalize} | #{op[1].join(' ')}\n--- | ---\n***Preconditions*** | ***Effects***"
      op[2].each {|pro| output << "\n(#{pro.join(' ')}) |#{" **not** (#{pro.join(' ')})" if op[5].include?(pro)}"}
      op[3].each {|pro| output << "\n**not** (#{pro.join(' ')}) |#{" (#{pro.join(' ')})" if op[4].include?(pro)}"}
      op[4].each {|pro| output << "\n| (#{pro.join(' ')})" unless op[3].include?(pro)}
      op[5].each {|pro| output << "\n| **not** (#{pro.join(' ')})" unless op[2].include?(pro)}
      output << "\n---"
    }
    output << "\n## Methods"
    methods.each {|met|
      output << "\n**#{met.first.capitalize}(#{met[1].join(' ')})**"
      met.drop(2).each {|met_case|
        output << "\n- #{met_case.first}(#{met[1].join(' ')})\n  - Preconditions:"
        met_case[2].each {|pro| output << "\n    - (#{pro.join(' ')})"}
        met_case[3].each {|pro| output << "\n    - **not** (#{pro.join(' ')})"}
        output << "\n  - Subtasks:"
        met_case[4].each {|task| output << "\n    - (#{task.join(' ')})"}
      }
      output << "\n---"
    }
    output
  end

  #-----------------------------------------------
  # Compile problem
  #-----------------------------------------------

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename)
    output = "# #{problem_name.capitalize} of #{domain_name.capitalize}\n## Initial state\n"
    state.each {|pro| output << "- (#{pro.join(' ')})\n"}
    output << "## Tasks\n"
    unless tasks.empty?
      ordered = tasks.shift
      output << (ordered ? "**ordered**\n" : "**unordered**\n")
      tasks.each {|task| output << "- (#{task.join(' ')})\n"}
      tasks.unshift(ordered)
    end
    output << '## Goal state'
    goal_pos.each {|pro| output << "\n- (#{pro.join(' ')})"}
    goal_not.each {|pro| output << "\n- **not** (#{pro.join(' ')})"}
    output
  end
end