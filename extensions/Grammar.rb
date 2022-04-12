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
      met.drop(2).each {|dec|
        production_or << "#{met.first}_#{dec.first}(#{parameters})"
        production_and = dec[4].map {|subtask,*terms| "#{subtask}(#{terms.join(' ')})"}
        puts "#{met.first}_#{dec.first}(#{parameters}) ->\n  #{production_and.empty? ? 'empty' : production_and.join(" &\n  ")}"
      }
      puts "#{left_token} ->\n  #{production_or.empty? ? 'empty' : production_or.join(" |\n  ")}"
    }
  end
end