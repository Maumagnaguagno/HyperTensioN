#-----------------------------------------------
# Evaluate
#-----------------------------------------------

def evaluate(expression, &block)
  case first = expression.shift
  when :and then expression.all? {|e| evaluate(e)}
  when :or then expression.any? {|e| evaluate(e)}
  when :xor then expression.one? {|e| evaluate(e)}
  when :not then expression.none? {|e| evaluate(e)}
  when :call then call(expression)
  when :forall then forall?(*expression, &block)
  when :exists then exists?(*expression, &block)
  else @state[first].include?(expression)
  end
end

#-----------------------------------------------
# Call
#-----------------------------------------------

def call(expression)
  f = expression.shift
  expression.map! {|i| i.instance_of?(Array) && i[0] == :call ? (i.shift; call(i)) : i}.inject(f)
end

#-----------------------------------------------
# Quantifiers
#-----------------------------------------------

def forall?(free, precond_pos, precond_not)
  # Try all calls
  generate(free, precond_pos, precond_not) {return false unless yield}
  true
end

def exists?(free, precond_pos, precond_not)
  # Try until first call succeed
  generate(free, precond_pos, precond_not) {return true if yield}
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

    def test_evaluate
      @state = {}
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
          assert_equal((pa and (pb or (pc and not pd))), evaluate(expression))
        }
      }
      @state = {:number => [['1'],['2'],['3']]}
      assert_true(evaluate([:xor, [:number, '1'], [:number, 'a']]))
      assert_false(evaluate([:xor, [:number, '1'], [:number, '2']]))
      assert_true(evaluate([:forall, [x = ''], [[:number, x]], []]) {x.to_i != 0})
      assert_true(evaluate([:exists, [x = ''], [[:number, x]], []]) {x.to_i != 0})
    end

    def test_call
      # (* 1 2 3 4)
      assert_equal(24, call([:*, 1, 2, 3, 4]))
      assert_equal(24, evaluate([:call, :*, 1, 2, 3, 4]))
      # (= 5 (+ 2 3))
      assert_true(call([:==, 5, [:call, :+, 2, 3]]))
      assert_true(evaluate([:call, :==, 5, [:call, :+, 2, 3]]))
      # (= (+ 1 2 3) 6)
      assert_true(call([:==, [:call, :+, 1, 2, 3], 6]))
      assert_true(evaluate([:call, :==, [:call, :+, 1, 2, 3], 6]))
      # (= (+ a b c) abc)
      assert_true(call([:==, [:call, :+, 'a', 'b', 'c'], 'abc']))
      assert_true(evaluate([:call, :==, [:call, :+, 'a', 'b', 'c'], 'abc']))
    end

    def test_quantification_forall?
      # Variable x may assume any value from [1, 2, 3]
      @state = {:number => [['1'],['2'],['3']]}
      # For all numbers x, x != 0
      assert_true(forall?([x = ''], [[:number, x]], []) {x.to_i != 0})
      # For all numbers x, x != 1
      assert_false(forall?([x.clear], [[:number, x]], []) {x.to_i != 1})
      # For all numbers x, x == 4
      assert_false(forall?([x.clear], [[:number, x]], []) {x.to_i == 4})
      # For all numbers x, x is odd or even
      assert_true(forall?([x.clear], [[:number, x]], []) {x.to_i.odd? or x.to_i.even?})
    end

    def test_quantification_exists?
      # Variable x may assume any value from [1, 2, 3]
      @state = {:number => [['1'],['2'],['3']]}
      # There exists a number x, x != 0
      assert_true(exists?([x = ''], [[:number, x]], []) {x.to_i != 0})
      # There exists a number x, x != 1
      assert_true(exists?([x.clear], [[:number, x]], []) {x.to_i != 1})
      # There exists a number x, x == 4
      assert_false(exists?([x.clear], [[:number, x]], []) {x.to_i == 4})
      # There exists a number x, x is odd and even
      assert_false(exists?([x.clear], [[:number, x]], []) {x.to_i.odd? and x.to_i.even?})
    end
  end
end