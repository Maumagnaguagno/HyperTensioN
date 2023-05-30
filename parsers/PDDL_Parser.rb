module PDDL_Parser
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
    (str = IO.read(filename)).gsub!(/;.*/,'')
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
          group.first == AND ? group.shift : group = [group]
          group.each {|pre|
            raise "Error with #{name} precondition" unless pre.instance_of?(Array)
            pre.first != NOT ? pos << pre : pre.size == 2 ? neg << pre = pre.last : raise("Unexpected not in #{name} precondition")
            pre.map! {|i| free_variables.find {|j| j == i} || i}
            @predicates[pre.first.freeze] ||= false
          }
        end
      when ':effect'
        raise "Error with #{name} effect" unless (group = op.shift).instance_of?(Array)
        unless group.empty?
          # Conjunction or atom
          group.first == AND ? group.shift : group = [group]
          group.each {|pre|
            raise "Error with #{name} effect" unless pre.instance_of?(Array)
            pre.first != NOT ? add << pre : pre.size == 2 ? del << pre = pre.last : raise("Unexpected not in #{name} effect")
            pre.map! {|i| free_variables.find {|j| j == i} || i}
            @predicates[pre.first.freeze] = true
          }
        end
      else raise "#{group} is not recognized in action"
      end
    end
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    if (tokens = scan_tokens(domain_filename)).instance_of?(Array) and tokens.shift == 'define'
      @domain_name = nil
      @operators = []
      @methods = []
      @predicates = {}
      @types = []
      @requirements = []
      while group = tokens.shift
        case group.first
        when ':action' then parse_action(group)
        when 'domain' then @domain_name = group.last
        when ':requirements' then (@requirements = group).shift
        when ':predicates'
        when ':types'
          # Type hierarchy
          group.shift
          while i = group.index(HYPHEN)
            type = group[i+1]
            j = -1
            @types << [group[j], type] while (j += 1) != i
            group.shift(i+2)
          end
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
    if (tokens = scan_tokens(problem_filename)).instance_of?(Array) and tokens.shift == 'define'
      @problem_name = nil
      @state = {}
      @objects = []
      @goal_pos = []
      @goal_not = []
      @tasks = []
      while group = tokens.shift
        case group.first
        when 'problem' then @problem_name = group.last
        when ':domain' then raise 'Different domain specified in problem file' if @domain_name != group.last
        when ':objects'
          # Move types to initial state
          group.shift
          while i = group.index(HYPHEN)
            @objects.concat(o = group.shift(i))
            group.shift
            types = [type = group.shift]
            while type = @types.assoc(type)
              raise 'Circular typing' if types.include?(type = type.last)
              types << type
            end
            types.each {|t| (@state[t] ||= []).concat(o.zip)}
          end
          raise 'Repeated object definition' if @objects.concat(group).uniq!
          @state[EQUAL] = @objects.zip(@objects) if @predicates.include?(EQUAL)
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
          end
        else raise "#{group.first} is not recognized in problem"
        end
      end
    else raise "File #{problem_filename} does not match problem pattern"
    end
  end
end