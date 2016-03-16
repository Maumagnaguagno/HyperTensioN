require File.expand_path('../../../Hypertension', __FILE__)
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
  else
    name, *objs = precondition
    @state[name].include?(objs)
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  states = [
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
end