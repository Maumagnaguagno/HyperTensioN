module Markdown_Compiler
  extend self

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not)
    output = "# #{domain_name.capitalize}\n ## Operators"
    operators.each {|op|
      output << "\n\n#{op.first.capitalize} | #{op[1].join(' ')}\n--- | ---\n***Preconditions*** | ***Effects***"
      op[2].each {|pro| output << "\n(#{pro.join(' ')}) |#{" **not** (#{pro.join(' ')})" if op[5].include?(pro)}"}
      op[3].each {|pro| output << "\n**not** (#{pro.join(' ')}) |#{" **not** (#{pro.join(' ')})" if op[4].include?(pro)}"}
      (op[4] - op[3]).each {|pro| output << "\n| (#{pro.join(' ')})"}
      (op[5] - op[2]).each {|pro| output << "\n| **not** (#{pro.join(' ')})"}
      output << "\n---"
    }
    output
  end

  #-----------------------------------------------
  # Compile problem
  #-----------------------------------------------

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename)
    # TODO
  end
end