require 'test/unit'
require './Hype'

class Frenesi < Test::Unit::TestCase

  #-----------------------------------------------
  # Exception
  #-----------------------------------------------

  def test_different_file_extension_exception
    e = assert_raises(RuntimeError) {Hype.parse('a.pddl','b.jshop')}
    assert_equal('Incompatible extensions between domain and problem', e.message)
  end

  def test_unknown_file_extension_exception
    e = assert_raises(RuntimeError) {Hype.parse('a.blob','b.blob')}
    assert_equal('Unknown file extension .blob', e.message)
    e = assert_raises(RuntimeError) {Hype.parse('a','b')}
    assert_equal('Unknown file extension ', e.message)
  end

  def test_unknown_extension_exception
    e = assert_raises(RuntimeError) {Hype.extend('blob')}
    assert_equal('Unknown extension blob', e.message)
  end

  def test_unknown_compiler_exception
    e = assert_raises(RuntimeError) {Hype.compile('a.blob','b.blob','blob')}
    assert_equal('Unknown type blob', e.message)
  end
end