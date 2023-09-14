module JSHOP_Parser
  extend self

  attr_reader :domain_name, :problem_name, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

  NOT = 'not'

  #-----------------------------------------------
  # Scan tokens
  #-----------------------------------------------

  def scan_tokens(filename)
    (str = File.read(filename)).gsub!(/;.*/,'')
    str.downcase!
    # return str.to_sexpr # require Ichor
    stack = []
    list = []
    str.scan(/[()]|[^\s()]+/) {|t|
      case t
      when '('
        stack << list
        list = []
      when ')'
        stack.empty? ? raise('Missing open parentheses') : list = stack.pop << list
      else list << t
      end
    }
    raise 'Missing close parentheses' unless stack.empty?
    raise 'Malformed expression' if list.size != 1
    list.first
  end

  #-----------------------------------------------
  # Define effects
  #-----------------------------------------------

  def define_effects(name, group)
    raise "Error with #{name} effect" unless group.instance_of?(Array)
    group.each {|pre,| pre != NOT ? @predicates[pre.freeze] = true : raise("Unexpected not in #{name} effect")}
  end

  #-----------------------------------------------
  # Parse operator
  #-----------------------------------------------

  def parse_operator(op)
    raise 'Operator without name definition' unless (name = op[1].shift).instance_of?(String)
    name.sub!(/^!!/,'invisible_') or name.delete_prefix!('!')
    raise "#{name} have size #{op.size} instead of 4" if op.size != 5
    raise "#{name} redefined" if @operators.assoc(name)
    @operators << [name, op[1], pos = [], neg = [], op[4], op[3]]
    # Preconditions
    raise "Error with #{name} precondition" unless (group = op[2]).instance_of?(Array)
    group.each {|pre|
      pre.first != NOT ? pos << pre : pre.size == 2 ? neg << pre = pre.last : raise("Error with #{name} negative precondition")
      @predicates[pre.first.freeze] ||= false
    }
    # Effects
    define_effects(name, op[3])
    define_effects(name, op[4])
  end

  #-----------------------------------------------
  # Parse method
  #-----------------------------------------------

  def parse_method(met)
    met.shift
    # Method may already have decompositions associated
    if method = @methods.assoc(name = (group = met.shift).shift)
      raise "Expected same parameters for method #{name}" if method[1] != group
    else @methods << method = [name, group]
    end
    until met.empty?
      # Optional label, add index for the unlabeled decompositions
      if met.first.instance_of?(String)
        label = met.shift
        raise "#{name} redefined #{label} decomposition" if method.drop(2).assoc(label)
      else label = "case_#{method.size - 2}"
      end
      # Preconditions
      raise "Error with #{name} precondition" unless (group = met.shift).instance_of?(Array)
      method << [label, free_variables = [], pos = [], neg = [], subtasks = met.shift]
      group.each {|pre|
        pre.first != NOT ? pos << pre : pre.size == 2 ? neg << pre = pre.last : raise("Error with #{name} negative precondition")
        @predicates[pre.first.freeze] ||= false
        pre.each {|i| free_variables << i if i.start_with?('?') and not method[1].include?(i)}
      }
      free_variables.uniq!
      # Subtasks
      raise "Error with #{name} subtasks" unless subtasks.instance_of?(Array)
      subtasks.each {|pre,| pre.sub!(/^!!/,'invisible_') or pre.delete_prefix!('!')}
    end
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    if (tokens = scan_tokens(domain_filename)).instance_of?(Array) and tokens.size == 3 and tokens[0] == 'defdomain'
      @domain_name = tokens[1]
      @operators = []
      @methods = []
      @predicates = {}
      tokens = tokens[2]
      while group = tokens.shift
        case group.first
        when ':operator' then parse_operator(group)
        when ':method' then parse_method(group)
        else raise "#{group.first} is not recognized in domain"
        end
      end
    else raise "File #{domain_filename} does not match domain pattern"
    end
  end

  #-----------------------------------------------
  # Parse problem
  #-----------------------------------------------

  def parse_problem(problem_filename)
    if (tokens = scan_tokens(problem_filename)).instance_of?(Array) and tokens.size == 5 and tokens[0] == 'defproblem'
      @problem_name = tokens[1]
      raise 'Different domain specified in problem file' if @domain_name != tokens[2]
      @state = {}
      tokens[3].each {|pre| (@state[pre.shift.freeze] ||= []) << pre}
      @tasks = tokens[4]
      # Tasks may be ordered or unordered
      @tasks.shift unless ordered = (@tasks.first != ':unordered')
      @tasks.each {|pre,| pre.sub!(/^!!/,'invisible_') or pre.delete_prefix!('!')}.unshift(ordered) unless @tasks.empty?
      @goal_pos = []
      @goal_not = []
    else raise "File #{problem_filename} does not match problem pattern"
    end
  end
end