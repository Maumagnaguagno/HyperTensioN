#-----------------------------------------------
# Compute
#-----------------------------------------------

def compute(expression)
  case command = expression.shift
  when :and
    expression.all? {|e| compute(e)}
  when :or
    expression.any? {|e| compute(e)}
  when :xor
    expression.one? {|e| compute(e)}
  when :not
    expression.none? {|e| compute(e)}
  when :call
    call(expression)
  when :forall
    block = expression.pop
    forall?(*expression, &block)
  when :exists
    block = expression.pop
    exists?(*expression, &block)
  else @state[command].include?(expression)
  end
end

#-----------------------------------------------
# Call
#-----------------------------------------------

def call(expression)
  f = expression.shift
  if (value = expression.shift).instance_of?(Array) and value.first == :call
    value.shift
    value = call(value)
  end
  if expression.empty?
    send(f, value)
  else
    expression.each {|i| value = value.send(f, i.is_a?(Array) && i.first == :call ? (i.shift; call(i)) : i)}
    value
  end
end

#-----------------------------------------------
# Quantifiers
#-----------------------------------------------

def forall?(precond_pos, precond_not, *free)
  # Try all calls
  generate(precond_pos, precond_not, *free) {return false unless yield}
  true
end

def exists?(precond_pos, precond_not, *free)
  # Try until first call succeed
  generate(precond_pos, precond_not, *free) {return true if yield}
  false
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  require 'test/unit'
  require_relative '../../Hypertension'

  class Expression < Test::Unit::TestCase
    include Hypertension

    def test_compute
      @state = {:p => nil}
      variables = [[:a],[:b],[:c],[:d]]
      5.times {|i|
        variables.combination(i) {|p|
          @state[:p] = p
          pa = p.include?([:a])
          pb = p.include?([:b])
          pc = p.include?([:c])
          pd = p.include?([:d])
          expression = [:and,
            [:p, :a],
            [:or,
              [:p, :b],
              [:and,
                [:p, :c],
                [:not, [:p, :d]]
              ]
            ]
          ]
          assert_equal((pa and (pb or (pc and not pd))), compute(expression))
        }
      }
    end

    def test_call
      # (* 1 2 3 4)
      assert_equal(24, call(['*', 1, 2, 3, 4]))
      # (= 5 (+ 2 3))
      assert_equal(true, call(['==', 5, [:call, '+', 2, 3]]))
      # (= (+ 1 2 3) 6)
      assert_equal(true, call(['==', [:call, '+', 1, 2, 3], 6]))
      # (= (+ a b c) abc)
      assert_equal(true, call(['==', [:call, '+', 'a', 'b', 'c'], 'abc']))
    end

    def test_quantification_forall?
      # Variable x may assume any value from [1, 2, 3]
      @state = {:number => [['1'],['2'],['3']]}
      # For all numbers x, x != 0
      assert_equal(true, forall?([[:number, x = '']], [], x) {x.to_i != 0})
      # For all numbers x, x != 1
      assert_equal(false, forall?([[:number, x]], [], x.clear) {x.to_i != 1})
      # For all numbers x, x == 4
      assert_equal(false, forall?([[:number, x]], [], x.clear) {x.to_i == 4})
      # For all numbers x, x is odd or even
      assert_equal(true, forall?([[:number, x]], [], x.clear) {x.to_i.odd? or x.to_i.even?})
    end

    def test_quantification_exists?
      # Variable x may assume any value from [1, 2, 3]
      @state = {:number => [['1'],['2'],['3']]}
      # There exists a number x, x != 0
      assert_equal(true, exists?([[:number, x = '']], [], x) {x.to_i != 0})
      # There exists a number x, x != 1
      assert_equal(true, exists?([[:number, x]], [], x.clear) {x.to_i != 1})
      # There exists a number x, x == 4
      assert_equal(false, exists?([[:number, x]], [], x.clear) {x.to_i == 4})
      # There exists a number x, x is odd and even
      assert_equal(false, exists?([[:number, x]], [], x.clear) {x.to_i.odd? and x.to_i.even?})
    end
  end
end