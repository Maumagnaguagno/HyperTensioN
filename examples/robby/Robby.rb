require_relative '../../Hypertension'

module Robby
  include Hypertension
  extend self

  #-----------------------------------------------
  # Domain
  #-----------------------------------------------

  @domain = {
    # Operators
    'enter' => true,
    'exit' => true,
    'move' => true,
    'report' => true,
    'visit_at' => false,
    'unvisit_at' => false,
    # Methods
    'swap_at' => [
      'swap_at__base',
      'swap_at__recursion_enter',
      'swap_at__recursion_exit',
      'swap_at__recursion_move'
    ]
  }
  # Memory
  @visited_at = Hash.new {|h,k| h[k] = []}

  #-----------------------------------------------
  # Operators
  #-----------------------------------------------

  def enter(bot, source, destination)
    apply_operator(
      # Positive preconditions
      [
        ['robot', bot],
        ['hallway', source],
        ['room', destination],
        ['at', bot, source],
        ['connected', source, destination]
      ],
      # Negative preconditions
      [
        ['at', bot, destination]
      ],
      # Add effects
      [
        ['at', bot, destination]
      ],
      # Del effects
      [
        ['at', bot, source]
      ]
    )
  end

  def exit(bot, source, destination)
    apply_operator(
      # Positive preconditions
      [
        ['robot', bot],
        ['room', source],
        ['hallway', destination],
        ['at', bot, source],
        ['connected', source, destination]
      ],
      # Negative preconditions
      [
        ['at', bot, destination]
      ],
      # Add effects
      [
        ['at', bot, destination]
      ],
      # Del effects
      [
        ['at', bot, source]
      ]
    )
  end

  def move(bot, source, destination)
    apply_operator(
      # Positive preconditions
      [
        ['robot', bot],
        ['hallway', source],
        ['hallway', destination],
        ['at', bot, source],
        ['connected', source, destination]
      ],
      # Negative preconditions
      [
        ['at', bot, destination]
      ],
      # Add effects
      [
        ['at', bot, destination]
      ],
      # Del effects
      [
        ['at', bot, source]
      ]
    )
  end

  def report(bot, source, beacon)
    apply_operator(
      # Positive preconditions
      [
        ['robot', bot],
        ['location', source],
        ['beacon', beacon],
        ['at', bot, source],
        ['in', beacon, source]
      ],
      # Negative preconditions
      [
        ['reported', bot, beacon]
      ],
      # Add effects
      [
        ['reported', bot, beacon]
      ],
      # Del effects
      []
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

  def swap_at__base(object, goal)
    if applicable?(
      # Positive preconditions
      [
        ['at', object, goal]
      ],
      # Negative preconditions
      []
    )
      yield [
        ['unvisit_at', object]
      ]
    end
  end

  def swap_at__recursion_enter(object, goal)
    # Free variables
    current = ''
    intermediate = ''
    # Generate unifications
    generate(
      # Positive preconditions
      [
        ['at', object, current],
        ['connected', current, intermediate]
      ],
      # Negative preconditions
      [
        ['at', object, goal]
      ], current, intermediate
    ) {
      unless @visited_at[object].include?(intermediate)
        yield [
          ['enter', object, current, intermediate],
          ['visit_at', object, current],
          ['swap_at', object, goal]
        ]
      end
    }
  end

  def swap_at__recursion_exit(object, goal)
    # Free variables
    current = ''
    intermediate = ''
    # Generate unifications
    generate(
      # Positive preconditions
      [
        ['at', object, current],
        ['connected', current, intermediate]
      ],
      # Negative preconditions
      [
        ['at', object, goal]
      ], current, intermediate
    ) {
      unless @visited_at[object].include?(intermediate)
        yield [
          ['exit', object, current, intermediate],
          ['visit_at', object, current],
          ['swap_at', object, goal]
        ]
      end
    }
  end

  def swap_at__recursion_move(object, goal)
    # Free variables
    current = ''
    intermediate = ''
    # Generate unifications
    generate(
      # Positive preconditions
      [
        ['at', object, current],
        ['connected', current, intermediate]
      ],
      # Negative preconditions
      [
        ['at', object, goal]
      ], current, intermediate
    ) {
      unless @visited_at[object].include?(intermediate)
        yield [
          ['move', object, current, intermediate],
          ['visit_at', object, current],
          ['swap_at', object, goal]
        ]
      end
    }
  end
end