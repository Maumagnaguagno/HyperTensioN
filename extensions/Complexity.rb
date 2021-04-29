module Complexity
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not)
    puts 'Complexity'.center(50,'-')
    domain_complexity = problem_complexity = 0
    # Domain
    operators.each {|op|
      op_complexity = op[1].size
      2.upto(5) {|i| op[i].each {|pre| op_complexity += pre.uniq.size}}
      domain_complexity += op_complexity
      puts "  #{op.first}: #{op_complexity}"
    }
    methods.each {|met|
      met_complexity = met[1].size
      met.drop(2).each {|dec| 2.upto(4) {|i| dec[i].each {|pre| met_complexity += pre.uniq.size}}}
      domain_complexity += met_complexity
      puts "  #{met.first}: #{met_complexity}"
    }
    # Problem
    state.each_value {|k| k.each {|terms| problem_complexity += terms.uniq.size + 1}}
    goal_pos.each {|pre| problem_complexity += pre.uniq.size}
    goal_not.each {|pre| problem_complexity += pre.uniq.size}
    tasks.drop(1).each {|t| problem_complexity += t.uniq.size}
    puts "Domain complexity: #{domain_complexity}",
         "Problem complexity: #{problem_complexity}",
         "Total complexity: #{domain_complexity + problem_complexity}"
  end
end