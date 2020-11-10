module Hyper_Compiler
  extend self

  SPACER = '-' * 47

  #-----------------------------------------------
  # Predicates to Hyper
  #-----------------------------------------------

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
      paramstr = "(#{param.join(', ').delete!('?')})" unless param.empty?
      decompositions.each_with_index {|dec,i|
        domain_str << "      :#{name}_#{dec.first}#{',' if decompositions.size - 1 != i}\n"
        define_methods << "\n  def #{name}_#{dec.first}#{paramstr}"
        equality = []
        define_methods_comparison = ''
        f = dec[1]
        precond_pos = dec[2].sort_by {|pre| (pre & param).size * -100 - (pre & f).size}
        precond_pos.reject! {|pre,*terms|
          if (terms & f).empty?
            if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
            elsif not predicates[pre] and not state.include?(pre) then define_methods << "\n    return"
            else predicate_to_hyper(define_methods_comparison << "\n    return unless ", pre, terms, predicates)
            end
          end
        }
        precond_not = dec[3].reject {|pre,*terms|
          if not predicates[pre] and not state.include?(pre) then true
          elsif (terms & f).empty?
            if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
            elsif predicates[pre] or state.include?(pre) then predicate_to_hyper(define_methods_comparison << "\n    return if ", pre, terms, predicates)
            end
          end
        }
        define_methods << "\n    return if #{equality.join(' or ')}" unless equality.empty?
        define_methods << define_methods_comparison
        # Ground
        if f.empty? then define_methods << subtasks_to_hyper(dec[4], "\n    ")
        # Lifted
        else
          iterator_count = 0
          ground = param.dup
          until precond_pos.empty?
            pre, *terms = precond_pos.shift
            equality.clear
            define_methods_comparison.clear
            new_grounds = false
            terms2 = terms.map {|j|
              if not j.start_with?('?')
                equality << "_#{j}_ground != :#{j}"
                "_#{j}_ground"
              elsif ground.include?(j)
                equality << "#{j}_ground != #{j}".delete!('?')
                term("#{j}_ground")
              else
                new_grounds = true
                ground << f.delete(j)
                term(j)
              end
            }
            if new_grounds
              if predicates[pre] then define_methods << "\n    @state[#{pre.upcase}].each {|#{terms2.join(', ')}|"
              else
                define_methods << "\n    return" unless state.include?(pre)
                define_methods << "\n    #{pre == '=' ? 'EQUAL' : pre.upcase}.each {|#{terms2.join(', ')}|"
              end
              iterator_count += 1
            elsif pre == '=' then equality << "#{terms2[0]} != #{terms2[1]}"
            elsif not predicates[pre] and not state.include?(pre) then define_methods << "\n    return"
            else predicate_to_hyper(define_methods_comparison << "\n    next unless ", pre, terms, predicates)
            end
            precond_pos.reject! {|pre,*terms|
              if (terms & f).empty?
                if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
                elsif not predicates[pre] and not state.include?(pre) then define_methods << "\n    return"
                else predicate_to_hyper(define_methods_comparison << "\n    next unless ", pre, terms, predicates)
                end
              end
            }
            precond_not.reject! {|pre,*terms|
              if (terms & f).empty?
                if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
                elsif predicates[pre] or state.include?(pre) then predicate_to_hyper(define_methods_comparison << "\n    next if ", pre, terms, predicates)
                end
              end
            }
            define_methods << "\n    next if #{equality.join(' or ')}" unless equality.empty?
            define_methods << define_methods_comparison
          end
          equality.clear
          define_methods_comparison.clear
          precond_not.each {|pre,*terms|
            if (terms & f).empty?
              if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
              elsif predicates[pre] or state.include?(pre) then predicate_to_hyper(define_methods_comparison << "\n    next if ", pre, terms, predicates)
              end
            end
          }
          define_methods << "\n    next if #{equality.join(' or ')}" unless equality.empty?
          define_methods << define_methods_comparison << subtasks_to_hyper(dec[4], "\n      ") << "\n    " << '}' * iterator_count
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