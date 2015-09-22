#!/usr/bin/env ruby
#-----------------------------------------------
# Hype
#-----------------------------------------------
# Mau Magnaguagno
#-----------------------------------------------
# Planning description converter
#-----------------------------------------------

module Hype
  extend self

  attr_reader :parser

  HELP = "  Usage:
    Hype domain problem [extensions*] [output]\n
  Output:
    print - print parsed data(default)
    rb    - generate Ruby files to Hypertension
    pddl  - generate PDDL files
    jshop - generate JSHOP files
    dot   - generate DOT file
    run   - same as rb with execution
    debug - same as run with execution log\n
  Extensions:
    fast  - optimize hierarchical structure"

  # Require parsers, compilers and extensions found
  FILEPATH = File.expand_path('..', __FILE__)
  Dir.glob("#{FILEPATH}/{parsers,compilers,extensions}/*.rb") {|file| require file}

  #-----------------------------------------------
  # Propositions to string
  #-----------------------------------------------

  def propositions_to_s(props, prefix)
    props.map {|i| "#{prefix}(#{i.join(' ')})"}.join
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
      output << "      Precond positive:#{propositions_to_s(op[2], indent)}\n" unless op[2].empty?
      output << "      Precond negative:#{propositions_to_s(op[3], indent)}\n" unless op[3].empty?
      output << "      Effect positive:#{propositions_to_s(op[4], indent)}\n" unless op[4].empty?
      output << "      Effect negative:#{propositions_to_s(op[5], indent)}\n" unless op[5].empty?
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
        output << "        Precond positive:#{propositions_to_s(dec[2], indent)}\n" unless dec[2].empty?
        output << "        Precond negative:#{propositions_to_s(dec[3], indent)}\n" unless dec[3].empty?
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
  State:#{propositions_to_s(@parser.state, "\n    ")}\n
  Goal:
    Tasks:#{subtasks_to_s(@parser.tasks.drop(1), "\n      ", @parser.tasks.first)}
    Positive:#{@parser.goal_pos.empty? ? "\n      empty" : propositions_to_s(@parser.goal_pos, "\n      ")}
    Negative:#{@parser.goal_not.empty? ? "\n      empty" : propositions_to_s(@parser.goal_not, "\n      ")}"
  end

  #-----------------------------------------------
  # Parse
  #-----------------------------------------------

  def parse(domain, problem)
    # Mix files may result in incomplete data
    raise 'Incompatible extensions between domain and problem' if File.extname(domain) != File.extname(problem)
    case File.extname(domain)
    when '.rb' then @parser = Hyper_Parser
    when '.jshop' then @parser = JSHOP_Parser
    when '.pddl' then @parser = PDDL_Parser
    else raise "Unknown file extension #{File.extname(domain)}"
    end
    @parser.parse_domain(domain)
    @parser.parse_problem(problem)
  end

  #-----------------------------------------------
  # Extend
  #-----------------------------------------------

  def extend(extension)
    raise 'No data to extend' unless @parser
    case extension
    when 'patterns' then extender = Patterns
    when 'fast' then extender = Fast
    else raise "Unknown extension #{extension}"
    end
    extender.apply(
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
    raise 'No data to compile' unless @parser
    case type
    when 'rb' then compiler = Hyper_Compiler
    when 'jshop' then compiler = JSHOP_Compiler
    when 'pddl' then compiler = PDDL_Compiler
    when 'dot' then compiler = Dot_Compiler
    when 'md' then compiler = Markdown_Compiler
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
    open("#{domain}.#{type}",'w') {|file| file << data} if data
    args << File.basename(domain)
    data = compiler.compile_problem(*args)
    open("#{problem}.#{type}",'w') {|file| file << data} if data
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  begin
    if ARGV.size >= 2
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
        if type and type != 'print'
          if type == 'run' or type == 'debug'
            Hype.compile(domain, problem, 'rb')
            ARGV[0] = '-d' if type == 'debug'
            require "#{Hype::FILEPATH}/#{problem}"
          else Hype.compile(domain, problem, type)
          end
        else puts Hype.to_s, "\nTime: #{Time.now.to_f - t}s"
        end
      end
    else puts Hype::HELP
    end
  rescue
    puts $!, $@
    STDIN.gets
  end
end