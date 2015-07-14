module PDDL_Parser
  extend self

  attr_reader :domain_name, :problem_name, :problem_domain, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

  #-----------------------------------------------
  # Define preconditions
  #-----------------------------------------------

  def define_preconditions(name, pro, pos, neg)
    raise "Error with #{name} preconditions" unless pro.instance_of?(Array)
    if pro.first == 'not'
      raise "Error with #{name} negative preconditions" if pro.size != 2
      pro = pro.last
      neg << pro
    else pos << pro
    end
    pro = pro.first
    pro.replace('equal') if pro == '='
    @predicates[pro] = true if @predicates[pro].nil?
  end

  #-----------------------------------------------
  # Define effects
  #-----------------------------------------------

  def define_effects(name, pro, add, del)
    raise "Error with #{name} effects" unless pro.instance_of?(Array)
    if pro.first == 'not'
      raise "Error with #{name} negative effects" if pro.size != 2
      pro = pro.last
      del << pro
    else add << pro
    end
    @predicates[pro.first] = false
  end

  #-----------------------------------------------
  # Define goals
  #-----------------------------------------------

  def define_goals(pro)
    if pro.first == 'not'
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
    name = op.shift
    raise 'Action without name definition' unless name.instance_of?(String)
    raise "Action #{name} redefined" if @operators.assoc(name)
    raise "Action #{name} have groups missing" if op.size != 6
    @operators << [name, free_variables = [], pos = [], neg = [], add = [], del = []]
    until op.empty?
      group = op.shift
      case group
      when ':parameters'
        raise "Error with #{name} parameters" unless op.first.instance_of?(Array)
        group = op.shift
        raise "Error with #{name} typed parameters" if group.first == '-'
        parameters = []
        until group.empty?
          o = group.shift
          parameters << o
          free_variables << o
          # Make "ob1 ob2 - type" become [type, ob1] [type, ob2]
          if group.first == '-'
            group.shift
            type = group.shift
            pos << [type, parameters.shift] until parameters.empty?
            @predicates[type] = true if @predicates[type].nil?
          end
        end
        raise "Action #{name} with repeated parameters" if free_variables.uniq!
      when ':precondition'
        group = op.shift
        raise "Error with #{name} precondition" unless group.instance_of?(Array)
        # Conjunction
        if group.first == 'and'
          group.shift
          group.each {|pro| define_preconditions(name, pro, pos, neg)}
        # Atom
        else define_preconditions(name, group, pos, neg)
        end
      when ':effect'
        group = op.shift
        raise "Error with #{name} effect" unless group.instance_of?(Array)
        # Conjunction
        if group.first == 'and'
          group.shift
          group.each {|pro| define_effects(name, pro, add, del)}
        # Atom
        else define_effects(name, group, add, del)
        end
      end
    end
  end

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    description = IO.read(domain_filename)
    description.gsub!(/;.*$|\n/,'')
    description.downcase!
    tokens = Hype.scan_tokens(description)
    if tokens.instance_of?(Array) and tokens.shift == 'define'
      @operators = []
      @methods = []
      @domain_name = 'unknown'
      @predicates = {}
      @types = []
      @requirements = []
      until tokens.empty?
        group = tokens.shift
        case group.first
        when 'domain'
          raise 'Domain group has size different of 2' if group.size != 2
          @domain_name = group.last
        when ':requirements'
          group.shift
          @requirements.push(*group)
        when ':predicates'
          # TODO take advantage of predicates definition
        when ':action' then parse_action(group)
        when ':types'
          # Type hierarchy
          raise 'Typing not required' unless @requirements.include?(':typing')
          group.shift
          raise 'Error with types' if group.first == '-'
          subtypes = []
          until group.empty?
            subtypes << group.shift
            if group.first == '-'
              group.shift
              type = group.shift
              @types << [subtypes.shift, type] until subtypes.empty?
            end
          end
        else puts "#{group.first} is not recognized"
        end
      end
    else raise "File #{domain_filename} does not match domain pattern"
    end
  end

  #-----------------------------------------------
  # Parse problem
  #-----------------------------------------------

  def parse_problem(problem_filename)
    description = IO.read(problem_filename)
    description.gsub!(/;.*$|\n/,'')
    description.downcase!
    tokens = Hype.scan_tokens(description)
    if tokens.instance_of?(Array) and tokens.shift == 'define'
      @problem_name = 'unknown'
      @problem_domain = 'unknown'
      @state = []
      @objects = []
      until tokens.empty?
        group = tokens.shift
        case group.first
        when 'problem'
          @problem_name = group.last
        when ':domain'
          @problem_domain = group.last
        when ':requirements'
          group.shift
          @requirements.push(*group)
          @requirements.uniq!
        when ':objects'
          # Move types to initial state
          group.shift
          raise 'Error with typed objects' if group.first == '-'
          objects = []
          until group.empty?
            o = group.shift
            objects << o
            @objects << o
            if group.first == '-'
              group.shift
              type = group.shift
              until objects.empty?
                o = objects.shift
                @state << [type, o]
                # Convert type hierarchy to propositions of initial state
                types = [type]
                until types.empty?
                  @types.each {|sub,t|
                    if sub == types.first
                      @state << [t, o]
                      types << t
                    end
                  }
                  types.shift
                end
              end
            end
          end
          @objects.each {|o| @state << ['equal', o, o]} if @requirements.include?(':equality')
        when ':init'
          group.shift
          @state.push(*group)
          @state.each {|proposition| @predicates[proposition.first] = nil unless @predicates.include?(proposition.first)}
        when ':goal'
          @goal_pos = []
          @goal_not = []
          @tasks = []
          group = group[1]
          return unless group
          # Conjunction
          if group.first == 'and'
            group.shift
            group.each {|pro| define_goals(pro)}
          # Atom
          else define_goals(group)
          end
        end
      end
    else raise "File #{problem_filename} does not match problem pattern"
    end
  end
end