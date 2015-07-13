require File.expand_path('../../../Hypertension', __FILE__)

module N_Queens
  include Hypertension
  extend self

  CLEAR = ?.
  QUEEN = ?Q

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
        ['board', x, y, QUEEN]
      ],
      # Del effects
      [
        ['board', x, y, CLEAR],
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
        ['free_collumn', x], # Check this first to limit faster the possible values
        ['board', x, y, CLEAR]
      ],
      # Negative preconditions
      [], x
    ) {
      # No need to test x == i, free collumn test
      # No need to test y == j, every piece has their row
      xi = x.to_i
      next if @state['board'].any? {|i,j,p| p == QUEEN and (xi - i.to_i).abs == (yi - j.to_i).abs}
      yield [
        ['put_piece', x, y],
        ['solve', yi]
      ]
    }
  end
end

begin
  # NxN board
  size = ARGV.first ? ARGV.first.to_i : 8
  board = []
  size.times {|i| size.times {|j| board << [i.to_s, j.to_s, N_Queens::CLEAR]}}
  N_Queens.problem(
    # Start
    {
      'board' => board,
      'free_collumn' => Array.new(size) {|i| [i.to_s]}
    },
    # Tasks
    [
      ['solve', size]
    ]
  )
  # Draw
  board = []
  N_Queens.state['board'].each {|x,y,p| board[x.to_i + y.to_i * size] = p}
  index = -1
  size.times {
    size.times {print board[index += 1]}
    puts
  }
end