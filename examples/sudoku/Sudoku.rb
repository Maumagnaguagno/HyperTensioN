require File.expand_path('../../../Hypertension', __FILE__)

module Sudoku
  include Hypertension
  extend self

  EMPTY = '.'

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
    counter = 0
    collumn = []
    row = []
    box = []
    board = []
    board_str.delete!(" \n|+-")
    raise "Expected #{total_width * total_height} symbols, received #{board_str.size}" if board_str.size != total_width * total_height
    board_str.each_char.with_index {|symbol,i|
      y, x = i.divmod(total_width)
      b = "box_#{x / width + y / height * box_width}"
      board << [x = x.to_s, y = y.to_s, b, symbol]
      if symbol != EMPTY
        collumn << [x, symbol]
        row << [y, symbol]
        box << [b, symbol]
      else counter += 1
      end
    }
    # Setup
    start = {
      :symbol => Array.new(total_width) {|i| [i.succ.to_s]},
      :at => board,
      :collumn => collumn,
      :row => row,
      :box => box
    }
    tasks = [
      [:solve, counter, total_width, total_height, box_width * box_height]
    ]
    if verbose
      problem(start, tasks, debug)
    else
      @debug = debug
      @state = start
      planning(tasks)
    end
    # Output
    @state[:at].sort_by {|i| i.first(2).reverse!}.map {|i| i.last}.each_slice(total_width) {|i| puts i.join}
  end

  #-----------------------------------------------
  # Operators
  #-----------------------------------------------

  def put_symbol(x, y, box, symbol)
    apply(
      # Add effects
      [
        [:at, x, y, box, symbol],
        [:collumn, x, symbol],
        [:row, y, symbol],
        [:box, box, symbol]
      ],
      # Del effects
      [
        [:at, x, y, box, EMPTY]
      ]
    )
  end

  #-----------------------------------------------
  # Methods
  #-----------------------------------------------

  def try_next(counter, collumns, rows, boxes)
    puts counter if @debug
    return yield [] if counter.zero?
    counter -= 1
    # Check each cell, row and collumn elimination
    rows.times {|r|
      y = r.to_s
      collumns.times {|c|
        x = c.to_s
        box = ''
        symbol = ''
        available = nil
        generate(
          # Positive preconditions
          [
            [:at, x, y, box, EMPTY],
            [:symbol, symbol]
          ],
          # Negative preconditions
          [
            [:collumn, x, symbol],
            [:row, y, symbol],
            [:box, box, symbol]
          ], box, symbol
        ) {
          break available = nil if available
          available = [box.dup, symbol.dup]
        }
        # Cell only have one symbol available
        if available
          return yield [
            [:put_symbol, x, y, *available],
            [:solve, counter, collumns, rows, boxes]
          ]
        end
      }
    }
    # Check each box, box elimination
    available = Hash.new {|h,k| h[k] = []}
    x = ''
    y = ''
    symbol = ''
    boxes.times {|b|
      box = "box_#{b}"
      generate(
        # Positive preconditions
        [
          [:at, x, y, box, EMPTY],
          [:symbol, symbol]
        ],
        # Negative preconditions
        [
          [:collumn, x, symbol],
          [:row, y, symbol],
          [:box, box, symbol]
        ], x, y, symbol
      ) {
        available[symbol] << [x.dup, y.dup]
      }
      # Box only have one symbol available
      available.each {|symbol,positions|
        if positions.size == 1
          x, y = positions.first
          return yield [
            [:put_symbol, x, y, box, symbol],
            [:solve, counter, collumns, rows, boxes]
          ]
        end
      }
      available.clear
      x.clear
      y.clear
      symbol.clear
    }
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  debug = ARGV.last == '-d'
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
  # TODO add more strategies to solve hard boards (i.e. symbol only have one position inside box)
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