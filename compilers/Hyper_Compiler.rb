module Hyper_Compiler
  extend self

  SPACER = '-' * 47

  #-----------------------------------------------
  # Term
  #-----------------------------------------------

  def term(term)
    term.start_with?('?') ? term.tr('?','_') : ":#{term}"
  end

  #-----------------------------------------------
  # Terms to Hyper
  #-----------------------------------------------

  def terms_to_hyper(terms)
    terms.size == 1 ? term(terms[0]) : "[#{terms.map! {|t| term(t)}.join(', ')}]"
  end

  #-----------------------------------------------
  # Applicable
  #-----------------------------------------------

  def applicable(output, pre, terms, predicates)
    if predicates[pre] then output << "@state[#{pre.upcase}].include?(#{terms_to_hyper(terms)})"
    else output << "#{pre.upcase}.include?(#{terms_to_hyper(terms)})"
    end
  end

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def apply(modifier, effects, define_operators, duplicated)
    effects.each {|pre,*terms|
      if duplicated.include?(pre)
        define_operators << "\n    @state[#{pre.upcase}]"
      else
        define_operators << "\n    (@state[#{pre.upcase}] = @state[#{pre.upcase}].dup)"
        duplicated[pre] = nil
      end
      define_operators << ".#{modifier}(#{terms_to_hyper(terms)})"
    }
  end

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, hypertension_filename = File.expand_path('../../Hypertension', __FILE__))
    domain_str = "module #{domain_name.capitalize}\n  include Hypertension\n  extend self\n\n  ##{SPACER}\n  # Domain\n  ##{SPACER}\n\n  @domain = {\n    # Operators"
    meta = false
    # Operators
    define_operators = ''
    state_visit = -1 if operators.any? {|name,param| param.empty? and name.start_with?('invisible_visit_', 'invisible_mark_')}
    # Goal becomes an invisible task
    unless goal_pos.empty? and goal_not.empty?
      tasks << true if tasks.empty?
      tasks << [invisible_goal = 'invisible_goal']
      operators << [invisible_goal, [], goal_pos, goal_not, [], []]
    end
    operators.each_with_index {|(name,param,precond_pos,precond_not,effect_add,effect_del),i|
      domain_str << "\n    :#{name} => #{!name.start_with?('invisible_')}#{',' unless operators.size.pred == i and methods.empty?}"
      define_operators << "\n  def #{name}#{"(#{(paramstr = param.join(', ')).tr!('?','_'); paramstr})" unless param.empty?}"
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
        elsif pre.start_with?('?')
          define_operators << "\n    return unless predicate(#{pre.tr('?','_')}).include?(#{terms_to_hyper(terms)})"
          meta = true
        elsif not predicates[pre] || state.include?(pre) then define_operators << "\n    return"
        else applicable(define_operators << "\n    return unless ", pre, terms, predicates)
        end
      }
      precond_not.each {|pre,*terms|
        if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
        elsif pre.start_with?('?')
          define_operators << "\n    return if predicate(#{pre.tr('?','_')}).include?(#{terms_to_hyper(terms)})"
          meta = true
        elsif predicates[pre] or state.include?(pre) then applicable(define_operators << "\n    return if ", pre, terms, predicates)
        end
      }
      define_operators << "\n    return if #{equality.join(' or ')}" unless equality.empty?
      unless effect_add.empty? and effect_del.empty?
        define_operators << "\n    @state = @state.dup"
        apply('delete', effect_del, define_operators, duplicated = {})
        apply('unshift', effect_add, define_operators, duplicated)
      end
      define_operators << "\n    true\n  end\n"
    }
    operators.pop if invisible_goal
    # Methods
    visit = false
    define_methods = ''
    domain_str << "\n    # Methods"
    methods.each_with_index {|(name,param,*decompositions),mi|
      variables = "(#{param.join(', ').tr!('?','_')})" unless param.empty?
      decompositions.map! {|dec|
        define_methods << "\n  def #{name}_#{dec[0]}#{variables}"
        equality = []
        define_methods_comparison = ''
        f = dec[1].dup
        precond_pos = dec[2].sort_by {|pre| (pre & param).size * -100 - (pre & f).size}
        precond_pos.reject! {|pre,*terms|
          if (terms & f).empty?
            if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
            elsif pre.start_with?('?')
              define_methods_comparison << "\n    return unless predicate(#{pre.tr('?','_')}).include?(#{terms_to_hyper(terms)})"
              meta = true
            elsif not predicates[pre] || state.include?(pre) then define_methods << "\n    return"
            else applicable(define_methods_comparison << "\n    return unless ", pre, terms, predicates)
            end
          end
        }
        precond_not = dec[3].reject {|pre,*terms|
          if terms.empty? and pre.start_with?('visited_') then predicates[pre] = nil
          elsif not pre.start_with?('?') || predicates[pre] || state.include?(pre) then true
          elsif (terms & f).empty?
            if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
            elsif pre.start_with?('?')
              define_methods_comparison << "\n    return if predicate(#{pre.tr('?','_')}).include?(#{terms_to_hyper(terms)})"
              meta = true
            elsif predicates[pre] or state.include?(pre) then applicable(define_methods_comparison << "\n    return if ", pre, terms, predicates)
            end
          end
        }
        define_methods << "\n    return if #{equality.join(' or ')}" unless equality.empty?
        define_methods << define_methods_comparison
        visit_param = nil
        dec[4].each {|s|
          if s.size > 1 and s[0].start_with?('invisible_visit_')
            if ((visit_param = s.drop(1)) & f).empty?
              define_methods << "\n    return if @visit.include?(#{terms_to_hyper(visit_param)})"
              visit_param = nil
            end
            visit = true
            break
          end
        } unless state_visit
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
                equality << "#{j = j.tr('?','_')}_ground != #{j}"
                "#{j}_ground"
              else
                new_grounds = true
                ground << f.delete(j)
                j.tr('?','_')
              end
            }
            if new_grounds
              if pre.start_with?('?')
                define_methods << "#{indentation}predicate(#{pre.tr('?','_')}).each {|#{terms2.join(', ')}|"
                meta = true
              elsif predicates[pre] then define_methods << "#{indentation}@state[#{pre.upcase}].each {|#{terms2.join(', ')}|"
              else
                define_methods << "#{indentation}return" unless state.include?(pre)
                define_methods << "#{indentation}#{pre == '=' ? 'EQUAL' : pre.upcase}.each {|#{terms2.join(', ')}|"
              end
              # close_method_str.prepend('}') and no indentation change for compact output
              close_method_str.prepend("#{indentation}}")
              indentation << '  '
            elsif pre == '=' then equality << "#{terms2[0]} != #{terms2[1]}"
            elsif pre.start_with?('?')
              define_methods_comparison << "#{indentation}next unless predicate(#{pre.tr('?','_')}).include?(#{terms_to_hyper(terms)})"
              meta = true
            elsif not predicates[pre] || state.include?(pre) then define_methods << "#{indentation}return"
            else applicable(define_methods_comparison << "#{indentation}next unless ", pre, terms, predicates)
            end
            precond_pos.reject! {|pre,*terms|
              if (terms & f).empty?
                if pre == '=' then equality << "#{term(terms[0])} != #{term(terms[1])}"
                elsif pre.start_with?('?')
                  define_methods_comparison << "#{indentation}next unless predicate(#{pre.tr('?','_')}).include?(#{terms_to_hyper(terms)})"
                  meta = true
                elsif not predicates[pre] || state.include?(pre) then define_methods << "#{indentation}return"
                else applicable(define_methods_comparison << "#{indentation}next unless ", pre, terms, predicates)
                end
              end
            }
            precond_not.reject! {|pre,*terms|
              if (terms & f).empty?
                if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
                elsif pre.start_with?('?')
                  define_methods_comparison << "#{indentation}next if predicate(#{pre.tr('?','_')}).include?(#{terms_to_hyper(terms)})"
                  meta = true
                elsif predicates[pre] or state.include?(pre) then applicable(define_methods_comparison << "#{indentation}next if ", pre, terms, predicates)
                end
              end
            }
            define_methods << "#{indentation}next if #{equality.join(' or ')}" unless equality.empty?
            define_methods << define_methods_comparison
            if visit_param and (visit_param & f).empty?
              define_methods << "#{indentation}next if @visit.include?(#{terms_to_hyper(visit_param)})"
              visit_param = nil
            end
          end
          equality.clear
          define_methods_comparison.clear
          precond_not.each {|pre,*terms|
            if pre == '=' then equality << "#{term(terms[0])} == #{term(terms[1])}"
            elsif pre.start_with?('?')
              define_methods_comparison << "#{indentation}next if predicate(#{pre.tr('?','_')}).include?(#{terms_to_hyper(terms)})"
              meta = true
            elsif predicates[pre] or state.include?(pre) then applicable(define_methods_comparison << "#{indentation}next if ", pre, terms, predicates)
            end
          }
          define_methods << "#{indentation}next if #{equality.join(' or ')}" unless equality.empty?
          define_methods << define_methods_comparison
        end
        define_methods << indentation << (dec[4].empty? ? 'yield []' : "yield [#{indentation}  [" << dec[4].map {|g| g.map {|i| term(i)}.join(', ')}.join("],#{indentation}  [") << "]#{indentation}]") << close_method_str
        "\n      :#{name}_#{dec[0]}"
      }
      domain_str << "\n    :#{name} => [" << decompositions.join(',') << (methods.size.pred == mi ? "\n    ]" : "\n    ],")
    }
    if meta
      define_methods << "\n  def predicate(pre)\n    case pre"
      predicates.each {|k,v|
        unless k.start_with?('?')
          case v
          when true then define_methods << "\n    when :#{k} then @state[#{k.upcase}]"
          when false then define_methods << "\n    when :#{k} then #{k.upcase}"
          end
        end
      }
      define_methods << "\n    end\n  end\n"
    end
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
    start_str = "\n#{domain_name.capitalize}.problem(\n  # Start\n  [\n"
    counter = -1
    predicates.each {|pre,type|
      if k = state[pre]
        unary = k[0].size == 1
        k = k.map {|obj| ':' << obj.join(', :')} unless k[0].empty?
      end
      if type
        problem_str << "#{pre.upcase} = #{counter += 1}\n"
        start_str << '    ['
        start_str << "\n      #{'[' unless unary}" << k.join(unary ? ",\n      " : "],\n      [") << "#{']' unless unary}\n    " if k
        start_str << "],\n"
      elsif k
        problem_str << "#{pre == '=' ? 'EQUAL' : pre.upcase} = ["
        problem_str << "\n  #{'[' unless unary}" << k.join(unary ? ",\n  " : "],\n  [") << (unary ? "\n]\n" : "]\n]\n")
      end
    }
    # Tasks
    ordered = tasks.shift
    problem_str << start_str << "  ],\n  # Tasks\n  [" << tasks.map {|g| "\n    [:#{g.join(', :')}]"}.join(',') << "\n  ],\n  # Debug\n  ARGV[0] == 'debug'#{",\n  # Ordered\n  false" if ordered == false}\n)"
    unless tasks.empty?
      tasks.unshift(ordered)
      tasks.pop if tasks[-1][0] == 'invisible_goal'
    end
    problem_str.gsub!(/\b-\b/,'_')
    domain_filename ? "# Generated by Hype\nrequire_relative '#{domain_filename}'\n\n#{problem_str}" : problem_str
  end
end