module Protection

  if defined?(Hypertension_U)
    PROTECTION_POS = :protection_pos
    PROTECTION_NOT = :protection_not
  else
    PROTECTION_POS = -2
    PROTECTION_NOT = -1
  end

  def problem(state, *args)
    if defined?(Hypertension_U)
      state[PROTECTION_POS] = []
      state[PROTECTION_NOT] = []
    else state.push([], [])
    end
    super
  end

  def protect(protection_pos, protection_not)
    @state[PROTECTION_POS].concat(protection_pos)
    @state[PROTECTION_NOT].concat(protection_not)
  end

  def unprotect(protection_pos, protection_not)
    @state[PROTECTION_POS] -= protection_pos
    @state[PROTECTION_NOT] -= protection_not
  end

  def protected?(effect_add, effect_del)
    effect_add.any? {|pre| @state[PROTECTION_NOT].include?(pre)} or effect_del.any? {|pre| @state[PROTECTION_POS].include?(pre)}
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
      if defined?(Hypertension_U)
        @state = {
          :pre => [['a'], ['b']],
          :protection_pos => [],
          :protection_not => []
        }
      else
        @state = [
          [['a'], ['b']],
          [],
          []
        ]
      end
      protect([[PRE, 'a']], [[PRE, 'c']])
      assert_equal([['a'],['b']], @state[PRE])
      assert_equal([[PRE, 'a']], @state[PROTECTION_POS])
      assert_equal([[PRE, 'c']], @state[PROTECTION_NOT])
      assert_equal(false, protected?([], []))
      assert_equal(false, protected?([[PRE, 'a']], []))
      assert_equal(false, protected?([], [[PRE, 'c']]))
      assert_equal(true, protected?([], [[PRE, 'a']]))
      assert_equal(true, protected?([[PRE, 'c']], []))
      assert_equal(true, protected?([[PRE, 'c']], [[PRE, 'a']]))
      assert_equal(true, apply_operator([], [], [], []))
      assert_nil(apply_operator([], [], [], [[PRE, 'a']]))
      assert_nil(apply_operator([], [], [[PRE, 'c']], []))
      assert_equal([['a'],['b']], @state[PRE])
      assert_equal(true, apply_operator([], [], [[PRE, 'x']], [[PRE, 'b']]))
      assert_equal([['a'],['x']], @state[PRE])
      assert_nil(apply_operator([], [], [], [[PRE, 'a']]))
      assert_equal([[PRE, 'a']], @state[PROTECTION_POS])
      assert_equal([[PRE, 'c']], @state[PROTECTION_NOT])
      unprotect([[PRE, 'a']], [])
      assert_equal([], @state[PROTECTION_POS])
      assert_equal([[PRE, 'c']], @state[PROTECTION_NOT])
      assert_equal(true, apply_operator([], [], [], [[PRE, 'a']]))
      assert_equal([['x']], @state[PRE])
    end
  end
end