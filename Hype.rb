#!/usr/bin/env ruby
#-----------------------------------------------
# Hype
#-----------------------------------------------
# Mau Magnaguagno
#-----------------------------------------------
# Planning description converter
#-----------------------------------------------

# Require parsers, compilers and extensions
Dir.glob("#{__dir__}/{parsers,compilers,extensions}/*.rb") {|file| require file}

module Hype
  extend self

  HELP = "  Usage:
    Hype domain problem {extensions} [output]\n
  Output:
    print - print parsed data(default)
    rb    - generate Ruby files to HyperTensioN
    cpp   - generate C++ file with HyperTensioN
    pddl  - generate PDDL files
    hddl  - generate HDDL files
    jshop - generate JSHOP files
    dot   - generate DOT file
    md    - generate Markdown file
    run   - same as rb with execution
    debug - same as run with execution log
    nil   - avoid print parsed data\n
  Extensions:
    patterns    - add methods and tasks based on operator patterns
    dummy       - add brute-force methods to operators
    dejavu      - add invisible visit operators
    wise        - warn and fix description mistakes
    macro       - optimize operator sequences
    warp        - optimize unification
    typredicate - optimize typed predicates
    pullup      - optimize structure based on preconditions
    grammar     - print hierarchical structure grammar
    complexity  - print estimated complexity of planning description"

  #-----------------------------------------------
  # Predicates to string
  #-----------------------------------------------

  def predicates_to_s(predicates, indent)
    predicates.map {|i| "#{indent}(#{i.join(' ')})"}.join
  end

  #-----------------------------------------------
  # Subtasks to string
  #-----------------------------------------------

  def subtasks_to_s(tasks, indent, ordered = true)
    if tasks.empty?
      "#{indent}empty"
    else
      operators = @parser.operators
      output = "#{indent}#{'un' unless ordered}ordered"
      tasks.each {|t| output << indent << (operators.assoc(t[0]) ? 'operator' : 'method  ') << " (#{t.join(' ')})"}
      output
    end
  end

  #-----------------------------------------------
  # Operators to string
  #-----------------------------------------------

  def operators_to_s
    output = ''
    indent = "\n        "
    @parser.operators.each {|op|
      output << "\n    #{op[0]}(#{op[1].join(' ')})\n"
      output << "      Precond positive:#{predicates_to_s(op[2], indent)}\n" unless op[2].empty?
      output << "      Precond negative:#{predicates_to_s(op[3], indent)}\n" unless op[3].empty?
      output << "      Effect positive:#{predicates_to_s(op[4], indent)}\n" unless op[4].empty?
      output << "      Effect negative:#{predicates_to_s(op[5], indent)}\n" unless op[5].empty?
    }
    output
  end

  #-----------------------------------------------
  # Methods to string
  #-----------------------------------------------

  def methods_to_s
    output = ''
    indent = "\n          "
    @parser.methods.each {|name,param,*decompositions|
      output << "\n    #{name}(#{param.join(' ')})\n"
      decompositions.each {|dec|
        output << "      Label: #{dec[0]}\n"
        output << "        Free variables:\n          #{dec[1].join(indent)}\n" unless dec[1].empty?
        output << "        Precond positive:#{predicates_to_s(dec[2], indent)}\n" unless dec[2].empty?
        output << "        Precond negative:#{predicates_to_s(dec[3], indent)}\n" unless dec[3].empty?
        output << "        Subtasks:#{subtasks_to_s(dec[4], indent)}\n"
      }
    }
    output
  end

  #-----------------------------------------------
  # To string
  #-----------------------------------------------

  def to_s
"Domain #{@parser.domain_name}
  Operators:#{operators_to_s}\n
  Methods:#{methods_to_s}\n
Problem #{@parser.problem_name}
  State:#{predicates_to_s(@parser.state.flat_map {|k,v| [k].product(v)}, "\n    ")}\n
  Goal:
    Tasks:#{subtasks_to_s(@parser.tasks.drop(1), "\n      ", @parser.tasks[0])}
    Positive:#{@parser.goal_pos.empty? ? "\n      empty" : predicates_to_s(@parser.goal_pos, "\n      ")}
    Negative:#{@parser.goal_not.empty? ? "\n      empty" : predicates_to_s(@parser.goal_not, "\n      ")}"
  end

  #-----------------------------------------------
  # Parse
  #-----------------------------------------------

  def parse(domain, problem)
    raise 'Incompatible extensions between domain and problem' if File.extname(domain) != File.extname(problem)
    @parser = case File.extname(domain)
    when '.jshop' then JSHOP_Parser
    when '.hddl' then HDDL_Parser
    when '.pddl' then PDDL_Parser
    else raise "Unknown file extension #{File.extname(domain)}"
    end
    @parser.parse_domain(domain)
    @parser.parse_problem(problem)
  end

  #-----------------------------------------------
  # Extend
  #-----------------------------------------------

  def extend(extension)
    case extension
    when 'patterns' then Patterns
    when 'dummy' then Dummy
    when 'dejavu' then Dejavu
    when 'wise' then Wise
    when 'macro' then Macro
    when 'warp' then Warp
    when 'typredicate' then Typredicate
    when 'pullup' then Pullup
    when 'grammar' then Grammar
    when 'complexity' then Complexity
    else raise "Unknown extension #{extension}"
    end.apply(
      @parser.operators,
      @parser.methods,
      @parser.predicates,
      @parser.state,
      @parser.tasks,
      @parser.goal_pos,
      @parser.goal_not
    )
  end

  #-----------------------------------------------
  # Compile
  #-----------------------------------------------

  def compile(domain, problem, type)
    compiler = case type
    when 'rb' then Hyper_Compiler
    when 'cpp' then Cyber_Compiler
    when 'jshop' then JSHOP_Compiler
    when 'hddl' then HDDL_Compiler
    when 'pddl' then PDDL_Compiler
    when 'dot' then Dot_Compiler
    when 'md' then Markdown_Compiler
    else raise "Unknown type #{type}"
    end
    args = [
      @parser.domain_name,
      @parser.problem_name,
      @parser.operators,
      @parser.methods,
      @parser.predicates,
      @parser.state,
      @parser.tasks,
      @parser.goal_pos,
      @parser.goal_not
    ]
    data = compiler.compile_domain(*args)
    File.write("#{domain}.#{type}", data) if data
    data = compiler.compile_problem(*args << File.basename(domain))
    File.write("#{problem}.#{type}", data) if data
  end

  #-----------------------------------------------
  # Execute
  #-----------------------------------------------

  def execute
    args = [
      @parser.domain_name,
      @parser.problem_name,
      @parser.operators,
      @parser.methods,
      @parser.predicates,
      @parser.state,
      @parser.tasks,
      @parser.goal_pos,
      @parser.goal_not
    ]
    eval(Hyper_Compiler.compile_domain(*args))
    eval(Hyper_Compiler.compile_problem(*args))
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  begin
    if ARGV.size < 2 or ARGV[0] == '-h'
      puts Hype::HELP
    elsif not File.exist?(domain = ARGV.shift)
      abort("Domain not found: #{domain}")
    elsif not File.exist?(problem = ARGV.shift)
      abort("Problem not found: #{problem}")
    else
      type = ARGV.pop
      t = Time.now.to_f
      Hype.parse(domain, problem)
      ARGV.each {|e| Hype.extend(e)}
      if not type or type == 'print'
        puts Hype.to_s
      elsif type == 'run' or (ARGV[0] = type) == 'debug'
        Hype.execute
      elsif type != 'nil'
        Hype.compile(domain, problem, type)
      end
      puts "Total time: #{Time.now.to_f - t}s"
    end
  rescue
    puts $!, $@
    exit(2)
  end
end