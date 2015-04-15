# Patterns are closed for now
PATTERNS = File.exist?('../Patterns.rb')
require '../Patterns' if PATTERNS

require './parsers/JSHOP_Parser'
require './parsers/PDDL_Parser'

require './compilers/Dot_Compiler'
require './compilers/Hyper_Compiler'
require './compilers/JSHOP_Compiler'
require './compilers/PDDL_Compiler'

module Hype
  extend self

  attr_reader :parser

  #-----------------------------------------------
  # Scan tokens
  #-----------------------------------------------

  def scan_tokens(str)
    tokenize(str.scan(/[()]|[!?:]*[\w-]+/))
  end

  #-----------------------------------------------
  # Tokenize
  #-----------------------------------------------

  def tokenize(tokens)
    raise 'No more tokens found' if tokens.empty?
    t = tokens.shift
    if t == '('
      list = []
      list << tokenize(tokens) until tokens.first == ')'
      tokens.shift
      list
    else t
    end
  end

  #-----------------------------------------------
  # Propositions to string
  #-----------------------------------------------

  def propositions_to_s(props, joiner)
    # TODO differentiate between free-variables and constants in terms
    props.map {|i| "(#{i.join(' ')})"}.join(joiner)
  end

  #-----------------------------------------------
  # Subtasks to string
  #-----------------------------------------------

  def subtasks_to_s(tasks, operators, joiner)
    return 'empty' if tasks.empty?
    tasks.map {|t| "#{operators.any? {|op| op.first == t.first} ? 'operator' : 'method  '} (#{t.first}#{t.drop(1).map {|i| " #{i}"}.join})"}.join(joiner)
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
        output << "        Subtasks:\n          #{subtasks_to_s(met_decompose[4], @parser.operators, "\n          ")}\n"
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

  Goal:
    Tasks:
      #{subtasks_to_s(@parser.tasks, @parser.operators, "\n      ")}
    Positive:
      #{@parser.goal_pos.empty? ? 'empty' : propositions_to_s(@parser.goal_pos, "\n      ")}
    Negative:
      #{@parser.goal_not.empty? ? 'empty' : propositions_to_s(@parser.goal_not, "\n      ")}"
  end

  #-----------------------------------------------
  # Parse
  #-----------------------------------------------

  def parse(domain, problem)
    # TODO remove this limitation in the future (mix files)
    raise 'Incompatible extensions between domain and problem' if File.extname(domain) != File.extname(problem)
    case File.extname(domain)
    when '.jshop' then @parser = JSHOP_Parser
    when '.pddl' then @parser = PDDL_Parser
    else raise "Unknown type #{File.extname(domain)} to parse"
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
    if ARGV.size.between?(2,3)
      domain = ARGV[0]
      problem = ARGV[1]
      if not File.exist?(domain)
        puts "File not found: #{domain}!"
      elsif not File.exist?(problem)
        puts "File not found: #{problem}!"
      else
        t = Time.now.to_f
        Hype.parse(domain, problem)
        if PATTERNS
          Patterns.match(
            Hype.parser.operators,
            Hype.parser.methods,
            Hype.parser.predicates,
            Hype.parser.tasks,
            Hype.parser.goal_pos,
            Hype.parser.goal_not
          )
        end
        if ARGV[2]
          Hype.compile(domain, problem, ARGV[2])
        else puts Hype.to_s
        end
        puts Time.now.to_f - t
      end
    else puts "Use #$0 domain_filename problem_filename output_type"
    end
  rescue
    puts $!, $@
    STDIN.gets
  end
end