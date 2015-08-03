require 'test/unit'
require './examples/n_queens/N_Queens'

class Sphygmomanometer < Test::Unit::TestCase

  def simple_state
    {
      'a' => [['1'], ['2'], ['3']],
      'b' => [['4'], ['5']],
      'c' => [['a','b'], ['c','d']]
    }
  end

  def test_attributes
    ['domain', 'state', 'debug'].each {|att|
      assert_respond_to(Hypertension, att)
      assert_respond_to(Hypertension, "#{att}=")
    }
  end

  def test_planning
    expected_plan = [
      ['put_piece', '0', '7'],
      ['put_piece', '4', '6'],
      ['put_piece', '7', '5'],
      ['put_piece', '5', '4'],
      ['put_piece', '2', '3'],
      ['put_piece', '6', '2'],
      ['put_piece', '1', '1'],
      ['put_piece', '3', '0']
    ]
    assert_equal(expected_plan, N_Queens.solve(8, false, false))
    # Expected state
    expected_plan.each {|i| i.shift}
    assert_equal({'queen' => expected_plan, 'free_collumn' => []}, N_Queens.state)
  end

  def test_generate
    Hypertension.state = simple_state
    # Pointers
    x = ''
    y = ''
    z = ''
    # Generate x y z based on state and preconditions
    generated = []
    Hypertension.generate(
      [
        ['a', x],
        ['b', y],
        ['c', z, 'd']
      ],
      [], x, y, z
    ) {
      # Save a copy of pointer values
      generated << [x.dup, y.dup, z.dup]
    }
    # Compare with expected
    expected = ['1','2','3'].product(['4','5'], ['c'])
    assert_equal(expected, generated)
  end

  def test_apply_operator_null
    Hypertension.state = original_state = simple_state
    # Successfully applied
    assert_equal(true, Hypertension.apply_operator([['a','1']],[['a','x']],[],[]))
    # New state was created
    assert_equal(false, original_state.equal?(Hypertension.state))
    # Same content
    assert_equal(true, original_state == Hypertension.state)
  end

  def test_apply_operator_success
    Hypertension.state = original_state = simple_state
    # Successfully applied
    assert_equal(true, Hypertension.apply_operator([['a','1']],[['a','x']],[['a','y']],[['a','y']]))
    # New state was created
    assert_equal(false, original_state.equal?(Hypertension.state))
    # Delete effects must happen before addition, otherwise the effect nullifies itself
    expected = simple_state
    expected['a'] << ['y']
    assert_equal(expected, Hypertension.state)
  end

  def test_apply_operator_failure
    Hypertension.state = original_state = simple_state
    # Successfully applied
    assert_equal(nil, Hypertension.apply_operator([],[['a','2']],[['a','y']],[]))
    # No state was created
    assert_equal(true, original_state.equal?(Hypertension.state))
  end

  def test_applicable_empty
    Hypertension.state = original_state = simple_state
    assert_equal(true, Hypertension.applicable?([],[]))
    # No state was created
    assert_equal(true, original_state.equal?(Hypertension.state))
  end

  def test_applicable_success
    Hypertension.state = original_state = simple_state
    assert_equal(true, Hypertension.applicable?([['a','1']],[['a','x']]))
    # No state was created
    assert_equal(true, original_state.equal?(Hypertension.state))
  end

  def test_applicable_failure
    Hypertension.state = original_state = simple_state
    assert_equal(false, Hypertension.applicable?([['a','1']],[['a','2']]))
    # No state was created
    assert_equal(true, original_state.equal?(Hypertension.state))
  end
end
