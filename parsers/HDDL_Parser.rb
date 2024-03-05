require 'tsort'

module HDDL_Parser
  extend self

  attr_reader :domain_name, :problem_name, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not, :objects, :requirements, :types

  AND = 'and'
  NOT = 'not'
  HYPHEN = '-'
  EQUAL = '='

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
    list[0]
  end

  #-----------------------------------------------
  # Parse ordering
  #-----------------------------------------------

  def parse_ordering(name, ordering, tasks)
    raise "Error with #{name} ordering" unless ordering.instance_of?(Array)
    ordering.shift
    graph = Hash.new {|h,k| h[k] = []}
    ordering.each {|_,before,after| graph[after] << before}
    graph.default = []
    total = TSort.tsort(lambda {|&b| graph.each_key(&b)}, lambda {|n,&b| graph[n].each(&b)})
    tasks.sort_by! {|label,| total.index(label)}
  end

  #-----------------------------------------------
  # Parse objects
  #-----------------------------------------------

  def parse_objects(group)
    # Move types to initial state
    group.shift
    while i = group.index(HYPHEN)
      @objects.concat(o = group.shift(i))
      group.shift
      types = [group.shift]
      ti = -1
      while type = types[ti += 1]
        @types.each {|sub,t| types << t if sub == type and not types.include?(t)}
      end
      types.each {|t| (@state[t] ||= []).concat(o.zip)}
    end
    @objects.concat(group)
  end

  #-----------------------------------------------
  # Parse action
  #-----------------------------------------------

  def parse_action(op)
    op.shift
    raise 'Action without name definition' unless (name = op.shift).instance_of?(String)
    raise "#{name} redefined" if @operators.assoc(name)
    @operators << [name, free_variables = [], pos = [], neg = [], add = [], del = []]
    while group = op.shift
      case group
      when ':parameters'
        raise "Error with #{name} parameters" unless (group = op.shift).instance_of?(Array)
        # "?ob1 ?ob2 - type" to [type, ?ob1] [type, ?ob2]
        while i = group.index(HYPHEN)
          @predicates[type = group[i+1].freeze] ||= false
          j = -1
          while (j += 1) != i
            free_variables << group[j]
            pos << [type, group[j]]
          end
          group.shift(i+2)
        end
        raise "#{name} with repeated parameters" if free_variables.concat(group).uniq!
      when ':precondition'
        raise "Error with #{name} precondition" unless (group = op.shift).instance_of?(Array)
        unless group.empty?
          # Conjunction or atom
          group[0] == AND ? group.shift : group = [group]
          group.each {|pre|
            raise "Error with #{name} precondition" unless pre.instance_of?(Array)
            if pre[0] == 'forall'
              pre[2][0] == AND ? pre[2].shift : pre[2] = [pre[2]]
              @foralls << [pos, neg, pre, false]
            else
              pre[0] != NOT ? pos << pre : pre.size == 2 ? neg << pre = pre[1] : raise("Unexpected not in #{name} precondition")
              @predicates[pre[0].freeze] ||= false
            end
          }
        end
      when ':effect'
        raise "Error with #{name} effect" unless (group = op.shift).instance_of?(Array)
        unless group.empty?
          # Conjunction or atom
          group[0] == AND ? group.shift : group = [group]
          group.each {|pre|
            raise "Error with #{name} effect" unless pre.instance_of?(Array)
            if pre[0] == 'forall'
              pre[2][0] == AND ? pre[2].shift : pre[2] = [pre[2]]
              @foralls << [add, del, pre, true]
            else
              pre[0] != NOT ? add << pre : pre.size == 2 ? del << pre = pre[1] : raise("Unexpected not in #{name} effect")
              @predicates[pre[0].freeze] = true
            end
          }
        end
      else raise "#{group} is not recognized in action"
      end
    end
  end

  #-----------------------------------------------
  # Parse method
  #-----------------------------------------------

  def parse_method(met)
    precondition = []
    while group = met.shift
      case group
      when ':method' then label = met.shift
      when ':parameters' then parameters = met.shift
      when ':task' then name = (variables = met.shift).shift
      when ':precondition' then precondition.concat(met.shift)
      when ':constraints'
        met[0].shift if not precondition.empty? and met[0][0] == AND
        precondition.concat(met.shift)
      when ':subtasks', ':tasks', ':ordered-subtasks', ':ordered-tasks' then subtasks = met.shift
      when ':ordering' then ordering = met.shift
      end
    end
    raise "Missing task #{name}" unless method = @methods.assoc(name)
    method << [label, free_variables = [], pos = [], neg = []]
    if parameters
      raise "Error with #{name} parameters" unless parameters.instance_of?(Array)
      # "?ob1 ?ob2 - type" to [type, ?ob1] [type, ?ob2]
      while i = parameters.index(HYPHEN)
        @predicates[type = parameters[i+1].freeze] ||= false
        j = -1
        while (j += 1) != i
          free_variables << fv = parameters[j]
          pos << [type, variables.find {|j| j == fv} || fv]
        end
        parameters.shift(i+2)
      end
      raise "#{name} with repeated parameters" if free_variables.concat(parameters).delete_if {|v| variables.include?(v)}.uniq!
    end
    # Preconditions
    if variables.size != (vu = variables.uniq).size
      precondition << AND if precondition.empty?
      ui = 0
      variables.zip(method[1]) {|v,m| v != vu[ui] ? precondition << [EQUAL, method[1][variables.index(v)], m] : ui += 1}
    end
    unless precondition.empty?
      # Conjunction or atom
      precondition[0] == AND ? precondition.shift : precondition = [precondition]
      precondition.each {|pre|
        if pre[0] == 'forall'
          pre[2][0] == AND ? pre[2].shift : pre[2] = [pre[2]]
          pre[2].each {|g| (g[0] != NOT ? g : g[1]).map! {|i| variables.find {|j| j == i} || free_variables.find {|j| j == i} || i}}
          @foralls << [pos, neg, pre, false]
        else
          pre[0] != NOT ? pos << pre : pre.size == 2 ? neg << pre = pre[1] : raise("Error with #{name} negative precondition")
          pre.map! {|i| variables.find {|j| j == i} || free_variables.find {|j| j == i} || i}
          @predicates[pre[0].freeze] ||= false
        end
      }
    end
    # Subtasks
    raise "Error with #{name} subtasks" unless (subtasks ||= []).instance_of?(Array)
    if subtasks.empty? then method[-1] << subtasks
    else
      # Conjunction or atom
      subtasks[0] == AND ? subtasks.shift : subtasks = [subtasks]
      # Ordering
      parse_ordering(name, ordering, subtasks) if ordering
      method[-1] << subtasks.map! {|t| (t[1].instance_of?(Array) ? t[1] : t).map! {|i| variables.find {|j| j == i} || free_variables.find {|j| j == i} || i}}
    end
    free_variables.each {|i| i.insert(1,'free_') if method[1].include?(i)}
    variables.zip(method[1]) {|i,j| i.replace(j)}
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    if (tokens = scan_tokens(domain_filename)).instance_of?(Array) and tokens.shift == 'define'
      @domain_name = nil
      @state = {}
      @objects = []
      @operators = []
      @methods = []
      @predicates = {}
      @types = []
      @requirements = []
      @foralls = []
      while group = tokens.shift
        case group[0]
        when ':action' then parse_action(group)
        when ':method' then parse_method(group)
        when ':task' then @methods << [group[1], group[2] == ':parameters' ? group[3].keep_if {|i| i.start_with?('?')} : []]
        when 'domain' then @domain_name = group[1]
        when ':requirements' then (@requirements = group).shift
        when ':predicates'
        when ':types'
          # Type hierarchy
          while i = group.index(HYPHEN)
            type = group[i+1]
            j = 0
            @types << [group[j], type] while (j += 1) != i
            group.shift(i+1)
          end
        when ':constants' then parse_objects(group)
        else raise "#{group[0]} is not recognized in domain"
        end
      end
    else raise "File #{domain_filename} does not match domain pattern"
    end
  end

  #-----------------------------------------------
  # Parse problem
  #-----------------------------------------------

  def parse_problem(problem_filename)
    if (tokens = scan_tokens(problem_filename)).instance_of?(Array) and tokens.shift == 'define'
      @problem_name = nil
      @goal_pos = []
      @goal_not = []
      @tasks = []
      while group = tokens.shift
        case group[0]
        when 'problem' then @problem_name = group[1]
        when ':domain' then raise 'Different domain specified in problem file' if @domain_name != group[1]
        when ':objects'
          raise 'Repeated object definition' if parse_objects(group).uniq!
          # Expand foralls
          @foralls.each {|pos,neg,(_,(fv,_,fvtype),g),mutable|
            fvtype = @state[fvtype] and g.each {|pre|
              if pre[0] != NOT
                fvtype.each {|obj,| pos << pre.map {|j| j == fv ? obj : j}}
              elsif pre.size == 2
                pre = pre[1]
                fvtype.each {|obj,| neg << pre.map {|j| j == fv ? obj : j}}
              else raise 'Unexpected not in forall'
              end
              @predicates[pre[0].freeze] ||= mutable
            }
          }
          @state[EQUAL] = @objects.zip(@objects) if @predicates.include?(EQUAL)
        when ':init'
          group.shift
          group.each {|pre| (@state[pre.shift.freeze] ||= []) << pre}
        when ':goal'
          if group = group[1]
            # Conjunction or atom
            group[0] == AND ? group.shift : group = [group]
            group.each {|pre|
              pre[0] != NOT ? @goal_pos << pre : pre.size == 2 ? @goal_not << pre = pre[1] : raise('Unexpected not in goal')
              @predicates[pre[0].freeze] ||= false
            }
            @methods.map! {|name,param,*decompositions| decompositions.sort_by! {|d| d[4].assoc(name) ? 0 : 1}.unshift(name, param)}
          end
        when ':htn'
          group.shift
          # TODO loop group elements to improve support
          if group[0] == ':parameters'
            group.shift
            group[0].empty? ? group.shift : parameters = group.shift
          end
          if (g = group.shift) == ':subtasks' or g == ':tasks' or g == ':ordered-subtasks' or g == ':ordered-tasks'
            @tasks = group.shift
            @tasks[0] == AND ? @tasks.shift : @tasks = [@tasks]
            # Ordering
            parse_ordering('problem', group.shift, @tasks) if group.shift == ':ordering'
            @tasks.map! {|t| t[1].instance_of?(Array) ? t[1] : t}
            # Add artificial task to support parameters
            if parameters
              @methods << [top_level = '__top', parameters, ['__top_method', free_variables = [], pos = [], [], @tasks]]
              @tasks = [true, [top_level]]
              # "?ob1 ?ob2 - type" to [type, ?ob1] [type, ?ob2]
              while i = parameters.index(HYPHEN)
                @predicates[type = parameters[i+1].freeze] ||= false
                j = -1
                while (j += 1) != i
                  free_variables << parameters[j]
                  pos << [type, parameters[j]]
                end
                parameters.shift(i+2)
              end
              raise 'Problem with repeated parameters' if free_variables.concat(parameters).uniq!
            elsif not @tasks.empty? then @tasks.unshift(true)
            end
          end
        else raise "#{group[0]} is not recognized in problem"
        end
      end
    else raise "File #{problem_filename} does not match problem pattern"
    end
  end
end