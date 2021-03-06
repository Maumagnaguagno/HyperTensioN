module JSHOP_Parser
  extend self

  attr_reader :domain_name, :problem_name, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

  NOT = 'not'

  #-----------------------------------------------
  # Scan tokens
  #-----------------------------------------------

  def scan_tokens(filename)
    (str = IO.read(filename)).gsub!(/;.*$/,'')
    str.downcase!
    stack = []
    list = []
    str.scan(/[()]|[^\s()]+/) {|t|
      case t
      when '('
        stack << list
        list = []
      when ')'
        stack.empty? ? raise('Missing open parentheses') : list = stack.pop << list
      when 'nil' then list << []
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
    op.shift
    raise 'Operator without name definition' unless (name = op.first.shift).instance_of?(String)
    name.sub!(/^!!/,'invisible_') or name.delete_prefix!('!')
    raise "#{name} have size #{op.size} instead of 4" if op.size != 4
    raise "#{name} redefined" if @operators.assoc(name)
    @operators << operator = [name, op.shift, pos = [], neg = []]
    # Preconditions
    raise "Error with #{name} precondition" unless (group = op.shift).instance_of?(Array)
    group.each {|pre|
      pre.first != NOT ? pos << pre : pre.size == 2 ? neg << pre = pre.last : raise("Error with #{name} negative precondition")
      @predicates[pre.first.freeze] ||= false
    }
    # Effects
    define_effects(name, operator[5] = op.shift)
    define_effects(name, operator[4] = op.shift)
  end

  #-----------------------------------------------
  # Parse method
  #-----------------------------------------------

  def parse_method(met)
    met.shift
    # Method may already have decompositions associated
    name = (group = met.first).shift
    @methods << method = [name, group] unless method = @methods.assoc(name)
    met.shift
    until met.empty?
      # Optional label, add index for the unlabeled decompositions
      if met.first.instance_of?(String)
        label = met.shift
        raise "#{name} redefined #{label} decomposition" if method.drop(2).assoc(label)
      else label = "case_#{method.size - 2}"
      end
      method << [label, free_variables = [], pos = [], neg = []]
      # Preconditions
      raise "Error with #{name} precondition" unless (group = met.shift).instance_of?(Array)
      group.each {|pre|
        pre.first != NOT ? pos << pre : pre.size == 2 ? neg << pre = pre.last : raise("Error with #{name} negative precondition")
        @predicates[pre.first.freeze] ||= false
        free_variables.concat(pre.select {|i| i.start_with?('?') and not method[1].include?(i)})
      }
      free_variables.uniq!
      # Subtasks
      raise "Error with #{name} subtasks" unless (group = met.shift).instance_of?(Array)
      method.last << group.each {|pre,| pre.sub!(/^!!/,'invisible_') or pre.delete_prefix!('!')}
    end
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    if (tokens = scan_tokens(domain_filename)).instance_of?(Array) and tokens.size == 3 and tokens.shift == 'defdomain'
      raise 'Found list instead of domain name' if tokens.first.instance_of?(Array)
      @domain_name = tokens.shift
      @operators = []
      @methods = []
      @predicates = {}
      tokens = tokens.shift
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
    if (tokens = scan_tokens(problem_filename)).instance_of?(Array) and tokens.size == 5 and tokens.shift == 'defproblem'
      @problem_name = tokens.shift
      raise 'Different domain specified in problem file' if @domain_name != tokens.shift
      @state = {}
      tokens.shift.each {|pre| (@state[pre.shift.freeze] ||= []) << pre}
      @tasks = tokens.shift
      # Tasks may be ordered or unordered
      @tasks.shift unless ordered = (@tasks.first != ':unordered')
      @tasks.each {|pre,| pre.sub!(/^!!/,'invisible_') or pre.delete_prefix!('!')}.unshift(ordered)
      @goal_pos = []
      @goal_not = []
    else raise "File #{problem_filename} does not match problem pattern"
    end
  end
end