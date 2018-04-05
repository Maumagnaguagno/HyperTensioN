require_relative '../../Hypertension'

module Hypertension

  alias original_problem problem

  def problem(start, *args)
    start[:protection_pos] = []
    start[:protection_not] = []
    original_problem(start, *args)
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
    effect_add.any? {|pre| @state[:protection_not].include?(pre)} and effect_del.any? {|pre| @state[:protection_pos].include?(pre)}
  end

  alias original_apply apply

  def apply(effect_add, effect_del)
    original_apply(effect_add, effect_del) unless protected?(effect_add, effect_del)
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  require 'test/unit'

  class Protection < Test::Unit::TestCase
    include Hypertension

    def test_protection
      @state = {
        :something => [['a'], ['b']],
        :protection_pos => [],
        :protection_not => []
      }
      assert_equal([['a'],['b']], @state[:something])
      assert_equal([], @state[:protection_pos])
      assert_equal([], @state[:protection_not])
      protect([[:something, 'a']], [[:something, 'c']])
      assert_equal([['a'],['b']], @state[:something])
      assert_equal([[:something, 'a']], @state[:protection_pos])
      assert_equal([[:something, 'c']], @state[:protection_not])
      assert_nil(apply_operator([], [], [[:something, 'c']], [[:something, 'a']]))
      assert_equal([['a'],['b']], @state[:something])
      assert_equal(true, apply_operator([], [], [[:something, 'x']], [[:something, 'b']]))
      assert_equal([['a'],['x']], @state[:something])
    end
  end
end