module PDDL_Parser
  extend self

  attr_reader :domain_name, :problem_name, :problem_domain, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not, :objects

  AND = 'and'
  NOT = 'not'
  HYPHEN = '-'
  EQUAL = '='
  EQUAL_SUB = 'equal'

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
      else list << t
      end
    }
    raise 'Missing close parentheses' unless stack.empty?
    raise 'Malformed expression' if list.size != 1
    list.first
  end

  #-----------------------------------------------
  # Define preconditions
  #-----------------------------------------------

  def define_preconditions(name, pro, pos, neg)
    raise "Error with #{name} preconditions" unless pro.instance_of?(Array)
    if pro.first == NOT
      raise "Error with #{name} negative preconditions" if pro.size != 2
      neg << (pro = pro.last)
    else pos << pro
    end
    pro.replace(EQUAL_SUB) if (pro = pro.first) == EQUAL
    @predicates[pro.freeze] = false unless @predicates.include?(pro)
  end

  #-----------------------------------------------
  # Define effects
  #-----------------------------------------------

  def define_effects(name, pro, add, del)
    raise "Error with #{name} effects" unless pro.instance_of?(Array)
    if pro.first == NOT
      raise "Error with #{name} negative effects" if pro.size != 2
      del << (pro = pro.last)
    else add << pro
    end
    @predicates[pro.first.freeze] = true
  end

  #-----------------------------------------------
  # Define goals
  #-----------------------------------------------

  def define_goals(pro)
    if pro.first == NOT
      raise 'Error with goals' if pro.size != 2
      @goal_not << pro.last
    else @goal_pos << pro
    end
  end

  #-----------------------------------------------
  # Parse action
  #-----------------------------------------------

  def parse_action(op)
    op.shift
    raise 'Action without name definition' unless (name = op.shift).instance_of?(String)
    raise "Action #{name} redefined" if @operators.assoc(name)
    raise "Action #{name} have groups missing" if op.size != 6
    @operators << [name, free_variables = [], pos = [], neg = [], add = [], del = []]
    until op.empty?
      case group = op.shift
      when ':parameters'
        raise "Error with #{name} parameters" unless op.first.instance_of?(Array)
        group = op.shift
        raise "Error with #{name} typed parameters" if group.first == HYPHEN
        parameters = []
        until group.empty?
          parameters << o = group.shift
          free_variables << o
          # Make "?ob1 ?ob2 - type" become [type, ?ob1] [type, ?ob2]
          if group.first == HYPHEN
            group.shift
            type = group.shift
            pos << [type, parameters.shift] until parameters.empty?
            @predicates[type.freeze] = false unless @predicates.include?(type)
          end
        end
        raise "Action #{name} with repeated parameters" if free_variables.uniq!
      when ':precondition'
        raise "Error with #{name} precondition" unless (group = op.shift).instance_of?(Array)
        # Conjunction
        if group.first == AND
          group.shift
          group.each {|pro| define_preconditions(name, pro, pos, neg)}
        # Atom
        else define_preconditions(name, group, pos, neg)
        end
      when ':effect'
        raise "Error with #{name} effect" unless (group = op.shift).instance_of?(Array)
        # Conjunction
        if group.first == AND
          group.shift
          group.each {|pro| define_effects(name, pro, add, del)}
        # Atom
        else define_effects(name, group, add, del)
        end
      else puts "#{group.first} is not recognized in action"
      end
    end
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    (description = IO.read(domain_filename)).gsub!(/;.*$|\n/,'')
    description.downcase!
    if (tokens = scan_tokens(description)).instance_of?(Array) and tokens.shift == 'define'
      @operators = []
      @methods = []
      @predicates = {}
      @types = []
      until tokens.empty?
        case (group = tokens.shift).first
        when ':action' then parse_action(group)
        when 'domain'
          raise 'Domain group has size different of 2' if group.size != 2
          @domain_name = group.last
        when ':requirements'
          group.shift
          @requirements = group
        when ':predicates'
          # TODO take advantage of predicates definition
        when ':types'
          # Type hierarchy
          raise 'Typing not required' unless @requirements.include?(':typing')
          group.shift
          raise 'Error with types' if group.first == HYPHEN
          subtypes = []
          until group.empty?
            subtypes << group.shift
            if group.first == HYPHEN
              group.shift
              type = group.shift
              @types << [subtypes.shift, type] until subtypes.empty?
            end
          end
        else puts "#{group.first} is not recognized in domain"
        end
      end
      @domain_name ||= 'unknown'
      @requirements ||= []
    else raise "File #{domain_filename} does not match domain pattern"
    end
  end

  #-----------------------------------------------
  # Parse problem
  #-----------------------------------------------

  def parse_problem(problem_filename)
    (description = IO.read(problem_filename)).gsub!(/;.*$|\n/,'')
    description.downcase!
    if (tokens = scan_tokens(description)).instance_of?(Array) and tokens.shift == 'define'
      @state = []
      @objects = []
      @goal_pos = []
      @goal_not = []
      @tasks = []
      until tokens.empty?
        case (group = tokens.shift).first
        when 'problem' then @problem_name = group.last
        when ':domain' then @problem_domain = group.last
        when ':requirements'
          group.shift
          @requirements.concat(group).uniq!
        when ':objects'
          # Move types to initial state
          group.shift
          raise 'Error with typed objects' if group.first == HYPHEN
          # TODO support either
          objects = []
          until group.empty?
            objects << o = group.shift
            @objects << o
            if group.first == HYPHEN
              group.shift
              type = group.shift
              until objects.empty?
                @state << [type, o = objects.shift]
                # Convert type hierarchy to propositions of initial state
                types = [type]
                until types.empty?
                  subtype = types.shift
                  @types.each {|sub,t|
                    if sub == subtype
                      @state << [t, o]
                      types << t
                    end
                  }
                end
              end
            end
          end
          raise 'Repeated object definition' if @objects.uniq!
          @objects.each {|obj| @state << [EQUAL_SUB, obj, obj]} if @requirements.include?(':equality')
        when ':init'
          group.shift
          @state.concat(group)
        when ':goal'
          return unless group = group[1]
          # Conjunction
          if group.first == AND
            group.shift
            group.each {|pro| define_goals(pro)}
          # Atom
          else define_goals(group)
          end
        else puts "#{group.first} is not recognized in problem"
        end
      end
    else raise "File #{problem_filename} does not match problem pattern"
    end
    @problem_name ||= 'unknown'
    @problem_domain ||= 'unknown'
  end
end