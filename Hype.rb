#!/usr/bin/env ruby
#-----------------------------------------------
# Hype
#-----------------------------------------------
# Mau Magnaguagno
#-----------------------------------------------
# Planning description converter
#-----------------------------------------------

# Require parsers, compilers and extensions
Dir.glob(File.expand_path('../{parsers,compilers,extensions}/*.rb', __FILE__)) {|file| require file}

module Hype
  extend self

  attr_reader :parser

  HELP = "  Usage:
    Hype domain problem {extensions} [output]\n
  Output:
    print - print parsed data(default)
    rb    - generate Ruby files to Hypertension
    pddl  - generate PDDL files
    jshop - generate JSHOP files
    dot   - generate DOT file
    md    - generate Markdown file
    run   - same as rb with execution
    debug - same as run with execution log
    nil   - avoid print parsed data\n
  Extensions:
    refinements - check and refine hierarchical structure
    grammar     - print hierarchical structure grammar"

  #-----------------------------------------------
  # Predicates to string
  #-----------------------------------------------

  def predicates_to_s(predicates, prefix)
    predicates.map {|i| "#{prefix}(#{i.join(' ')})"}.join
  end

  #-----------------------------------------------
  # Subtasks to string
  #-----------------------------------------------

  def subtasks_to_s(tasks, prefix, order = true)
    if tasks.empty?
      "#{prefix}empty"
    else
      operators = @parser.operators
      output = "#{prefix}#{'un' unless order}ordered"
      tasks.each {|t| output << prefix << (operators.assoc(t.first) ? 'operator' : 'method  ') << " (#{t.join(' ')})"}
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
      output << "    #{op.first}(#{op[1].join(' ')})\n"
      output << "      Precond positive:#{predicates_to_s(op[2], indent)}\n" unless op[2].empty?
      output << "      Precond negative:#{predicates_to_s(op[3], indent)}\n" unless op[3].empty?
      output << "      Effect positive:#{predicates_to_s(op[4], indent)}\n" unless op[4].empty?
      output << "      Effect negative:#{predicates_to_s(op[5], indent)}\n" unless op[5].empty?
      output << "\n"
    }
    output
  end

  #-----------------------------------------------
  # Methods to string
  #-----------------------------------------------

  def methods_to_s
    output = ''
    indent = "\n          "
    @parser.methods.each {|name,variables,*decompose|
      output << "    #{name}(#{variables.join(' ')})\n"
      decompose.each {|dec|
        output << "      Label: #{dec.first}\n"
        output << "        Free variables:\n          #{dec[1].join(indent)}\n" unless dec[1].empty?
        output << "        Precond positive:#{predicates_to_s(dec[2], indent)}\n" unless dec[2].empty?
        output << "        Precond negative:#{predicates_to_s(dec[3], indent)}\n" unless dec[3].empty?
        output << "        Subtasks:#{subtasks_to_s(dec[4], indent)}\n"
      }
      output << "\n"
    }
    output
  end

  #-----------------------------------------------
  # To string
  #-----------------------------------------------

  def to_s
"Domain #{@parser.domain_name}
  Operators:\n#{operators_to_s}
  Methods:\n#{methods_to_s}
Problem #{@parser.problem_name}
  State:#{predicates_to_s(@parser.state, "\n    ")}\n
  Goal:
    Tasks:#{subtasks_to_s(@parser.tasks.drop(1), "\n      ", @parser.tasks.first)}
    Positive:#{@parser.goal_pos.empty? ? "\n      empty" : predicates_to_s(@parser.goal_pos, "\n      ")}
    Negative:#{@parser.goal_not.empty? ? "\n      empty" : predicates_to_s(@parser.goal_not, "\n      ")}"
  end

  #-----------------------------------------------
  # Parse
  #-----------------------------------------------

  def parse(domain, problem)
    raise 'Incompatible extensions between domain and problem' if File.extname(domain) != File.extname(problem)
    @parser = case File.extname(domain)
    when '.rb' then Hyper_Parser
    when '.jshop' then JSHOP_Parser
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
    when 'refinements' then Refinements
    when 'grammar' then Grammar
    when 'complexity' then Complexity
    when 'dummy' then Dummy
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
    when 'jshop' then JSHOP_Compiler
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
    IO.write("#{domain}.#{type}", data) if data
    data = compiler.compile_problem(*args << File.basename(domain))
    IO.write("#{problem}.#{type}", data) if data
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  begin
    if ARGV.size < 2 or ARGV.first == '-h'
      puts Hype::HELP
    else
      domain = ARGV.shift
      problem = ARGV.shift
      type = ARGV.pop
      extensions = ARGV
      if not File.exist?(domain)
        puts "Domain file #{domain} not found"
      elsif not File.exist?(problem)
        puts "Problem file #{problem} not found"
      else
        t = Time.now.to_f
        Hype.parse(domain, problem)
        extensions.each {|e| Hype.extend(e)}
        if not type or type == 'print'
          puts Hype.to_s
        elsif type == 'run' or (type == 'debug' and ARGV[0] = '-d')
          Hype.compile(domain, problem, 'rb')
          require File.expand_path(problem)
        elsif type != 'nil'
          Hype.compile(domain, problem, type)
        end
        puts "Total time: #{Time.now.to_f - t}s"
      end
    end
  rescue
    puts $!, $@
  end
end