require './tests/hypest'

class Disorder < Test::Unit::TestCase
  include Hypest

  DOMAIN = 'examples/basic/basic.jshop'
  ORDERED = 'examples/basic/pb2.jshop'
  UNORDERED = 'examples/basic/pb3.jshop'

  def test_ordered_ruby_execution
    interpreted_execution_tests(DOMAIN, ORDERED, 'Hype.rb', 'Planning failed')
    interpreted_execution_tests(DOMAIN, ORDERED, '-s Hype.rb -IPC', 'Planning failed')
  end

  def test_unordered_ruby_execution
    interpreted_execution_tests(DOMAIN, UNORDERED, 'Hype.rb', "0: pickup(kiwi)\n1: drop(kiwi)\nTotal")
    interpreted_execution_tests(DOMAIN, UNORDERED, '-s Hype.rb -IPC', "\n==>\n0 pickup kiwi\n1 drop kiwi\nroot 0 1\n<==\n")
  end
end