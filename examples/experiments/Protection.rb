module Protection

  def problem(state, *args)
    state[:protection_pos] = []
    state[:protection_not] = []
    super(state, *args)
  end

  def protect(protection_pos, protection_not)
    @state[:protection_pos].concat(protection_pos)
    @state[:protection_not].concat(protection_not)
  end

  def unprotect(protection_pos, protection_not)
    @state[:protection_pos] -= protection_pos
    @state[:protection_not] -= protection_not
  end

  def protected?(effect_add, effect_del)
    effect_add.any? {|pre| @state[:protection_not].include?(pre)} or effect_del.any? {|pre| @state[:protection_pos].include?(pre)}
  end

  def apply(effect_add, effect_del)
    super(effect_add, effect_del) unless protected?(effect_add, effect_del)
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

    def test_protection
      @state = {
        :pre => [['a'], ['b']],
        :protection_pos => [],
        :protection_not => []
      }
      protect([[:pre, 'a']], [[:pre, 'c']])
      assert_equal([['a'],['b']], @state[:pre])
      assert_equal([[:pre, 'a']], @state[:protection_pos])
      assert_equal([[:pre, 'c']], @state[:protection_not])
      assert_equal(false, protected?([], []))
      assert_equal(false, protected?([[:pre, 'a']], []))
      assert_equal(false, protected?([], [[:pre, 'c']]))
      assert_equal(true, protected?([], [[:pre, 'a']]))
      assert_equal(true, protected?([[:pre, 'c']], []))
      assert_equal(true, protected?([[:pre, 'c']], [[:pre, 'a']]))
      assert_equal(true, apply_operator([], [], [], []))
      assert_nil(apply_operator([], [], [], [[:pre, 'a']]))
      assert_nil(apply_operator([], [], [[:pre, 'c']], []))
      assert_equal([['a'],['b']], @state[:pre])
      assert_equal(true, apply_operator([], [], [[:pre, 'x']], [[:pre, 'b']]))
      assert_equal([['a'],['x']], @state[:pre])
      assert_nil(apply_operator([], [], [], [[:pre, 'a']]))
      assert_equal([[:pre, 'a']], @state[:protection_pos])
      assert_equal([[:pre, 'c']], @state[:protection_not])
      unprotect([[:pre, 'a']], [])
      assert_equal([], @state[:protection_pos])
      assert_equal([[:pre, 'c']], @state[:protection_not])
      assert_equal(true, apply_operator([], [], [], [[:pre, 'a']]))
      assert_equal([['x']], @state[:pre])
    end
  end
end