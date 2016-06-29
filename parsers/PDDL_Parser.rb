module PDDL_Parser
  extend self

  attr_reader :domain_name, :problem_name, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not, :objects, :requirements

  AND = 'and'
  NOT = 'not'
  HYPHEN = '-'
  EQUAL = '='
  EQUAL_SUB = 'equal'

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
  # Parse action
  #-----------------------------------------------

  def parse_action(op)
    op.shift
    raise 'Action without name definition' unless (name = op.shift).instance_of?(String)
    raise "Action #{name} redefined" if @operators.assoc(name)
    @operators << [name, free_variables = [], pos = [], neg = [], add = [], del = []]
    until op.empty?
      case group = op.shift
      when ':parameters'
        raise "Error with #{name} parameters" unless op.first.instance_of?(Array)
        raise "Unexpected hyphen in #{name} parameters" if (group = op.shift).first == HYPHEN
        # "?ob1 ?ob2 - type" to [type, ?ob1] [type, ?ob2]
        index = 0
        until group.empty?
          free_variables << group.shift
          if group.first == HYPHEN
            group.shift
            type = group.shift
            until index == free_variables.size
              pos << [type, free_variables[index]]
              index += 1
            end
            @predicates[type.freeze] ||= false
          end
        end
        raise "Action #{name} with repeated parameters" if free_variables.uniq!
      when ':precondition'
        raise "Error with #{name} precondition" unless (group = op.shift).instance_of?(Array)
        unless group.empty?
          # Conjunction or atom
          group.first == AND ? group.shift : group = [group]
          group.each {|pre|
            raise "Error with #{name} preconditions" unless pre.instance_of?(Array)
            pre.first != NOT ? pos << pre : pre.size == 2 ? neg << (pre = pre.last) : raise("Error with #{name} negative preconditions")
            pre.replace(EQUAL_SUB) if (pre = pre.first) == EQUAL
            @predicates[pre.freeze] ||= false
          }
        end
      when ':effect'
        raise "Error with #{name} effect" unless (group = op.shift).instance_of?(Array)
        unless group.empty?
          # Conjunction or atom
          group.first == AND ? group.shift : group = [group]
          group.each {|pre|
            raise "Error with #{name} effects" unless pre.instance_of?(Array)
            pre.first != NOT ? add << pre : pre.size == 2 ? del << (pre = pre.last) : raise("Error with #{name} negative effects")
            @predicates[pre.first.freeze] = true
          }
        end
      else puts "#{group.first} is not recognized in action"
      end
    end
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    if (tokens = scan_tokens(domain_filename)).instance_of?(Array) and tokens.shift == 'define'
      @operators = []
      @methods = []
      @predicates = {}
      @types = []
      until tokens.empty?
        case (group = tokens.shift).first
        when ':action' then parse_action(group)
        when 'domain' then @domain_name = group.last
        when ':requirements'
          group.shift
          @requirements = group
        when ':predicates'
        when ':types'
          # Type hierarchy
          raise 'Typing not required' unless @requirements.include?(':typing')
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
    if (tokens = scan_tokens(problem_filename)).instance_of?(Array) and tokens.shift == 'define'
      @state = []
      @objects = []
      @goal_pos = []
      @goal_not = []
      @tasks = []
      until tokens.empty?
        case (group = tokens.shift).first
        when 'problem' then @problem_name = group.last
        when ':domain' then raise 'Different domain specified in problem file' if @domain_name != group.last
        when ':requirements'
          group.shift
          @requirements.concat(group).uniq!
        when ':objects'
          # Move types to initial state
          group.shift
          raise 'Unexpected hyphen in objects' if group.first == HYPHEN
          index = 0
          until group.empty?
            @objects << group.shift
            if group.first == HYPHEN
              group.shift
              type = group.shift
              until index == @objects.size
                @state << [type, o = @objects[index]]
                index += 1
                # Convert type hierarchy to initial state predicates
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
          if group = group[1] and not group.empty?
            # Conjunction or atom
            group.first == AND ? group.shift : group = [group]
            group.each {|pre| pre.first != NOT ? @goal_pos << pre : pre.size == 2 ? @goal_not << pre.last : raise('Error with goals')}
          end
        else puts "#{group.first} is not recognized in problem"
        end
      end
    else raise "File #{problem_filename} does not match problem pattern"
    end
    @problem_name ||= 'unknown'
  end
end