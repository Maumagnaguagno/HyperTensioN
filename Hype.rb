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

  FILEPATH = File.expand_path('..', __FILE__)

  HELP = "Hype
  Use #$0 domain problem [options]

  Options:
    [print] to print data parsed(default)
    [rb] to generate Ruby files to Hypertension
    [pddl] to generate PDDL files
    [jshop] to generate JSHOP files
    [dot] to generate DOT file
    [run] to generate Ruby files and execute them
    [debug] the same as run with search log"

  # Parsers
  require "#{FILEPATH}/parsers/JSHOP_Parser"
  require "#{FILEPATH}/parsers/PDDL_Parser"
  # Compilers
  require "#{FILEPATH}/compilers/Dot_Compiler"
  require "#{FILEPATH}/compilers/Hyper_Compiler"
  require "#{FILEPATH}/compilers/JSHOP_Compiler"
  require "#{FILEPATH}/compilers/PDDL_Compiler"
  # Extensions
  require "#{FILEPATH}/Patterns" if File.exist?("#{FILEPATH}/Patterns.rb")

  #-----------------------------------------------
  # Scan tokens
  #-----------------------------------------------

  def scan_tokens(str)
    stack = []
    list = []
    str.scan(/[()]|[!?:]*[\w-]+/) {|t|
      case t
      when '('
        stack << list
        list = []
      when ')'
        raise 'Missing open parentheses' if stack.empty?
        list = stack.pop << list
      else t
        list << t
      end
    }
    raise 'Missing close parentheses' unless stack.empty?
    raise 'Malformed expression' if list.size != 1
    list.first
  end

  #-----------------------------------------------
  # Propositions to string
  #-----------------------------------------------

  def propositions_to_s(props, prefix)
    props.map {|i| "#{prefix}(#{i.join(' ')})"}.join
  end

  #-----------------------------------------------
  # Subtasks to string
  #-----------------------------------------------

  def subtasks_to_s(tasks, operators, prefix, order = true)
    if tasks.empty?
      "#{prefix}empty"
    else
      "#{prefix}#{'un' unless order}ordered" << tasks.map {|t| "#{prefix}#{operators.any? {|op| op.first == t.first} ? 'operator' : 'method  '} (#{t.join(' ')})"}.join
    end
  end

  #-----------------------------------------------
  # Operators to string
  #-----------------------------------------------

  def operators_to_s
    output = ''
    @parser.operators.each {|op|
      output << "    #{op.first}(#{op[1].join(' ')})\n"
      output << "      Precond positive:#{propositions_to_s(op[2], "\n        ")}\n" unless op[2].empty?
      output << "      Precond negative:#{propositions_to_s(op[3], "\n        ")}\n" unless op[3].empty?
      output << "      Effect positive:#{propositions_to_s(op[4], "\n        ")}\n" unless op[4].empty?
      output << "      Effect negative:#{propositions_to_s(op[5], "\n        ")}\n" unless op[5].empty?
      output << "\n"
    }
    output
  end

  #-----------------------------------------------
  # Methods to string
  #-----------------------------------------------

  def methods_to_s
    output = ''
    @parser.methods.each {|name,variables,*decompose|
      output << "    #{name}(#{variables.join(' ')})\n"
      decompose.each {|dec|
        output << "      Label: #{dec.first}\n"
        output << "        Free variables:\n          #{dec[1].join("\n          ")}\n" unless dec[1].empty?
        output << "        Precond positive:#{propositions_to_s(dec[2], "\n          ")}\n" unless dec[2].empty?
        output << "        Precond negative:#{propositions_to_s(dec[3], "\n          ")}\n" unless dec[3].empty?
        output << "        Subtasks:#{subtasks_to_s(dec[4], @parser.operators, "\n          ")}\n"
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
Problem #{@parser.problem_name} of #{@parser.problem_domain}
  State:#{propositions_to_s(@parser.state, "\n    ")}

  Goal:
    Tasks:#{subtasks_to_s(@parser.tasks.drop(1), @parser.operators, "\n      ", @parser.tasks.first)}
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
    when '.jshop' then @parser = JSHOP_Parser
    when '.pddl' then @parser = PDDL_Parser
    else raise "Unknown extension #{File.extname(domain)} to parse"
    end
    @parser.parse_domain(domain)
    @parser.parse_problem(problem)
  end

  #-----------------------------------------------
  # Compile
  #-----------------------------------------------

  def compile(domain, problem, type)
    raise "No data to compile" unless @parser
    case type
    when 'rb' then compiler = Hyper_Compiler
    when 'jshop' then compiler = JSHOP_Compiler
    when 'pddl' then compiler = PDDL_Compiler
    when 'dot' then compiler = Dot_Compiler
    else raise "Unknown type #{type} to save"
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
    if ARGV.size.between?(2,4)
      domain, problem, type, extension = ARGV
      if not File.exist?(domain)
        puts "Domain file #{domain} not found"
      elsif not File.exist?(problem)
        puts "Problem file #{problem} not found"
      else
        t = Time.now.to_f
        Hype.parse(domain, problem)
        if extension == 'patterns'
          if defined?(Patterns)
            Patterns.match(
              Hype.parser.operators,
              Hype.parser.methods,
              Hype.parser.predicates,
              Hype.parser.tasks,
              Hype.parser.goal_pos,
              Hype.parser.goal_not
            )
          else raise 'Patterns not supported'
          end
        end
        if type and type != 'print'
          if type == 'run' or type == 'debug'
            Hype.compile(domain, problem, 'rb')
            ARGV[0] = '-d' if type == 'debug'
            require "#{Hype::FILEPATH}/#{problem}"
          else Hype.compile(domain, problem, type)
          end
        else puts Hype.to_s, Time.now.to_f - t
        end
      end
    else puts Hype::HELP
    end
  rescue
    puts $!, $@
    STDIN.gets
  end
end