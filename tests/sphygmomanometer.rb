require 'test/unit'
require './examples/n_queens/N_Queens'

class Sphygmomanometer < Test::Unit::TestCase

  def simple_state
    {
      'a' => [['1'], ['2'], ['3']],
      'b' => [['3'], ['4'], ['5']],
      'c' => [['a','b'], ['c','d']],
      'd' => [['d','x']]
    }
  end

  def test_attributes
    [:domain, :domain=, :state, :state=, :debug, :debug=].each {|att| assert_respond_to(Hypertension, att)}
  end

  #-----------------------------------------------
  # Planning
  #-----------------------------------------------

  def test_planning_empty
    Hypertension.state = original_state = simple_state
    Hypertension.domain = {}
    assert_equal([], Hypertension.planning([]))
    # No state was created
    assert_same(original_state, Hypertension.state)
  end

  def test_planning_success
    expected_plan = [
      [:put_piece, 0, 7],
      [:put_piece, 4, 6],
      [:put_piece, 7, 5],
      [:put_piece, 5, 4],
      [:put_piece, 2, 3],
      [:put_piece, 6, 2],
      [:put_piece, 1, 1],
      [:put_piece, 3, 0]
    ]
    assert_equal(expected_plan, N_Queens.solve(8, false, false))
    # Expected state
    assert_equal({:queen => expected_plan.each {|i| i.shift}, :free_collumn => []}, N_Queens.state)
  end

  def test_planning_failure
    N_Queens.solve(8, false, false)
    assert_nil(N_Queens.planning([[:solve,1]]))
  end

  def test_planning_exception
    Hypertension.state = simple_state
    Hypertension.domain = {}
    e = assert_raises(RuntimeError) {Hypertension.planning([['exception_rise']])}
    assert_equal('Domain defines no decomposition for exception_rise', e.message)
  end

  #-----------------------------------------------
  # Generate
  #-----------------------------------------------

  def test_generate
    expected = ['1','2','3'].product(['4','5'], ['c'], ['d'])
    Hypertension.state = simple_state
    # Free variables
    x = ''
    y = ''
    w = ''
    z = ''
    # Generate x y w z based on state and preconditions
    Hypertension.generate(
      [
        ['a', x],
        ['b', y],
        ['c', w, z],
        ['d', z, 'x']
      ],
      [
        ['a', y]
      ], x, y, w, z
    ) {
      assert_equal(expected.shift, [x,y,w,z])
    }
    assert_equal(true, expected.empty?)
  end

  def test_generate_exist
    expected = ['1','2','3'].product(['4'], ['c'], ['d'])
    Hypertension.state = simple_state
    # Free variables
    x = ''
    y = ''
    w = ''
    z = ''
    # Generate x y w z based on state and preconditions
    exist_y = nil # One unification of y is enough
    Hypertension.generate(
      [
        ['a', x],
        ['b', y],
        ['c', w, z],
        ['d', z, 'x']
      ],
      [
        ['a', y]
      ], y, x, w, z # Sort exist variables
    ) {
      break if (exist_y ||= y.dup) != y
      assert_equal(expected.shift, [x,y,w,z])
    }
    assert_equal(true, expected.empty?)
  end

  #-----------------------------------------------
  # Applicable?
  #-----------------------------------------------

  def test_applicable_empty
    Hypertension.state = original_state = simple_state
    assert_equal(true, Hypertension.applicable?([],[]))
    # No state was created
    assert_same(original_state, Hypertension.state)
  end

  def test_applicable_success
    Hypertension.state = original_state = simple_state
    assert_equal(true, Hypertension.applicable?([['a','1']],[['a','x']]))
    # No state was created
    assert_same(original_state, Hypertension.state)
  end

  def test_applicable_failure
    Hypertension.state = original_state = simple_state
    assert_equal(false, Hypertension.applicable?([['a','1']],[['a','2']]))
    # No state was created
    assert_same(original_state, Hypertension.state)
  end

  #-----------------------------------------------
  # Apply
  #-----------------------------------------------

  def test_apply_empty_effects
    Hypertension.state = original_state = simple_state
    # Successfully applied
    assert_equal(true, Hypertension.apply([],[]))
    # New state was created
    assert_not_same(original_state, Hypertension.state)
    # Same content
    assert_equal(original_state, Hypertension.state)
  end

  def test_apply_success
    Hypertension.state = original_state = simple_state
    # Successfully applied
    assert_equal(true, Hypertension.apply([['a','y']],[['a','y']]))
    # New state was created
    assert_not_same(original_state, Hypertension.state)
    # Delete effects must happen before addition, otherwise the effect nullifies itself
    expected = simple_state
    expected['a'] << ['y']
    assert_equal(expected, Hypertension.state)
  end

  #-----------------------------------------------
  # Apply operator
  #-----------------------------------------------

  def test_apply_operator_empty_effects
    Hypertension.state = original_state = simple_state
    # Successfully applied
    assert_equal(true, Hypertension.apply_operator([['a','1']],[['a','x']],[],[]))
    # New state was created
    assert_not_same(original_state, Hypertension.state)
    # Same content
    assert_equal(original_state, Hypertension.state)
  end

  def test_apply_operator_success
    Hypertension.state = original_state = simple_state
    # Successfully applied
    assert_equal(true, Hypertension.apply_operator([['a','1']],[['a','x']],[['a','y']],[['a','y']]))
    # New state was created
    assert_not_same(original_state, Hypertension.state)
    # Delete effects must happen before addition, otherwise the effect nullifies itself
    expected = simple_state
    expected['a'] << ['y']
    assert_equal(expected, Hypertension.state)
  end

  def test_apply_operator_failure
    Hypertension.state = original_state = simple_state
    # Precondition failure
    assert_nil(Hypertension.apply_operator([],[['a','2']],[['a','y']],[]))
    # No state was created
    assert_same(original_state, Hypertension.state)
  end
end