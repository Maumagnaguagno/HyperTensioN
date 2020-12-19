module Hyper_Compiler
  extend self

  SPACER = '-' * 47

  #-----------------------------------------------
  # Predicate to Hyper
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
    terms.size == 1 ? term(terms[0]) : "[#{terms.map! {|t| term(t)}.join(', ')}]"
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
    t.start_with?('?') ? t.tr('?','_') : ":#{t}"
  end

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, hypertension_filename = File.expand_path('../../Hypertension', __FILE__))
    domain_str = "module #{domain_name.capitalize}\n  include Hypertension\n  extend self\n\n  ##{SPACER}\n  # Domain\n  ##{SPACER}\n\n  @domain = {\n    # Operators"
    # Operators
    define_operators = ''
    state_visit = -1 if operators.any? {|name,param| param.empty? and name.start_with?('invisible_visit_', 'invisible_mark_')}
    operators.each_with_index {|(name,param,precond_pos,precond_not,effect_add,effect_del),i|
      domain_str << "\n    :#{name} => #{!name.start_with?('invisible_')}#{',' unless operators.size.pred == i and methods.empty?}"
      define_operators << "\n  def #{name}#{"(#{paramstr = param.join(', ').tr!('?','_')})" unless param.empty?}"
      if state_visit
        if name.start_with?('invisible_visit_', 'invisible_mark_')
          define_operators << "\n    return if @state_visit#{state_visit += 1}.include?(@state)\n    @state_visit#{state_visit} << @state\n    true\n  end\n"
          next
        elsif name.start_with?('invisible_unvisit_', 'invisible_unmark_')
          define_operators << "\n    true\n  end\n"
          next
        end
      elsif name.start_with?('invisible_visit_')
        define_operators << "\n    @visit[#{param.size > 1 ? "[#{paramstr}]" : paramstr}] = nil"
      elsif name.start_with?('invisible_unvisit_')
        define_operators << "\n    @visit.clear"
      end
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
    visit = false
    define_methods = ''
    domain_str << "\n    # Methods"
    methods.each_with_index {|(name,param,*decompositions),mi|
      domain_str << "\n    :#{name} => [\n"
      variables = "(#{param.join(', ').tr!('?','_')})" unless param.empty?
      decompositions.each_with_index {|dec,i|
        domain_str << "      :#{name}_#{dec.first}#{',' if decompositions.size - 1 != i}\n"
        define_methods << "\n  def #{name}_#{dec.first}#{variables}"
        paramstr = nil
        dec[4].each {|s|
          if s.size > 1 and s.first.start_with?('invisible_visit_')
            paramstr = s.drop(1)
            visit = true
            break
          end
        }
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
          if terms.empty? and pre.start_with?('visited_') then predicates[pre] = nil
          elsif not predicates[pre] and not state.include?(pre) then true
          elsif (terms & f).empty?
            if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
            elsif predicates[pre] or state.include?(pre) then predicate_to_hyper(define_methods_comparison << "\n    return if ", pre, terms, predicates)
            end
          end
        }
        define_methods << "\n    return if #{equality.join(' or ')}" unless equality.empty?
        define_methods << define_methods_comparison
        if paramstr and (paramstr & f).empty?
          define_methods << "\n    return if @visit.include?(#{paramstr.map! {|j| term(j)}.size > 1 ? "[#{paramstr.join(', ')}]" : paramstr.first})"
          paramstr = nil
        end
        close_method_str = "\n  end\n"
        indentation = "\n    "
        # Lifted
        unless f.empty?
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
                equality << "#{j}_ground != #{j}".tr!('?','_')
                term("#{j}_ground")
              else
                new_grounds = true
                ground << f.delete(j)
                term(j)
              end
            }
            if new_grounds
              if predicates[pre] then define_methods << "#{indentation}@state[#{pre.upcase}].each {|#{terms2.join(', ')}|"
              else
                define_methods << "#{indentation}return" unless state.include?(pre)
                define_methods << "#{indentation}#{pre == '=' ? 'EQUAL' : pre.upcase}.each {|#{terms2.join(', ')}|"
              end
              # close_method_str.prepend('}') and no indentation change for compact output
              close_method_str.prepend("#{indentation}}")
              indentation << '  '
            elsif pre == '=' then equality << "#{terms2[0]} != #{terms2[1]}"
            elsif not predicates[pre] and not state.include?(pre) then define_methods << "#{indentation}return"
            else predicate_to_hyper(define_methods_comparison << "#{indentation}next unless ", pre, terms, predicates)
            end
            precond_pos.reject! {|pre,*terms|
              if (terms & f).empty?
                if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
                elsif not predicates[pre] and not state.include?(pre) then define_methods << "#{indentation}return"
                else predicate_to_hyper(define_methods_comparison << "#{indentation}next unless ", pre, terms, predicates)
                end
              end
            }
            precond_not.reject! {|pre,*terms|
              if (terms & f).empty?
                if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
                elsif predicates[pre] or state.include?(pre) then predicate_to_hyper(define_methods_comparison << "#{indentation}next if ", pre, terms, predicates)
                end
              end
            }
            define_methods << "#{indentation}next if #{equality.join(' or ')}" unless equality.empty?
            define_methods << define_methods_comparison
            if paramstr and (paramstr & f).empty?
              define_methods << "#{indentation}next if @visit.include?(#{paramstr.map! {|j| term(j)}.size > 1 ? "[#{paramstr.join(', ')}]" : paramstr.first})"
              paramstr = nil
            end
          end
          equality.clear
          define_methods_comparison.clear
          precond_not.each {|pre,*terms|
            if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
            elsif predicates[pre] or state.include?(pre) then predicate_to_hyper(define_methods_comparison << "#{indentation}next if ", pre, terms, predicates)
            end
          }
          define_methods << "#{indentation}next if #{equality.join(' or ')}" unless equality.empty?
          define_methods << define_methods_comparison
        end
        define_methods << subtasks_to_hyper(dec[4], indentation) << close_method_str
      }
      domain_str << (methods.size.pred == mi ? '    ]' : '    ],')
    }
    if state_visit then (state_visit + 1).times {|i| define_methods << "  @state_visit#{i} = []\n"}
    elsif visit then define_methods << "  @visit = {}\n"
    end
    # Definitions
    domain_str << "\n  }\n\n  ##{SPACER}\n  # Operators\n  ##{SPACER}\n#{define_operators}\n  ##{SPACER}\n  # Methods\n  ##{SPACER}\n#{define_methods}end"
    domain_str.gsub!(/\b-\b/,'_')
    hypertension_filename ? "# Generated by Hype\nrequire '#{hypertension_filename}'\n\n#{domain_str}" : domain_str
  end

  #-----------------------------------------------
  # Compile problem
  #-----------------------------------------------

  def compile_problem(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, domain_filename = nil)
    # Start
    problem_str = "# Predicates\n"
    start_str = "\n#{domain = domain_name.capitalize}.problem(\n  # Start\n  [\n"
    counter = -1
    predicates.each {|pre,type|
      if k = state[pre]
        unary = k[0].size == 1
      end
      if type
        problem_str << "#{pre.upcase} = #{counter += 1}\n"
        start_str << '    ['
        start_str << "\n      #{'[' unless unary}" << k.map! {|obj| ':' << obj.join(', :') unless obj.empty?}.join(unary ? ",\n      " : "],\n      [") << "#{']' unless unary}\n    " if k
        start_str << "],\n"
      elsif k
        problem_str << "#{pre == '=' ? 'EQUAL' : pre.upcase} = ["
        problem_str << "\n  #{'[' unless unary}" << k.map! {|obj| ':' << obj.join(', :') unless obj.empty?}.join(unary ? ",\n  " : "],\n  [") << (unary ? "\n]\n" : "]\n]\n")
      end
    }
    # Tasks
    ordered = tasks.shift
    problem_str << start_str << "  ],\n  # Tasks\n  [" << tasks.map {|g| "\n    [:#{g.join(', :')}]"}.join(',') << "\n  ],\n  # Debug\n  ARGV.first == 'debug'\n)"
    tasks.unshift(ordered) unless tasks.empty?
    unless ordered
      problem_str << (goal_pos.empty? && goal_not.empty? ? ' {true}' :
      " {\n  # Goal\n  " << goal_pos.map {|pre,*terms| "#{domain}.state[#{pre.upcase}].include?(#{terms_to_hyper(terms)})"}.concat(goal_not.map {|pre,*terms| "not #{domain}.state[#{pre.upcase}].include?(#{terms_to_hyper(terms)})"}).join(" and\n  ") << "\n}")
    end
    problem_str.gsub!(/\b-\b/,'_')
    domain_filename ? "# Generated by Hype\nrequire_relative '#{domain_filename}'\n\n#{problem_str} or abort" : problem_str
  end
end