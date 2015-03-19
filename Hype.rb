# Patterns are closed for now
USE_PATTERNS = ENV['USER'] == 'Mau'

require '../Patterns' if USE_PATTERNS
require './compilers/Hyper_Compiler'
require './parsers/JSHOP_Parser'

module Hype
  extend self

  attr_reader :parser

  #-----------------------------------------------
  # Propositions to string
  #-----------------------------------------------

  def propositions_to_s(props, joiner)
    props.map {|i| "(#{i.join(' ')})"}.join(joiner)
  end

  #-----------------------------------------------
  # Operators to string
  #-----------------------------------------------

  def operators_to_s
    output = ''
    @parser.operators.each {|op|
      output << "    #{op.first}(#{op[1].join(' ')})\n"
      output << "      Precond positive:\n        #{propositions_to_s(op[2], "\n        ")}\n" unless op[2].empty?
      output << "      Precond negative:\n        #{propositions_to_s(op[3], "\n        ")}\n" unless op[3].empty?
      output << "      Effect positive:\n        #{propositions_to_s(op[4], "\n        ")}\n" unless op[4].empty?
      output << "      Effect negative:\n        #{propositions_to_s(op[5], "\n        ")}\n" unless op[5].empty?
      output << "\n"
    }
    output
  end

  #-----------------------------------------------
  # Methods to string
  #-----------------------------------------------

  def methods_to_s
    output = ''
    @parser.methods.each {|met|
      output << "    #{met.first}(#{met[1].join(' ')})\n"
      met.drop(2).each {|met_decompose|
        output << "      Label: #{met_decompose.first}\n"
        output << "        Free variables:\n          #{met_decompose[1].join("\n          ")}\n" unless met_decompose[1].empty?
        output << "        Precond positive:\n          #{propositions_to_s(met_decompose[2], "\n          ")}\n" unless met_decompose[2].empty?
        output << "        Precond negative:\n          #{propositions_to_s(met_decompose[3], "\n          ")}\n" unless met_decompose[3].empty?
        output << "        Subtasks:\n          #{met_decompose[4].empty? ? 'empty': propositions_to_s(met_decompose[4], "\n          ")}\n"
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
  Operators:
#{operators_to_s}
  Methods:
#{methods_to_s}
Problem #{@parser.problem_name} of #{@parser.problem_domain}
  State:
    #{propositions_to_s(@parser.state, "\n    ")}

  Tasks:
    #{propositions_to_s(@parser.tasks, "\n    ")}"
  end

  #-----------------------------------------------
  # Parse
  #-----------------------------------------------

  def parse(type, domain, problem)
    case type
    when 'jshop'
      @parser = JSHOP_Parser
    when 'pddl'
      @parser = PDDL_Parser
    else
      @parser = nil
      raise "Unknown type #{type} to parse"
    end
    @parser.parse_domain(domain)
    @parser.parse_problem(problem)
  end

  #-----------------------------------------------
  # Compile
  #-----------------------------------------------

  def compile(type, domain, problem, folder)
    raise "No data to compile" unless @parser
    case type
    when 'hyper'
      compiler = Hyper_Compiler
      ext = 'rb'
    when 'jshop'
      compiler = JSHOP_Compiler
      ext = 'jshop'
    else raise "Unknown type #{type} to save"
    end
    folder = "examples/#{folder}"
    Dir.mkdir(folder) unless Dir.exist?(folder)
    open("#{folder}/#{domain}.#{ext}", 'w') {|file|
      file << compiler.compile_domain(@parser.domain_name, @parser.operators, @parser.methods, @parser.predicates, @parser.state, @parser.tasks)
    }
    open("#{folder}/#{problem}.#{ext}", 'w') {|file|
      file << compiler.compile_problem(@parser.domain_name, @parser.operators, @parser.methods, @parser.predicates, @parser.state, @parser.tasks, domain)
    }
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------

if $0 == __FILE__
  begin
    if ARGV.size.between?(2,3)
      if not File.exist?(ARGV.first)
        puts "File not found: #{ARGV.first}!"
      elsif not File.exist?(ARGV[1])
        puts "File not found: #{ARGV[1]}!"
      else
        t = Time.now.to_f
        Hype.parse('jshop', ARGV.first, ARGV[1])
        if ARGV[2]
          Hype.compile('hyper', *ARGV)
        else
          puts Hype.to_s
        end
        Patterns.match(Hype.parser.operators, Hype.parser.predicates) if USE_PATTERNS
        p Time.now.to_f - t
      end
    else
      puts "Use #$0 domain_filename problem_filename [output_folder]"
    end
  rescue
    puts $!, $@
    STDIN.gets
  end
end