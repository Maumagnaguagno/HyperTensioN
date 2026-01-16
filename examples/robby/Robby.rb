require_relative '../../Hypertension'

module Robby
  include Hypertension
  extend self

  #-----------------------------------------------
  # Domain
  #-----------------------------------------------

  @domain = {
    # Operators
    :enter => true,
    :exit => true,
    :move => true,
    :report => true,
    :visit_at => false,
    :unvisit_at => false,
    # Methods
    :swap_at => [
      :swap_at__base,
      :swap_at__recursion_enter,
      :swap_at__recursion_exit,
      :swap_at__recursion_move
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
        [ROBOT, bot],
        [HALLWAY, source],
        [ROOM, destination],
        [AT, bot, source],
        [CONNECTED, source, destination]
      ],
      # Negative preconditions
      [
        [AT, bot, destination]
      ],
      # Add effects
      [
        [AT, bot, destination]
      ],
      # Del effects
      [
        [AT, bot, source]
      ]
    )
  end

  def exit(bot, source, destination)
    apply_operator(
      # Positive preconditions
      [
        [ROBOT, bot],
        [ROOM, source],
        [HALLWAY, destination],
        [AT, bot, source],
        [CONNECTED, source, destination]
      ],
      # Negative preconditions
      [
        [AT, bot, destination]
      ],
      # Add effects
      [
        [AT, bot, destination]
      ],
      # Del effects
      [
        [AT, bot, source]
      ]
    )
  end

  def move(bot, source, destination)
    apply_operator(
      # Positive preconditions
      [
        [ROBOT, bot],
        [HALLWAY, source],
        [HALLWAY, destination],
        [AT, bot, source],
        [CONNECTED, source, destination]
      ],
      # Negative preconditions
      [
        [AT, bot, destination]
      ],
      # Add effects
      [
        [AT, bot, destination]
      ],
      # Del effects
      [
        [AT, bot, source]
      ]
    )
  end

  def report(bot, source, beacon)
    apply_operator(
      # Positive preconditions
      [
        [ROBOT, bot],
        [LOCATION, source],
        [BEACON, beacon],
        [AT, bot, source],
        [IN, beacon, source]
      ],
      # Negative preconditions
      [
        [REPORTED, bot, beacon]
      ],
      # Add effects
      [
        [REPORTED, bot, beacon]
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
        [AT, object, goal]
      ],
      # Negative preconditions
      []
    )
      yield [
        [:unvisit_at, object]
      ]
    end
  end

  def swap_at__recursion_enter(object, goal)
    # Generate unifications
    generate(
      # Free variables
      [
        current = '',
        intermediate = ''
      ],
      # Positive preconditions
      [
        [AT, object, current],
        [CONNECTED, current, intermediate]
      ],
      # Negative preconditions
      [
        [AT, object, goal]
      ]
    ) {
      unless @visited_at[object].include?(intermediate)
        yield [
          [:enter, object, current, intermediate],
          [:visit_at, object, current],
          [:swap_at, object, goal]
        ]
      end
    }
  end

  def swap_at__recursion_exit(object, goal)
    # Generate unifications
    generate(
      # Free variables
      [
        current = '',
        intermediate = ''
      ],
      # Positive preconditions
      [
        [AT, object, current],
        [CONNECTED, current, intermediate]
      ],
      # Negative preconditions
      [
        [AT, object, goal]
      ]
    ) {
      unless @visited_at[object].include?(intermediate)
        yield [
          [:exit, object, current, intermediate],
          [:visit_at, object, current],
          [:swap_at, object, goal]
        ]
      end
    }
  end

  def swap_at__recursion_move(object, goal)
    # Generate unifications
    generate(
      # Free variables
      [
        current = '',
        intermediate = ''
      ],
      # Positive preconditions
      [
        [AT, object, current],
        [CONNECTED, current, intermediate]
      ],
      # Negative preconditions
      [
        [AT, object, goal]
      ]
    ) {
      unless @visited_at[object].include?(intermediate)
        yield [
          [:move, object, current, intermediate],
          [:visit_at, object, current],
          [:swap_at, object, goal]
        ]
      end
    }
  end
end