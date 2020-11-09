module Hyper_Compiler
  extend self

  SPACER = '-' * 47

  #-----------------------------------------------
  # Predicates to Hyper
  #-----------------------------------------------

  def predicates_to_hyper(output, predicates)
    if predicates.empty?
      output << "\n      []"
    else
      predicates = predicates.map {|g| g.map.with_index {|i,j| j == 0 ? "?#{i == '=' ? 'EQUAL' : i.upcase}" : i}}
      output << "\n      [\n        [" << predicates.map {|g| g.map {|i| i.start_with?('?') ? i.delete('?') : "'#{i}'"}.join(', ')}.join("],\n        [") << "]\n      ]"
    end
  end

  def predicate_to_hyper(output, pre, terms, predicates)
    if predicates[pre] then output << "@state[#{pre.upcase}].include?(#{terms_to_hyper(terms)})"
    else output << "#{pre.upcase}.include?(#{terms_to_hyper(terms)})"
    end
  end

  #-----------------------------------------------
  # Terms to Hyper
  #-----------------------------------------------

  def terms_to_hyper(terms)
    terms.size == 1 ? terms.map! {|t| term(t)}.join(', ') : "[#{terms.map! {|t| term(t)}.join(', ')}]"
  end

  #-----------------------------------------------
  # Subtasks to Hyper
  #-----------------------------------------------

  def subtasks_to_hyper(tasks, indentation)
    if tasks.empty? then "#{indentation}yield []"
    else "#{indentation}yield [#{indentation}  [" << tasks.map {|g| g.map {|i| term(i)}.join(', ')}.join("],#{indentation}  [") << "]#{indentation}]"
    end
  end

  #-----------------------------------------------
  # Term
  #-----------------------------------------------

  def term(t)
    t.start_with?('?') ? t.delete('?') : ":#{t}"
  end

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, hypertension_filename = File.expand_path('../../Hypertension', __FILE__))
    domain_str = "module #{domain_name.capitalize}\n  include Hypertension\n  extend self\n\n  ##{SPACER}\n  # Domain\n  ##{SPACER}\n\n  @domain = {\n    # Operators"
    # Operators
    define_operators = ''
    operators.each_with_index {|(name,param,precond_pos,precond_not,effect_add,effect_del),i|
      domain_str << "\n    :#{name} => #{!name.start_with?('invisible_')}#{',' unless operators.size.pred == i and methods.empty?}"
      define_operators << "\n  def #{name}#{"(#{param.join(', ').delete!('?')})" unless param.empty?}"
      equality = []
      precond_pos.each {|pre,*terms|
        if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
        elsif not predicates[pre] and not state.include?(pre) then define_operators << "\n    return"
        else predicate_to_hyper(define_operators << "\n    return unless ", pre, terms, predicates)
        end
      }
      precond_not.each {|pre,*terms|
        if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
        elsif predicates[pre] or state.include?(pre) then predicate_to_hyper(define_operators << "\n    return if ", pre, terms, predicates)
        end
      }
      define_operators << "\n    return if #{equality.join(' or ')}" unless equality.empty?
      unless effect_add.empty? and effect_del.empty?
        define_operators << "\n    @state = @state.dup"
        duplicated = {}
        effect_del.each {|pre,*terms|
          if duplicated.include?(pre)
            define_operators << "\n    @state[#{pre.upcase}].delete(#{terms_to_hyper(terms)})"
          else
            define_operators << "\n    (@state[#{pre.upcase}] = @state[#{pre.upcase}].dup).delete(#{terms_to_hyper(terms)})"
            duplicated[pre] = nil
          end
        }
        effect_add.each {|pre,*terms|
          if duplicated.include?(pre)
            define_operators << "\n    @state[#{pre.upcase}].unshift(#{terms_to_hyper(terms)})"
          else
            define_operators << "\n    (@state[#{pre.upcase}] = @state[#{pre.upcase}].dup).unshift(#{terms_to_hyper(terms)})"
            duplicated[pre] = nil
          end
        }
      end
      define_operators << "\n    true\n  end\n"
    }
    # Methods
    define_methods = ''
    domain_str << "\n    # Methods"
    methods.each_with_index {|(name,param,*decompositions),mi|
      domain_str << "\n    :#{name} => [\n"
      variables = param.empty? ? nil : "(#{param.join(', ').delete!('?')})"
      decompositions.each_with_index {|dec,i|
        domain_str << "      :#{name}_#{dec.first}#{',' if decompositions.size - 1 != i}\n"
        define_methods << "\n  def #{name}_#{dec.first}#{variables}"
        # No preconditions
        if dec[2].empty? and dec[3].empty?
          define_methods << subtasks_to_hyper(dec[4], "\n    ")
        # Ground
        elsif dec[1].empty?
          predicates_to_hyper(define_methods << "\n    if applicable?(\n      # Positive preconditions", dec[2])
          predicates_to_hyper(define_methods << ",\n      # Negative preconditions", dec[3])
          define_methods << "\n    )" << subtasks_to_hyper(dec[4], "\n      ") << "\n    end"
        # Lifted
        else
          dec[1].each {|free| define_methods << "\n    #{free.delete('?')} = ''"}
          predicates_to_hyper(define_methods << "\n    generate(\n      # Positive preconditions", dec[2])
          predicates_to_hyper(define_methods << ",\n      # Negative preconditions", dec[3])
          define_methods << ', ' << dec[1].join(', ').delete!('?')
          define_methods << "\n    ) {" << subtasks_to_hyper(dec[4], "\n      ") << "\n    }"
        end
        define_methods << "\n  end\n"
      }
      domain_str << (methods.size.pred == mi ? '    ]' : '    ],')
    }
    # Definitions
    domain_str << "\n  }\n\n  ##{SPACER}\n  # Operators\n  ##{SPACER}\n#{define_operators}\n  ##{SPACER}\n  # Methods\n  ##{SPACER}\n#{define_methods}end"
    domain_str.gsub!(/\b-\b/,'_')
    hypertension_filename ? "# Generated by Hype\nrequire '#{hypertension_filename}'\n\n#{domain_str}" : domain_str
  end

  #-----------------------------------------------
  # Compile problem
  #-----------------------------------------------

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename = nil)
    # Extract information
    problem_str = "# Predicates\n"
    start = []
    predicates.each_with_index {|(pre,_),i|
      problem_str << "#{pre == '=' ? 'EQUAL' : pre.upcase} = #{i}\n"
      start << []
    }
    predicate_index = predicates.keys
    problem_str << "\n# Objects\n"
    objects = []
    state.each {|pre,k|
      k.each {|terms|
        start[predicate_index.index(pre)] << terms if predicates.include?(pre)
        objects.concat(terms)
      }
    }
    goal_pos.each {|pre,*terms| objects.concat(terms)}
    goal_not.each {|pre,*terms| objects.concat(terms)}
    ordered = tasks.shift
    tasks.each {|pre,*terms| objects.concat(terms)}
    # Objects
    objects.uniq!
    objects.each {|i| problem_str << "#{i} = '#{i}'\n"}
    problem_str << "\n#{domain_name.capitalize}.problem(\n  # Start\n  [\n"
    # Start
    start.each_with_index {|v,i|
      problem_str << '    ['
      problem_str << "\n      [" << v.map! {|obj| obj.join(', ')}.join("],\n      [") << "]\n    " unless v.empty?
      problem_str << (start.size.pred == i ? ']' : "],\n")
    }
    # Tasks
    problem_str << "\n  ],\n  # Tasks\n  [" << tasks.map {|g| "\n    [:#{g.first}#{', ' if g.size > 1}#{g.drop(1).join(', ')}]"}.join(',') << "\n  ],\n  # Debug\n  ARGV.first == 'debug'"
    tasks.unshift(ordered) unless tasks.empty?
    unless ordered
      problem_str << ",\n  # Positive goals\n  [" << goal_pos.map {|g| "\n    [#{g.first.upcase}#{', ' if g.size > 1}#{g.drop(1).join(', ')}]"}.join(',') <<
        "\n  ],\n  # Negative goals\n  [" << goal_not.map {|g| "\n    [#{g.first.upcase}#{', ' if g.size > 1}#{g.drop(1).join(', ')}]"}.join(',') << "\n  ]"
    end
    problem_str.gsub!(/\b-\b/,'_')
    domain_filename ? "# Generated by Hype\nrequire_relative '#{domain_filename}'\n\n#{problem_str}\n) or abort" : "#{problem_str}\n)"
  end
end