require_relative '../../Hypertension'

module N_Queens
  include Hypertension
  extend self

  #-----------------------------------------------
  # Domain
  #-----------------------------------------------

  @domain = {
    # Operators
    :put_piece => true,
    # Methods
    :solve => [:try_next]
  }

  def solve(size, debug, verbose)
    state = {
      :queen => [],
      :free_collumn => (0...size).to_a
    }
    tasks = [
      [:solve, size]
    ]
    if verbose
      problem(state, tasks, debug)
    else
      @debug = debug
      @state = state
      planning(tasks)
    end
  end

  #-----------------------------------------------
  # Operators
  #-----------------------------------------------

  def put_piece(x, y)
    # Add effects
    q = @state[:queen].dup << [x, y]
    # Del effects
    (f = @state[:free_collumn].dup).delete(x)
    @state = {:queen => q, :free_collumn => f}
  end

  #-----------------------------------------------
  # Methods
  #-----------------------------------------------

  def try_next(y)
    # Base of recursion
    return yield [] if y.zero?
    y -= 1 # Closed row boost
    queen = @state[:queen]
    # Generate unifications without generate
    @state[:free_collumn].each {|x|
      # No need to test x == i, free collumn test, or y == j, every piece have a row
      next if queen.any? {|i,j| (i - x).abs == j - y}
      yield [
        [:put_piece, x, y],
        [:solve, y]
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
  N_Queens.solve(size, ARGV.last == 'debug', true)
  # Draw from row size - 1 to 0
  N_Queens.state[:queen].reverse_each {|i,j|
    row = '[ ]' * size
    row[i * 3 + 1] = 'Q'
    puts row
  }
end