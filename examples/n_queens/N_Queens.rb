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
        ['board', x, y, 'Q']
      ],
      # Del effects
      [
        ['board', x, y, '.']
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
    # Free variables
    x = ''
    y = c.pred.to_s # Closed collumn boost
    # Generate unifications
    generate(
      # Positive preconditions
      [
        ['board', x, y, '.'],
      ],
      # Negative preconditions
      [], x
    ) {
      xi = x.to_i
      yi = y.to_i
      next if @state['board'].any? {|i,j,p|
        p == 'Q' and x == i || y == j || (xi - i.to_i).abs == (yi - j.to_i).abs
      }
      yield [
        ['put_piece', x, y],
        ['solve', c.pred]
      ]
    }
  end

  def solve_board(size)
    board = []
    size.times {|i| size.times {|j| board << [i.to_s, j.to_s, '.']}}
    problem(
      # Start
      {'board' => board},
      # Tasks
      [['solve', size]]
    )
    board = []
    @state['board'].each {|x,y,p| board[x.to_i + y.to_i * size] = p}
    index = 0
    size.times {
      size.times {
        print board[index]
        index += 1
      }
      puts
    }
  end
end

N_Queens.solve_board(ARGV.first ? ARGV.first.to_i : 8)