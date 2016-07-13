require_relative '../../Hypertension'
include Hypertension

#-----------------------------------------------
# Formula applicable?
#-----------------------------------------------

def formula_applicable?(precondition)
  case precondition.first
  when :and
    precondition.shift
    precondition.all? {|pre| formula_applicable?(pre)}
  when :or
    precondition.shift
    precondition.any? {|pre| formula_applicable?(pre)}
  when :xor
    precondition.shift
    precondition.one? {|pre| formula_applicable?(pre)}
  when :not
    precondition.shift
    precondition.none? {|pre| formula_applicable?(pre)}
  when :call
    call(precondition)
  else
    name, *objs = precondition
    @state[name].include?(objs)
  end
end

#-----------------------------------------------
# Call
#-----------------------------------------------

def call(expression)
  expression.shift
  f = expression.shift
  if (value = expression.shift).is_a?(Array)
    value = call(value)
  end
  if expression.empty?
    send(f, value)
  else
    expression.each {|i| value = value.send(f, i.is_a?(Array) && i.first == :call ? call(i) : i)}
    value
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  # (and (p a) (or (p b) (and (p c) (not p d)))) => true or false
  [
    [{:p => []}, false],

    [{:p => [[:a]]}, false],
    [{:p => [[:b]]}, false],
    [{:p => [[:c]]}, false],
    [{:p => [[:d]]}, false],

    [{:p => [[:a],[:b]]}, true],
    [{:p => [[:a],[:c]]}, true],
    [{:p => [[:a],[:d]]}, false],
    [{:p => [[:b],[:c]]}, false],
    [{:p => [[:b],[:d]]}, false],
    [{:p => [[:c],[:d]]}, false],

    [{:p => [[:a],[:b],[:c]]}, true],
    [{:p => [[:a],[:b],[:d]]}, true],
    [{:p => [[:a],[:c],[:d]]}, false],
    [{:p => [[:b],[:c],[:d]]}, false],

    [{:p => [[:a],[:b],[:c],[:d]]}, true]
  ].each {|s,expected|
    @state = s
    p formula_applicable?(
      [:and,
        [:p, :a],
        [:or,
          [:p, :b],
          [:and,
            [:p, :c],
            [:not, [:p, :d]]
          ]
        ]
      ]
    ) == expected
  }
  # (= 5 (+ 2 3))
  p call([:call, '==', 5, [:call, '+', 2, 3]])
  # (= (+ 1 2 3) 6)
  p call([:call, '==', [:call, '+', 1, 2, 3], 6])
  # (= (+ a b c) abc)
  p call([:call, '==', [:call, '+', 'a', 'b', 'c'], 'abc'])
end