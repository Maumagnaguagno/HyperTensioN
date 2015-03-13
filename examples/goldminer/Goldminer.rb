require '../../Hypertension'

module Goldminer
  include Hypertension
  extend self

  #-----------------------------------------------
  # Domain
  #-----------------------------------------------

  @domain = {
    # Operators
    'move' => true,
    'pick' => true,
    'drop' => true,
    'see' => false,
    'shift' => false,
    'visit_at' => false,
    'unvisit_at' => false,
    # Methods
    'travel' => [
      #'travel__bfs', # Optimal
      'travel__base',
      'travel__recursion'
    ],
    'get_gold' => [
      'get_gold__recursion',
      'get_gold__base'
    ]
  }

  # Memory
  @visited_at = Hash.new {|h,k| h[k] = []}

  #-----------------------------------------------
  # Operators
  #-----------------------------------------------

  def move(agent, from, to)
    apply_operator(
      # True preconditions
      [
        ['at', agent, from],
        ['adjacent', from, to]
      ],
      # False preconditions
      [
        ['blocked', to]
      ],
      # Add effects
      [
        ['at', agent, to]
      ],
      # Del effects
      [
        ['at', agent, from]
      ]
    )
  end

  def pick(agent, gold, where)
    apply_operator(
      # True preconditions
      [
        ['at', agent, where],
        ['on', gold, where]
      ],
      # False preconditions
      [],
      # Add effects
      [
        ['have', agent, gold]
      ],
      # Del effects
      [
        ['on', gold, where]
      ]
    )
  end

  def drop(agent, gold, where)
    apply_operator(
      # True preconditions
      [
        ['at', agent, where]
      ],
      # False preconditions
      [],
      # Add effects
      [
        ['on', gold, where]
      ],
      # Del effects
      [
        ['have', agent, gold]
      ]
    )
  end

  def see(gold)
    apply_operator(
      # True preconditions
      [],
      # False preconditions
      [],
      # Add effects
      [
        ['dibs', gold]
      ],
      # Del effects
      []
    )
  end

  def shift(agent, other)
    apply_operator(
      # True preconditions
      [],
      # False preconditions
      [],
      # Add effects
      [
        ['duty', other]
      ],
      # Del effects
      [
        ['duty', agent]
      ]
    )
  end

  def visit_at(agent, pos)
    @visited_at[agent] << pos.dup
    true
  end

  def unvisit_at(agent)
    @visited_at[agent].clear
    true
  end

  #-----------------------------------------------
  # Methods
  #-----------------------------------------------

  def travel__base(agent, from, to)
    if applicable?(
      # True preconditions
      [
        ['at', agent, to]
      ],
      # False preconditions
      []
    )
      yield [
        ['unvisit_at', agent]
      ]
    end
  end

  def travel__recursion(agent, from, to)
    # Free variables
    place = ''
    # Generate unifications
    generate(
    # True preconditions
    [
      ['at', agent, from],
      ['adjacent', from, place]
    ],
    # False preconditions
    [
      ['at', agent, to],
      ['blocked', place],
      ['blocked', to]
    ], place) {
      unless @visited_at[agent].include?(place)
        yield [
          ['move', agent, from, place],
          ['visit_at', agent, from],
          ['travel', agent, place, to]
        ]
      end
    }
  end

  def travel__bfs(agent, from, to)
    # TODO test if 'to' is blocked
    # TODO use generate as a generic method of unification
    frontier = [from]
    visited = {}
    place = ''
    adjacent = @state['adjacent']
    blocked = @state['blocked']
    until frontier.empty?
      current = frontier.shift
      plan = frontier.shift
      adjacent.each {|c,place|
        if c == current and not blocked.include?([place])
          unless visited.include?(place)
            if place == to
              solution = [['move', agent, current, to]]
              while plan
                to = current
                current, plan = plan
                solution.unshift(['move', agent, current, to])
              end
              yield solution
              return
            end
            visited[place] = nil
            frontier.push(place, [current, plan])
          end
        end
      }
    end
  end

  def get_gold__recursion
    # Free variables
    agent = ''
    agent_pos = ''
    other = ''
    gold = ''
    gold_pos = ''
    deposit_pos = ''
    # Generate unifications
    generate(
    # True preconditions
    [
      ['duty', agent],
      ['at', agent, agent_pos],
      ['on', gold, gold_pos],
      ['deposit', deposit_pos],
      ['next', agent, other]
    ],
    # False preconditions
    [
      ['dibs', gold]
    ], agent, agent_pos, other, gold, gold_pos, deposit_pos) {
      yield [
        ['see', gold],
        ['travel', agent, agent_pos, gold_pos],
        ['pick', agent, gold, gold_pos],
        ['travel', agent, gold_pos, deposit_pos],
        ['drop', agent, gold, deposit_pos],
        ['shift', agent, other],
        ['get_gold']
      ]
    }
  end

  def get_gold__base
    yield []
  end
end