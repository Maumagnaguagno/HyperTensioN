module Grammar
  extend self

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(operators, methods, predicates, state, tasks, goal_pos, goal_not)
    puts 'Grammar'.center(50,'-'), 'Production rules'
    methods.each {|met|
      parameters = met[1].join(' ')
      production_or = met.drop(2).map! {|dec|
        production_and = dec[4].map {|subtask,*terms| "#{subtask}(#{terms.join(' ')})"}
        puts "#{met[0]}_#{dec[0]}(#{parameters}) ->\n  #{production_and.empty? ? 'empty' : production_and.join(" &\n  ")}"
        "#{met[0]}_#{dec[0]}(#{parameters})"
      }
      puts "#{met[0]}(#{parameters}) ->\n  #{production_or.empty? ? 'empty' : production_or.join(" |\n  ")}"
    }
  end
end