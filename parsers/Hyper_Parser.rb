module Hyper_Parser
  extend self

  attr_reader :domain_name, :problem_name, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    @operators = []
    @methods = []
    @predicates = {}
    require domain_filename
    @domain_name ||= 'unknown'
  end

  #-----------------------------------------------
  # Parse problem
  #-----------------------------------------------

  def parse_problem(problem_filename)
    @state = {}
    @tasks = []
    @goal_pos = []
    @goal_not = []
    require problem_filename
    @problem_name ||= 'unknown'
  end
end