require_relative '../../Hypertension'

module Sudoku
  include Hypertension
  extend self

  #-----------------------------------------------
  # Domain
  #-----------------------------------------------

  @domain = {
    # Operators
    :put_symbol => true,
    # Methods
    :solve => [:try_next]
  }

  def solve(board_str, width, height, box_width, box_height, debug, verbose)
    # Parser
    total_width = width * box_width
    total_height = height * box_height
    board_str.delete!(" \n|+-")
    raise "Expected #{total_width * total_height} symbols, received #{board_str.size}" if board_str.size != total_width * total_height
    cells = box_width * box_height
    symbols = Array.new(cells) {|i| i.succ}
    collumns = Array.new(total_width) {symbols.dup}
    rows = Array.new(total_height) {symbols.dup}
    boxes = Array.new(width * height) {symbols.dup}
    board = []
    counter = 0
    board_str.each_char.with_index {|symbol,i|
      y, x = i.divmod(total_width)
      board << [x, y, b = x / width + y / height * box_width, symbol = symbol.to_i]
      if symbol != 0
        collumns[x].delete(symbol)
        rows[y].delete(symbol)
        boxes[b].delete(symbol)
      else counter += 1
      end
    }
    # Setup
    state = {:at => board}
    collumns.each_with_index {|s,i| state["c#{i}"] = s}
    rows.each_with_index {|s,i| state["r#{i}"] = s}
    boxes.each_with_index {|s,i| state["b#{i}"] = s}
    tasks = [
      [:solve, counter, cells]
    ]
    if verbose
      problem(state, tasks, debug)
    else
      @debug = debug
      @state = state
      planning(tasks)
    end
    # Display board
    @state[:at].sort_by {|i| i.first(2).reverse!}.map {|i| i.last}.each_slice(total_width) {|i| puts i.join}
  end

  #-----------------------------------------------
  # Operators
  #-----------------------------------------------

  def put_symbol(x, y, b, symbol)
    apply(
      # Add effects
      [[:at, x, y, b, symbol]],
      # Del effects
      [[:at, x, y, b, 0]]
    )
    @state["c#{x}"].delete(symbol)
    @state["r#{y}"].delete(symbol)
    @state["b#{b}"].delete(symbol)
    true
  end

  #-----------------------------------------------
  # Methods
  #-----------------------------------------------

  def try_next(counter, cells)
    puts counter if @debug
    return yield [] if counter.zero?
    # Find available symbols for each empty cell
    available = Array.new(cells - 2) {[]}
    singles = []
    @state[:at].each {|x,y,b,symbol|
      if symbol == 0
        col = @state["c#{x}"]
        row = @state["r#{y}"]
        box = @state["b#{b}"]
        symbols = col & row & box
        if symbols.empty?
          return
        elsif symbols.size == 1
          singles << [:put_symbol, x, y, b, s = symbols.first]
          col.delete(s)
          row.delete(s)
          box.delete(s)
        else available[symbols.size - 2] << [x, y, b, symbols]
        end
      end
    }
    return yield singles << [:solve, counter - singles.size, cells] unless singles.empty?
    counter -= 1
    # Explore empty cells with fewest available symbols first
    available.each {|set|
      set.each {|x,y,b,symbols|
        symbols.each {|symbol|
          yield [
            [:put_symbol, x, y, b, symbol],
            [:solve, counter, cells]
          ]
        }
      }
    }
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  debug = ARGV.first == 'debug'
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