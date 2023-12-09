require_relative '../../Hypertension'

module Sudoku
  include Hypertension
  extend self

  #-----------------------------------------------
  # Domain
  #-----------------------------------------------

  BOARD = 0
  EMPTY = 1

  @domain = {
    # Operators
    :put_symbol => true,
    # Methods
    :solve => [:try_next]
  }

  def solve(board_str, width, height, box_width, box_height, debug, verbose)
    # Parser
    x_index = 2
    y_index = x_index + total_width = width * box_width
    b_index = y_index + total_height = height * box_height
    board_str.delete!(" \n|+-")
    raise "Expected #{total_width * total_height} symbols, received #{board_str.size}" if board_str.size != total_width * total_height
    symbols = (1..box_width * box_height).to_a
    state = [board = [], empty = []]
    (total_width + total_height + width * height).times {state << symbols.dup}
    counter = 0
    board_str.each_char.with_index {|symbol,i|
      symbol = symbol.to_i
      y, x = i.divmod(total_width)
      b = x / width + y / height * box_width + b_index
      if symbol != 0
        board << [y += y_index, x += x_index, symbol]
        state[x].delete(symbol)
        state[y].delete(symbol)
        state[b].delete(symbol)
      else
        empty << [x_index + x, y_index + y, b]
        counter += 1
      end
    }
    # Setup
    tasks = [
      [:solve, counter]
    ]
    if verbose
      problem(state, tasks, debug)
    else
      @debug = debug
      @state = state
      planning(tasks)
    end
    # Display board
    @state[BOARD].sort!.map!(&:last).each_slice(total_width) {|i| puts i.join}
  end

  #-----------------------------------------------
  # Operators
  #-----------------------------------------------

  def put_symbol(x, y, b, symbol)
    @state = @state.map(&:dup)
    @state[x].delete(symbol)
    @state[y].delete(symbol)
    @state[b].delete(symbol)
    @state[EMPTY].delete([x, y, b])
    @state[BOARD] << [y, x, symbol]
    true
  end

  #-----------------------------------------------
  # Methods
  #-----------------------------------------------

  def try_next(counter)
    puts counter if @debug
    return yield [] if counter.zero?
    # Find available symbols for each empty cell
    best = 100
    available = nil
    singles = []
    @state[EMPTY].each {|x,y,b|
      col = @state[x]
      row = @state[y]
      box = @state[b]
      symbols = col & row & box
      if symbols.empty?
        return
      elsif symbols.size == 1
        singles << [:put_symbol, x, y, b, s = symbols[0]]
        col.delete(s)
        row.delete(s)
        box.delete(s)
      elsif symbols.size < best
        best = symbols.size
        available = [x, y, b, symbols]
      end
    }
    return yield singles << [:solve, counter - singles.size] unless singles.empty?
    counter -= 1
    # Explore empty cell with fewest available symbols
    x, y, b, symbols = available
    symbols.each {|symbol|
      yield [
        [:put_symbol, x, y, b, symbol],
        [:solve, counter]
      ]
    }
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  debug = ARGV[0] == 'debug'
  # Easy
  board = '
  3 4 | 1 2
  . . | . .
  ----+----
  . . | . .
  4 2 | 3 1'
  Sudoku.solve(board, 2, 2, 2, 2, debug, true)
  # Medium
  board = '
  . . 3 | . 2 . | 6 . .
  9 . . | 3 . 5 | . . 1
  . . 1 | 8 . 6 | 4 . .
  ------+-------+------
  . . 8 | 1 . 2 | 9 . .
  7 . . | . . . | . . 8
  . . 6 | 7 . 8 | 2 . .
  ------+-------+------
  . . 2 | 6 . 9 | 5 . .
  8 . . | 2 . 3 | . . 9
  . . 5 | . 1 . | 3 . .'
  Sudoku.solve(board, 3, 3, 3, 3, debug, true)
  # Hard
  board = '
  4 . . | . . . | 8 . 5
  . 3 . | . . . | . . .
  . . . | 7 . . | . . .
  ------+-------+------
  . 2 . | . . . | . 6 .
  . . . | . 8 . | 4 . .
  . . . | . 1 . | . . .
  ------+-------+------
  . . . | 6 . 3 | . 7 .
  5 . . | 2 . . | . . .
  1 . 4 | . . . | . . .'
  Sudoku.solve(board, 3, 3, 3, 3, debug, true)
end