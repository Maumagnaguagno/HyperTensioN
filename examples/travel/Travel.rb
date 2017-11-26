require_relative '../../Hypertension'

module Travel
  include Hypertension
  extend self

  STAMINA = 2

  #-----------------------------------------------
  # Domain
  #-----------------------------------------------

  @domain = {
    # Operators
    'walk' => true,
    'call_taxi' => true,
    'ride_taxi' => true,
    'pay_driver' => true,
    # Methods
    'travel' => [
      'stay_here',
      'travel_by_taxi',
      'travel_by_foot'
    ]
  }

  #-----------------------------------------------
  # Definitions
  #-----------------------------------------------

  def taxi_rate(dist)
    dist * 0.5 + 1.5
  end

  #-----------------------------------------------
  # Operators
  #-----------------------------------------------

  def walk(agent, source, destination)
    apply_operator(
      # Positive preconditions
      [
        ['connected', source, destination],
        ['at', agent, source]
      ],
      # Negative preconditions
      [
        ['at', agent, destination]
      ],
      # Add effects
      [
        ['at', agent, destination]
      ],
      # Del effects
      [
        ['at', agent, source]
      ]
    )
  end

  def call_taxi(taxi_position, here)
    apply_operator(
      # Positive preconditions
      [
        ['at', 'taxi', taxi_position]
      ],
      # Negative preconditions
      [
        ['at', 'taxi', here]
      ],
      # Add effects
      [
        ['at', 'taxi', here]
      ],
      # Del effects
      [
        ['at', 'taxi', taxi_position]
      ]
    )
  end

  def ride_taxi(agent, source, destination, cost)
    apply_operator(
      # Positive preconditions
      [
        ['connected', source, destination],
        ['at', 'taxi', source],
        ['at', agent, source]
      ],
      # Negative preconditions
      [],
      # Add effects
      [
        ['at', 'taxi', destination],
        ['at', agent, destination],
        ['owe', agent, cost]
      ],
      # Del effects
      [
        ['at', 'taxi', destination],
        ['at', agent, destination]
      ]
    )
  end

  def pay_driver(agent, amount_of_money, cost)
    apply_operator(
      # Positive preconditions
      [
        ['cash', agent, amount_of_money],
        ['owe', agent, cost]
      ],
      # Negative preconditions
      [],
      # Add effects
      [
        ['cash', agent, (amount_of_money.to_i - cost.to_i).to_s]
      ],
      # Del effects
      [
        ['cash', agent, amount_of_money],
        ['owe', agent, cost]
      ]
    )
  end

  #-----------------------------------------------
  # Methods
  #-----------------------------------------------

  def stay_here(agent, source, destination)
    if applicable?(
      # Positive preconditions
      [
        ['at', agent, source],
        ['at', agent, destination]
      ],
      # Negative preconditions
      []
    )
      yield []
    end
  end

  def travel_by_taxi(agent, source, destination)
    # Free variables
    amount_of_money = ''
    taxi_position = ''
    distance = ''
    # Generate unifications
    generate(
      # Positive preconditions
      [
        ['at', agent, source],
        ['at', 'taxi', taxi_position],
        ['cash', agent, amount_of_money],
        ['distance', source, destination, distance]
      ],
      # Negative preconditions
      [
        ['at', agent, destination]
      ], amount_of_money, taxi_position, distance
    ) {
      distance = distance.to_i
      if distance > STAMINA
        cost = taxi_rate(distance)
        if amount_of_money.to_i >= cost
          cost = cost.to_s
          yield [
            ['call_taxi', taxi_position, source],
            ['ride_taxi', agent, source, destination, cost],
            ['pay_driver', agent, amount_of_money, cost]
          ]
        end
      end
    }
  end

  def travel_by_foot(agent, source, destination)
    if applicable?(
      # Positive preconditions
      [
        ['at', agent, source]
      ],
      # Negative preconditions
      [
        ['at', agent, destination]
      ]
    )
      yield [
        ['walk', agent, source, destination]
      ]
    end
  end
end