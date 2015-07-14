require File.expand_path('../../../Hypertension', __FILE__)

module N_Queens
  include Hypertension
  extend self

  #-----------------------------------------------
  # Domain
  #-----------------------------------------------

  @domain = {
    # Operators
    'put_piece' => true,
    # Methods
    'solve' => ['try_next']
  }

  #-----------------------------------------------
  # Operators
  #-----------------------------------------------

  def put_piece(x, y)
    apply_operator(
      # Positive preconditions
      [],
      # Negative preconditions
      [],
      # Add effects
      [
        ['queen', x, y]
      ],
      # Del effects
      [
        ['free_collumn', x]
      ]
    )
  end

  #-----------------------------------------------
  # Methods
  #-----------------------------------------------

  def try_next(c)
    # Base of recursion
    if c.zero?
      yield []
      return
    end
    yi = c.pred
    # Free variables
    x = ''
    y = yi.to_s # Closed row boost
    # Generate unifications
    generate(
      # Positive preconditions
      [
        ['free_collumn', x]
      ],
      # Negative preconditions
      [], x
    ) {
      # No need to test x == i, free collumn test, or y == j, every piece has their row
      xi = x.to_i
      next if @state['queen'].any? {|i,j| (xi - i.to_i).abs == (yi - j.to_i).abs}
      yield [
        ['put_piece', x, y],
        ['solve', yi]
      ]
    }
  end
end

begin
  # Size input
  size = ARGV.first ? ARGV.first.to_i : 8
  N_Queens.problem(
    # Start
    {
      'queen' => [],
      'free_collumn' => Array.new(size) {|i| [i.to_s]}
    },
    # Tasks
    [
      ['solve', size]
    ]
  )
  # Draw from row size - 1 to 0
  N_Queens.state['queen'].reverse_each {|i,j|
    row = '.' * size
    row[i.to_i] = 'Q'
    puts row
  }
end