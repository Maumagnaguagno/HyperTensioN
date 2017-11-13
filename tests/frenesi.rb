require './tests/hypest'

class Frenesi < Test::Unit::TestCase
  include Hypest

  #-----------------------------------------------
  # Extension
  #-----------------------------------------------

  def test_different_extensions
    e = assert_raises(RuntimeError) {Hype.parse('a.pddl','b.jshop')}
    assert_equal('Incompatible extensions between domain and problem', e.message)
  end

  def test_unknown_extension
    e = assert_raises(RuntimeError) {Hype.parse('a.blob','b.blob')}
    assert_equal('Unknown file extension .blob', e.message)
    e = assert_raises(RuntimeError) {Hype.parse('a','b')}
    assert_equal('Unknown file extension ', e.message)
  end

  end

  end
end