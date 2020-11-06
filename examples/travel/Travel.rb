require_relative '../../Hypertension'

module Travel
  include Hypertension
  extend self

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
  # Operators
  #-----------------------------------------------

  def walk(agent, source, destination)
    apply_operator(
      # Positive preconditions
      [
        [CONNECTED, source, destination],
        [AT, agent, source]
      ],
      # Negative preconditions
      [
        [AT, agent, destination]
      ],
      # Add effects
      [
        [AT, agent, destination]
      ],
      # Del effects
      [
        [AT, agent, source]
      ]
    )
  end

  def call_taxi(taxi_position, here)
    apply_operator(
      # Positive preconditions
      [
        [AT, 'taxi', taxi_position]
      ],
      # Negative preconditions
      [],
      # Add effects
      [
        [AT, 'taxi', here]
      ],
      # Del effects
      [
        [AT, 'taxi', taxi_position]
      ]
    )
  end

  def ride_taxi(agent, source, destination, cost)
    apply_operator(
      # Positive preconditions
      [
        [CONNECTED, source, destination],
        [AT, 'taxi', source],
        [AT, agent, source]
      ],
      # Negative preconditions
      [],
      # Add effects
      [
        [AT, 'taxi', destination],
        [AT, agent, destination],
        [OWE, agent, cost]
      ],
      # Del effects
      [
        [AT, 'taxi', source],
        [AT, agent, destination]
      ]
    )
  end

  def pay_driver(agent, amount_of_money, cost)
    apply_operator(
      # Positive preconditions
      [
        [CASH, agent, amount_of_money],
        [OWE, agent, cost]
      ],
      # Negative preconditions
      [],
      # Add effects
      [
        [CASH, agent, (amount_of_money.to_f - cost.to_f).to_s]
      ],
      # Del effects
      [
        [CASH, agent, amount_of_money],
        [OWE, agent, cost]
      ]
    )
  end

  #-----------------------------------------------
  # Methods
  #-----------------------------------------------

  def stay_here(agent, destination)
    if applicable?(
      # Positive preconditions
      [
        [AT, agent, destination]
      ],
      # Negative preconditions
      []
    )
      yield []
    end
  end

  def travel_by_taxi(agent, destination)
    # Free variables
    source = ''
    amount_of_money = ''
    taxi_position = ''
    distance = ''
    stamina = ''
    # Generate unifications
    generate(
      # Positive preconditions
      [
        [AT, agent, source],
        [AT, 'taxi', taxi_position],
        [CASH, agent, amount_of_money],
        [DISTANCE, source, destination, distance],
        [STAMINA, agent, stamina]
      ],
      # Negative preconditions
      [
        [AT, agent, destination]
      ], source, amount_of_money, taxi_position, distance, stamina
    ) {
      distance = distance.to_i
      if distance > stamina.to_i
        cost = distance * 0.5 + 1.5
        if amount_of_money.to_f >= cost
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

  def travel_by_foot(agent, destination)
    # Free variables
    source = ''
    # Generate unifications
    generate(
      # Positive preconditions
      [
        [AT, agent, source]
      ],
      # Negative preconditions
      [
        [AT, agent, destination]
      ], source
    ) {
      yield [
        ['walk', agent, source, destination]
      ]
    }
  end
end