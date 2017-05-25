module JSHOP_Parser
  extend self

  attr_reader :domain_name, :problem_name, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

  NOT = 'not'
  NIL = 'nil'

  #-----------------------------------------------
  # Define effects
  #-----------------------------------------------

  def define_effects(name, group)
    raise "Error with #{name} effects" unless group.instance_of?(Array)
    group.each {|pre| pre.first != NOT ? @predicates[pre.first.freeze] = true : raise('Unexpected not in effects')}
  end

  #-----------------------------------------------
  # Parse operator
  #-----------------------------------------------

  def parse_operator(op)
    op.shift
    raise 'Action without name definition' unless (name = op.first.shift).instance_of?(String)
    name.sub!(/^!!/,'invisible_') or name.sub!(/^!/,'')
    raise "Action #{name} redefined" if @operators.assoc(name)
    raise "Operator #{name} have size #{op.size} instead of 4" if op.size != 4
    @operators << [name, op.shift, pos = [], neg = []]
    # Preconditions
    if (group = op.shift) != NIL
      raise "Error with #{name} preconditions" unless group.instance_of?(Array)
      group.each {|pre|
        pre.first != NOT ? pos << pre : pre.size == 2 ? neg << pre = pre.last : raise("Error with #{name} negative preconditions")
        @predicates[pre.first.freeze] ||= false
      }
    end
    # Effects
    @operators.last[5] = (group = op.shift) != NIL ? define_effects(name, group) : []
    @operators.last[4] = (group = op.shift) != NIL ? define_effects(name, group) : []
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
        raise "Method #{name} redefined #{label} decomposition" if method.drop(2).assoc(label)
      else label = "case_#{method.size - 2}"
      end
      method << [label, free_variables = [], pos = [], neg = []]
      # Preconditions
      if (group = met.shift) != NIL
        raise "Error with #{name} preconditions" unless group.instance_of?(Array)
        group.each {|pre|
          pre.first != NOT ? pos << pre : pre.size == 2 ? neg << pre = pre.last : raise("Error with #{name} negative preconditions")
          @predicates[pre.first.freeze] ||= false
          free_variables.concat(pre.select {|i| i.start_with?('?') and not method[1].include?(i)})
        }
        free_variables.uniq!
      end
      # Subtasks
      if (group = met.shift) != NIL
        raise "Error with #{name} subtasks" unless group.instance_of?(Array)
        group.each {|pre| pre.first.sub!(/^!!/,'invisible_') or pre.first.sub!(/^!/,'')}
        method.last << group
      else method.last << []
      end
    end
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    if (tokens = PDDL_Parser.scan_tokens(domain_filename)).instance_of?(Array) and tokens.shift == 'defdomain'
      @operators = []
      @methods = []
      raise 'Found group instead of domain name' if tokens.first.instance_of?(Array)
      @domain_name = tokens.shift
      @predicates = {}
      raise 'More than one group to define domain content' if tokens.size != 1
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
    if (tokens = PDDL_Parser.scan_tokens(problem_filename)).instance_of?(Array) and tokens.size == 5 and tokens.shift == 'defproblem'
      @problem_name = tokens.shift
      raise 'Different domain specified in problem file' if @domain_name != tokens.shift
      @state = (group = tokens.shift) != NIL ? group : []
      if tokens.first != NIL
        @tasks = tokens.shift
        # Tasks may be ordered or unordered
        @tasks.shift unless ordered = (@tasks.first != ':unordered')
        @tasks.each {|pre| pre.first.sub!(/^!!/,'invisible_') or pre.first.sub!(/^!/,'')}.unshift(ordered)
      else @tasks = []
      end
      @goal_pos = []
      @goal_not = []
    else raise "File #{problem_filename} does not match problem pattern"
    end
  end
end