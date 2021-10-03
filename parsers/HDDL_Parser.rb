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
      else list << t
      end
    }
    raise 'Missing close parentheses' unless stack.empty?
    raise 'Malformed expression' if list.size != 1
    list.first
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
    raise 'Unexpected hyphen in objects' if group.first == HYPHEN
    index = @objects.size
    until group.empty?
      @objects << group.shift
      if group.first == HYPHEN
        group.shift
        types = [group.shift]
        # Convert type hierarchy to initial state predicates
        ti = 0
        while type = types[ti]
          @types.each {|t| types << t.last if t.first == type and not types.include?(t.last)}
          ti += 1
        end
        while o = @objects[index]
          index += 1
          types.each {|t| (@state[t] ||= []) << [o]}
        end
      end
    end
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
        raise "Unexpected hyphen in #{name} parameters" if group.first == HYPHEN
        # "?ob1 ?ob2 - type" to [type, ?ob1] [type, ?ob2]
        index = 0
        while p = group.shift
          free_variables << p
          if group.first == HYPHEN
            group.shift
            @predicates[(type = group.shift).freeze] ||= false
            while fv = free_variables[index]
              pos << [type, fv]
              index += 1
            end
          end
        end
        raise "#{name} with repeated parameters" if free_variables.uniq!
      when ':precondition'
        raise "Error with #{name} precondition" unless (group = op.shift).instance_of?(Array)
        unless group.empty?
          # Conjunction or atom
          group.first == AND ? group.shift : group = [group]
          group.each {|pre|
            raise "Error with #{name} precondition" unless pre.instance_of?(Array)
            if pre.first == 'forall'
              pre[2].first == AND ? pre[2].shift : pre[2] = [pre[2]]
              @foralls << [pos, neg, pre, false]
            else
              pre.first != NOT ? pos << pre : pre.size == 2 ? neg << pre = pre.last : raise("Unexpected not in #{name} precondition")
              @predicates[pre.first.freeze] ||= false
            end
          }
        end
      when ':effect'
        raise "Error with #{name} effect" unless (group = op.shift).instance_of?(Array)
        unless group.empty?
          # Conjunction or atom
          group.first == AND ? group.shift : group = [group]
          group.each {|pre|
            raise "Error with #{name} effect" unless pre.instance_of?(Array)
            if pre.first == 'forall'
              pre[2].first == AND ? pre[2].shift : pre[2] = [pre[2]]
              @foralls << [add, del, pre, true]
            else
              pre.first != NOT ? add << pre : pre.size == 2 ? del << pre = pre.last : raise("Unexpected not in #{name} effect")
              @predicates[pre.first.freeze] = true
            end
          }
        end
      else raise "#{group.first} is not recognized in action"
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
        met.first.shift if not precondition.empty? and met.first.first == AND
        precondition.concat(met.shift)
      when ':subtasks', ':tasks', ':ordered-subtasks', ':ordered-tasks' then subtasks = met.shift
      when ':ordering' then ordering = met.shift
      end
    end
    raise "Missing task #{name}" unless method = @methods.assoc(name)
    method << [label, free_variables = [], pos = [], neg = []]
    raise "Error with #{name} parameters" unless parameters.instance_of?(Array)
    raise "Unexpected hyphen in #{name} parameters" if parameters.first == HYPHEN
    # "?ob1 ?ob2 - type" to [type, ?ob1] [type, ?ob2]
    index = 0
    while p = parameters.shift
      free_variables << p
      if parameters.first == HYPHEN
        parameters.shift
        @predicates[(type = parameters.shift).freeze] ||= false
        while fv = free_variables[index]
          pos << [type, variables.find {|j| j == fv} || fv]
          index += 1
        end
      end
    end
    free_variables.delete_if {|v| variables.include?(v)}
    raise "#{name} with repeated parameters" if free_variables.uniq!
    # Preconditions
    if variables != variables.uniq
      precondition << AND if precondition.empty?
      variables.each_with_index {|v,i|
        variables.each_with_index {|v2,j|
          if i < j and v == v2 and not precondition.include?(eq = [EQUAL, method[1][i], method[1][j]])
            precondition << eq
          end
        }
      }
    end
    unless precondition.empty?
      # Conjunction or atom
      precondition.first == AND ? precondition.shift : precondition = [precondition]
      precondition.each {|pre|
        if pre.first == 'forall'
          pre[2].first == AND ? pre[2].shift : pre[2] = [pre[2]]
          pre[2].each {|g| (g.first != NOT ? g : g[1]).map! {|i| variables.find {|j| j == i} || free_variables.find {|j| j == i} || i}}
          @foralls << [pos, neg, pre, false]
        else
          pre.first != NOT ? pos << pre : pre.size == 2 ? neg << pre = pre.last : raise("Error with #{name} negative precondition")
          pre.map! {|i| variables.find {|j| j == i} || free_variables.find {|j| j == i} || i}
          @predicates[pre.first.freeze] ||= false
        end
      }
    end
    # Subtasks
    raise "Error with #{name} subtasks" unless subtasks.instance_of?(Array)
    if subtasks.empty? then method.last << subtasks
    else
      # Conjunction or atom
      subtasks.first == AND ? subtasks.shift : subtasks = [subtasks]
      # Ordering
      parse_ordering(name, ordering, subtasks) if ordering
      method.last << subtasks.map! {|t| (t[1].instance_of?(Array) ? t[1] : t).map! {|i| variables.find {|j| j == i} || free_variables.find {|j| j == i} || i}}
    end
    free_variables.each {|i| i.sub!('?','?free_') if method[1].include?(i)}
    variables.zip(method[1]) {|i,j| i.replace(j)}
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    if (tokens = scan_tokens(domain_filename)).instance_of?(Array) and tokens.shift == 'define'
      @state = {}
      @objects = []
      @operators = []
      @methods = []
      @predicates = {}
      @types = []
      @requirements = []
      @foralls = []
      while group = tokens.shift
        case group.first
        when ':action' then parse_action(group)
        when ':method' then parse_method(group)
        when ':task'
          group.shift
          name = group.shift
          parameters = group.shift.keep_if {|i| i.start_with?('?')} if group.shift == ':parameters'
          @methods << [name, parameters || []]
        when 'domain' then @domain_name = group.last
        when ':requirements' then (@requirements = group).shift
        when ':predicates'
        when ':types'
          # Type hierarchy
          raise 'Expected :typing' unless @requirements.include?(':typing')
          group.shift
          raise 'Unexpected hyphen in types' if group.first == HYPHEN
          subtypes = []
          until group.empty?
            subtypes << group.shift
            if group.first == HYPHEN
              group.shift
              type = group.shift
              @types << [subtypes.shift, type] until subtypes.empty?
            end
          end
        when ':constants' then parse_objects(group)
        else raise "#{group.first} is not recognized in domain"
        end
      end
      @domain_name ||= 'unknown'
    else raise "File #{domain_filename} does not match domain pattern"
    end
  end

  #-----------------------------------------------
  # Parse problem
  #-----------------------------------------------

  def parse_problem(problem_filename)
    if (tokens = scan_tokens(problem_filename)).instance_of?(Array) and tokens.shift == 'define'
      @goal_pos = []
      @goal_not = []
      @tasks = []
      while group = tokens.shift
        case group.first
        when 'problem' then @problem_name = group.last
        when ':domain' then raise 'Different domain specified in problem file' if @domain_name != group.last
        when ':objects'
          parse_objects(group)
          # Expand foralls
          @foralls.each {|pos,neg,(_,(fv,_,fvtype),g),mutable|
            @state[fvtype]&.each {|obj,|
              g.each {|pre|
                pre.first != NOT ? pos << pre.map {|j| j == fv ? obj : j} : pre.size == 2 ? neg << pre = pre.last.map {|j| j == fv ? obj : j} : raise('Unexpected not in forall')
                @predicates[pre.first.freeze] ||= mutable
              }
            }
          }
          raise 'Repeated object definition' if @objects.uniq!
          @state[EQUAL] = @objects.map {|obj| [obj, obj]} if @predicates.include?(EQUAL)
        when ':init'
          group.shift
          group.each {|pre| (@state[pre.shift.freeze] ||= []) << pre}
        when ':goal'
          if group = group[1]
            # Conjunction or atom
            group.first == AND ? group.shift : group = [group]
            group.each {|pre|
              pre.first != NOT ? @goal_pos << pre : pre.size == 2 ? @goal_not << pre = pre.last : raise('Unexpected not in goal')
              @predicates[pre.first.freeze] ||= false
            }
            # Ordered tasks with goal require an invisible task
            if @tasks.first
              @tasks << [invisible_goal = 'invisible_goal']
              @operators << [invisible_goal, [], @goal_pos, @goal_not, [], []]
            end
          end
          @methods.map! {|name,param,*decompositions| decompositions.sort_by! {|d| d[4].assoc(name) ? 0 : 1}.unshift(name, param)}
          #@state.each {|pre,k| k.sort_by! {|terms| @goal_pos.include?([pre,*terms]) ? 0 : @goal_not.include?([pre,*terms]) ? 2 : 1}}
        when ':htn'
          group.shift
          # TODO loop group elements to improve support
          if group.first == ':parameters'
            group.shift
            group.first.empty? ? group.shift : parameters = group.shift
          end
          if (g = group.shift) == ':subtasks' or g == ':tasks' or g == ':ordered-subtasks' or g == ':ordered-tasks'
            @tasks = group.shift
            @tasks.first == AND ? @tasks.shift : @tasks = [@tasks]
            # Ordering
            parse_ordering('problem', group.shift, @tasks) if group.shift == ':ordering'
            @tasks.map! {|t| t[1].instance_of?(Array) ? t[1] : t}
            # Add artificial task to support parameters
            if parameters
              free_variables = []
              pos = []
              index = 0
              while p = parameters.shift
                free_variables << p
                if parameters.first == HYPHEN
                  parameters.shift
                  @predicates[(type = parameters.shift).freeze] ||= false
                  while fv = free_variables[index]
                    pos << [type, fv]
                    index += 1
                  end
                end
              end
              @methods << [top_level = '__top', [], ['__top_method', free_variables, pos, [], @tasks]]
              @tasks = [true, [top_level]]
            else @tasks.unshift(true)
            end
          end
        else raise "#{group.first} is not recognized in problem"
        end
      end
    else raise "File #{problem_filename} does not match problem pattern"
    end
    @problem_name ||= 'unknown'
  end
end