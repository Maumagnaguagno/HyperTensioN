module Grammar
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not)
    puts 'Grammar'.center(50,'-'), 'Production rules'
    methods.each {|met|
      parameters = met[1].join(' ')
      left_token = "#{met.first}(#{parameters})"
      production_or = []
      met.drop(2).each {|cases|
        production_or << "#{cases.first}(#{parameters})"
        production_and = []
        cases[4].each {|subtask| production_and << "#{subtask.first}(#{subtask.drop(1).join(' ')})"}
        puts "#{cases.first}(#{parameters}) ->\n  #{production_and.empty? ? 'empty' : production_and.join(" &\n  ")}"
      }
      next if production_or.size == 1 and production_or.first == left_token
      puts "#{left_token} ->\n  #{production_or.empty? ? 'empty' : production_or.join(" |\n  ")}"
    }
  end
end