require './tests/hypest'

class Disorder < Test::Unit::TestCase
  include Hypest

  DOMAIN = 'examples/basic/basic.jshop'
  ORDERED1 = 'examples/basic/pb1.jshop'
  ORDERED2 = 'examples/basic/pb2.jshop'
  UNORDERED = 'examples/basic/pb3.jshop'

  def test_ordered_ruby_solvable_execution
    interpreted_execution_tests(DOMAIN, ORDERED1, 'Hype.rb', "0: drop(kiwi)\n1: pickup(banjo)\nTotal")
    interpreted_execution_tests(DOMAIN, ORDERED1, '-s Hype.rb -IPC', "\n==>\n1 drop kiwi\n2 pickup banjo\nroot 0\n0 swap banjo kiwi -> case_1 1 2\n<==\n")
  end

  def test_ordered_ruby_unsolvable_execution
    interpreted_execution_tests(DOMAIN, ORDERED2, 'Hype.rb', 'Planning failed')
    interpreted_execution_tests(DOMAIN, ORDERED2, '-s Hype.rb -IPC', 'Planning failed')
  end

  def test_unordered_ruby_execution
    interpreted_execution_tests(DOMAIN, UNORDERED, 'Hype.rb', "0: pickup(kiwi)\n1: drop(kiwi)\nTotal")
    interpreted_execution_tests(DOMAIN, UNORDERED, '-s Hype.rb -IPC', "\n==>\n0 pickup kiwi\n1 drop kiwi\nroot 0 1\n<==\n")
  end
end