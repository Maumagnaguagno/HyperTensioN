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

  def solve(size, debug, verbose)
    start = {
      'queen' => [],
      'free_collumn' => Array.new(size) {|i| [i.to_s]}
    }
    tasks = [
      ['solve', size]
    ]
    if verbose
      problem(start, tasks, debug)
    else
      @debug = debug
      @state = start
      planning(tasks)
    end
  end

  #-----------------------------------------------
  # Operators
  #-----------------------------------------------

  def put_piece(x, y)
    apply(
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
    return yield [] if c.zero?
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

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  # Size input
  size = ARGV.first ? ARGV.first.to_i : 8
  N_Queens.solve(size, ARGV.last == '-d', true)
  # Draw from row size - 1 to 0
  N_Queens.state['queen'].reverse_each {|i,j|
    row = '[ ]' * size
    row[i.to_i * 3 + 1] = 'Q'
    puts row
  }
end
