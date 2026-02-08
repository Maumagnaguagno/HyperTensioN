module Protection

  def problem(state, *args)
    @protection_pos = state.size
    @protection_not = @protection_pos + 1
    state.push([], [])
    super
  end

  def protect(protection_pos, protection_not)
    @state[@protection_pos] += protection_pos
    @state[@protection_not] += protection_not
  end

  def unprotect(protection_pos, protection_not)
    @state[@protection_pos] -= protection_pos
    @state[@protection_not] -= protection_not
  end

  def protected?(effect_add, effect_del)
    @state[@protection_not].intersect?(effect_add) or @state[@protection_pos].intersect?(effect_del)
  end

  def apply(effect_add, effect_del)
    super unless protected?(effect_add, effect_del)
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  require 'test/unit'
  require_relative '../../Hypertension'

  class Protect < Test::Unit::TestCase
    include Protection, Hypertension

    PRE = 0

    def test_protection
      @state = []
      @protection_pos = 1
      @protection_not = 2
      @state[PRE] = [[:a], [:b]]
      @state[@protection_pos] = []
      @state[@protection_not] = []
      protect([[PRE, :a]], [[PRE, :c]])
      assert_equal([[:a],[:b]], @state[PRE])
      assert_equal([[PRE, :a]], @state[@protection_pos])
      assert_equal([[PRE, :c]], @state[@protection_not])
      assert_false(protected?([], []))
      assert_false(protected?([[PRE, :a]], []))
      assert_false(protected?([], [[PRE, :c]]))
      assert_true(protected?([], [[PRE, :a]]))
      assert_true(protected?([[PRE, :c]], []))
      assert_true(protected?([[PRE, :c]], [[PRE, :a]]))
      assert_true(apply_operator([], [], [], []))
      assert_nil(apply_operator([], [], [], [[PRE, :a]]))
      assert_nil(apply_operator([], [], [[PRE, :c]], []))
      assert_equal([[:a],[:b]], @state[PRE])
      assert_true(apply_operator([], [], [[PRE, :x]], [[PRE, :b]]))
      assert_equal([[:a],[:x]], @state[PRE])
      assert_nil(apply_operator([], [], [], [[PRE, :a]]))
      assert_equal([[PRE, :a]], @state[@protection_pos])
      assert_equal([[PRE, :c]], @state[@protection_not])
      unprotect([[PRE, :a]], [])
      assert_equal([], @state[@protection_pos])
      assert_equal([[PRE, :c]], @state[@protection_not])
      assert_true(apply_operator([], [], [], [[PRE, :a]]))
      assert_equal([[:x]], @state[PRE])
    end
  end
end