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
    'visit' => true,
    'unvisit' => true,
    'see' => true,
    'shift' => true,

    # Methods
    'travel' => [
      'travel_impossible',
      'travel_base',
      'travel_rail',
      'travel_recursion'
    ],
    'get_gold' => [
      'get_gold_recursion',
      'get_gold_base'
    ]
  }

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
        ['has', agent, gold]
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
        ['has', agent, gold]
      ]
    )
  end

  def visit(agent, pos)
    apply_operator(
      # True preconditions
      [],
      # False preconditions
      [],
      # Add effects
      [
        ['visited', agent, pos]
      ],
      # Del effects
      []
    )
  end

  def unvisit(agent, pos)
    apply_operator(
      # True preconditions
      [],
      # False preconditions
      [],
      # Add effects
      [],
      # Del effects
      [
        ['visited', agent, pos]
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

  def shift(agent)
    apply_operator(
      # True preconditions
      [
        ['next', agent, other]
      ],
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

  #-----------------------------------------------
  # Methods
  #-----------------------------------------------

  def travel_impossible(agent, to)
    if applicable?(
      # True preconditions
      [
        ['blocked', to],
      ],
      # False preconditions
      []
    )
      yield []
    end
  end

  def travel_base(agent, to)
    if applicable?(
      # True preconditions
      [
        ['at', agent, to],
      ],
      # False preconditions
      []
    )
      yield []
    end
  end

  def travel_rail(agent, to)
    from = ''
    place = ''
    generate(
      # True preconditions
      [
        ['at', agent, from],
        ['rail', from, place],
      ],
      # False preconditions
      [
        ['at', agent, to],
        ['blocked', place],
        ['visited', agent, place],
      ], from, place) {
      yield [
        ['move', agent, from, place],
        ['visit', agent, from],
        ['travel', agent, to],
        ['unvisit', agent, from]
      ]
    }
  end

  def travel_recursion(agent, to)
    from = ''
    place = ''
    generate(
      # True preconditions
      [
        ['at', agent, from],
        ['adjacent', from, place],
      ],
      # False preconditions
      [
        ['at', agent, to],
        ['rail', from, place],
        ['blocked', place],
        ['visited', agent, place],
      ], from, place) {
      yield [
        ['move', agent, from, place],
        ['visit', agent, from],
        ['travel', agent, to],
        ['unvisit', agent, from]
      ]
    }
  end

  def get_gold_recursion()
    agent = ''
    agent_pos = ''
    gold = ''
    gold_pos = ''
    anygold = ''
    deposit_pos = ''
    generate(
      # True preconditions
      [
        ['duty', agent],
        ['at', agent, agent_pos],
        ['on', gold, gold_pos],
        ['deposit', deposit_pos],
      ],
      # False preconditions
      [
        ['has', agent, anygold],
        ['dibs', gold],
      ], agent, agent_pos, gold, gold_pos, anygold, deposit_pos) {
      yield [
        ['see', gold],
        ['travel', agent, gold_pos],
        ['pick', agent, gold, gold_pos],
        ['travel', agent, deposit_pos],
        ['drop', agent, gold, deposit_pos],
        ['shift', agent],
        ['get_gold']
      ]
    }
  end

  def get_gold_base()
    yield []
  end

end
