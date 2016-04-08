module Hyper_Parser
  extend self

  attr_reader :domain_name, :problem_name, :operators, :methods, :predicates, :state, :tasks, :goal_pos, :goal_not

  #-----------------------------------------------
  # Parse domain
  #-----------------------------------------------

  def parse_domain(domain_filename)
    @domain_name = 'unknown'
    @operators = []
    @methods = []
    @predicates = {}
    require domain_filename
  end

  #-----------------------------------------------
  # Parse problem
  #-----------------------------------------------

  def parse_problem(problem_filename)
    @problem_name = 'unknown'
    @state = {}
    @tasks = []
    @goal_pos = []
    @goal_not = []
    require problem_filename
  end
end