module Hyper_Compiler
  extend self

  SPACER = '-' * 47

  #-----------------------------------------------
  # Predicates to Hyper
  #-----------------------------------------------

  def predicates_to_hyper(output, predicates, indentation = '      ', yielder = '')
    if predicates.empty?
      output << "\n#{indentation}#{yielder}[]"
    else
      output << "\n#{indentation}#{yielder}[\n#{indentation}  [" << predicates.map {|g| g.map {|i| i.start_with?('?') ? i.delete('?') : "'#{i}'"}.join(', ')}.join("],\n#{indentation}  [") << "]\n#{indentation}]"
    end
  end

  #-----------------------------------------------
  # Compile domain
  #-----------------------------------------------

  def compile_domain(domain_name, problem_name, operators, methods, predicates, state, tasks, goal_pos, goal_not, hypertension_filename = File.expand_path('../../Hypertension', __FILE__))
    domain_str = "module #{domain_name.capitalize}\n  include Hypertension\n  extend self\n\n  ##{SPACER}\n  # Domain\n  ##{SPACER}\n\n  @domain = {\n    # Operators"
    # Operators
    define_operators = ''
    operators.each_with_index {|op,i|
      domain_str << "\n    '#{op.first}' => #{!op.first.start_with?('invisible_')}#{',' if operators.size.pred != i or not methods.empty?}"
      define_operators << "\n  def #{op.first}#{"(#{op[1].join(', ').delete!('?')})" unless op[1].empty?}\n    "
      if op[4].empty? and op[5].empty?
        if op[2].empty? and op[3].empty?
          # Empty
          define_operators << "true\n  end\n"
        else
          # Sensing
          predicates_to_hyper(define_operators << "applicable?(\n      # Positive preconditions", op[2])
          predicates_to_hyper(define_operators << ",\n      # Negative preconditions", op[3])
          define_operators << "    )\n  end\n"
        end
      else
        if op[2].empty? and op[3].empty?
          # Effective
          define_operators << 'apply('
        else
          # Effective if preconditions hold
          predicates_to_hyper(define_operators << "apply_operator(\n      # Positive preconditions", op[2])
          predicates_to_hyper(define_operators << ",\n      # Negative preconditions", op[3])
          define_operators << ','
        end
        predicates_to_hyper(define_operators << "\n      # Add effects", op[4])
        predicates_to_hyper(define_operators << ",\n      # Del effects", op[5])
        define_operators << "\n    )\n  end\n"
      end
    }
    # Methods
    define_methods = ''
    domain_str << "\n    # Methods"
    methods.each_with_index {|met,mi|
      domain_str << "\n    '#{met.first}' => [\n"
      variables = met[1].empty? ? nil : "(#{met[1].join(', ').delete!('?')})"
      met.drop(2).each_with_index {|dec,i|
        domain_str << "      '#{met.first}_#{dec.first}'#{',' if met.size - 3 != i}\n"
        define_methods << "\n  def #{met.first}_#{dec.first}#{variables}"
        # No preconditions
        if dec[2].empty? and dec[3].empty?
          predicates_to_hyper(define_methods, dec[4], '    ', 'yield ')
        # Ground
        elsif dec[1].empty?
          predicates_to_hyper(define_methods << "\n    if applicable?(\n      # Positive preconditions", dec[2])
          predicates_to_hyper(define_methods << ",\n      # Negative preconditions", dec[3])
          predicates_to_hyper(define_methods << "\n    )", dec[4], '      ', 'yield ')
          define_methods << "\n    end"
        # Lifted
        else
          dec[1].each {|free| define_methods << "\n    #{free.delete('?')} = ''"}
          predicates_to_hyper(define_methods << "\n    generate(\n      # Positive preconditions", dec[2])
          predicates_to_hyper(define_methods << ",\n      # Negative preconditions", dec[3])
          dec[1].each {|free| define_methods << ', ' << free.delete('?')}
          predicates_to_hyper(define_methods << "\n    ) {", dec[4], '      ', 'yield ')
          define_methods << "\n    }"
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
    problem_str = "# Objects\n"
    # Extract information
    objects = []
    start_hash = {}
    predicates.each_key {|i| start_hash[i] = []}
    state.each {|pre,*terms|
      start_hash[pre] << terms if predicates.include?(pre)
      objects.concat(terms)
    }
    goal_pos.each {|pre,*terms| objects.concat(terms)}
    goal_not.each {|pre,*terms| objects.concat(terms)}
    ordered = tasks.shift
    tasks.each {|pre,*terms| objects.concat(terms)}
    # Objects
    objects.uniq!
    objects.each {|i| problem_str << "#{i} = '#{i}'\n"}
    problem_str << "\n#{domain_name.capitalize}.problem(\n  # Start\n  {\n"
    # Start
    start_hash.each_with_index {|(k,v),i|
      problem_str << "    '#{k}' => ["
      problem_str << "\n      [" << v.map! {|obj| obj.join(', ')}.join("],\n      [") << "]\n    " unless v.empty?
      problem_str << (start_hash.size.pred == i ? ']' : "],\n")
    }
    # Tasks
    problem_str << "\n  },\n  # Tasks\n  [" << tasks.map {|g| "\n    ['#{g.first}'#{', ' if g.size > 1}#{g.drop(1).join(', ')}]"}.join(',') << "\n  ],\n  # Debug\n  ARGV.first == 'debug'"
    tasks.unshift(ordered) unless tasks.empty?
    unless ordered
      problem_str << ",\n  # Positive goals\n  [" << goal_pos.map {|g| "\n    ['#{g.first}'#{', ' if g.size > 1}#{g.drop(1).join(', ')}]"}.join(',') <<
        "\n  ],\n  # Negative goals\n  [" << goal_not.map {|g| "\n    ['#{g.first}'#{', ' if g.size > 1}#{g.drop(1).join(', ')}]"}.join(',') << "\n  ]"
    end
    problem_str.gsub!(/\b-\b/,'_')
    domain_filename ? "# Generated by Hype\nrequire_relative '#{domain_filename}'\n\n#{problem_str}\n)" : "#{problem_str}\n)"
  end
end