require 'test/unit'
require 'stringio'
require './Hypertension'

# Output supressed
module Hypertension
  extend self

  alias_method :loud_problem, :problem

  def problem(*args)
    $stdout = StringIO.new
    loud_problem(*args)
  ensure
    $stdout = STDOUT
  end
end

class Samples < Test::Unit::TestCase

  #-----------------------------------------------
  # Travel
  #-----------------------------------------------

  def test_travel_pb1
    require './examples/travel/pb1'
    assert_equal([['walk', 'me', 'home', 'park']], Travel.plan)
  end

  def test_travel_pb2
    require './examples/travel/pb2'
    assert_equal([['walk', 'me', 'home', 'friend']], Travel.plan)
  end

  def test_travel_pb3
    require './examples/travel/pb3'
    assert_equal([], Travel.plan)
  end

  def test_travel_pb4
    require './examples/travel/pb4'
    expected = [
      ['walk', 'me', 'home', 'friend'],
      ['walk', 'me', 'friend', 'park']
    ]
    assert_equal(expected, Travel.plan)
  end

  #-----------------------------------------------
  # Robby
  #-----------------------------------------------

  def test_robby_pb1
    require './examples/robby/pb1'
    expected = [
      ['move', 'robby', 'left', 'middle'],
      ['enter', 'robby', 'middle', 'room1'],
      ['report', 'robby', 'room1', 'beacon1'],
      ['exit', 'robby', 'room1', 'middle'],
      ['move', 'robby', 'middle', 'right']
    ]
    assert_equal(expected, Robby.plan)
  end

  #-----------------------------------------------
  # Goldminer
  #-----------------------------------------------

  def test_goldminer_pb1
    require './examples/goldminer/pb1'
    expected = [
      ['move', 'ag1', 'p1_6', 'p1_5'],
      ['move', 'ag1', 'p1_5', 'p1_4'],
      ['move', 'ag1', 'p1_4', 'p1_3'],
      ['move', 'ag1', 'p1_3', 'p1_2'],
      ['move', 'ag1', 'p1_2', 'p0_2'],
      ['move', 'ag1', 'p0_2', 'p0_1'],
      ['move', 'ag1', 'p0_1', 'p0_0'],
      ['move', 'ag1', 'p0_0', 'p1_0'],
      ['move', 'ag1', 'p1_0', 'p2_0'],
      ['move', 'ag1', 'p2_0', 'p3_0'],
      ['move', 'ag1', 'p3_0', 'p4_0'],
      ['pick', 'ag1', 'g1', 'p4_0'],
      ['move', 'ag1', 'p4_0', 'p5_0'],
      ['move', 'ag1', 'p5_0', 'p6_0'],
      ['move', 'ag1', 'p6_0', 'p7_0'],
      ['move', 'ag1', 'p7_0', 'p8_0'],
      ['move', 'ag1', 'p8_0', 'p9_0'],
      ['move', 'ag1', 'p9_0', 'p9_1'],
      ['move', 'ag1', 'p9_1', 'p9_2'],
      ['move', 'ag1', 'p9_2', 'p8_2'],
      ['move', 'ag1', 'p8_2', 'p8_3'],
      ['move', 'ag1', 'p8_3', 'p8_4'],
      ['move', 'ag1', 'p8_4', 'p8_5'],
      ['move', 'ag1', 'p8_5', 'p8_6'],
      ['drop', 'ag1', 'g1', 'p8_6'],
      ['move', 'ag1', 'p8_6', 'p8_5'],
      ['move', 'ag1', 'p8_5', 'p8_4'],
      ['move', 'ag1', 'p8_4', 'p8_3'],
      ['move', 'ag1', 'p8_3', 'p7_3'],
      ['move', 'ag1', 'p7_3', 'p6_3'],
      ['move', 'ag1', 'p6_3', 'p5_3'],
      ['move', 'ag1', 'p5_3', 'p4_3'],
      ['pick', 'ag1', 'g2', 'p4_3'],
      ['move', 'ag1', 'p4_3', 'p5_3'],
      ['move', 'ag1', 'p5_3', 'p6_3'],
      ['move', 'ag1', 'p6_3', 'p7_3'],
      ['move', 'ag1', 'p7_3', 'p8_3'],
      ['move', 'ag1', 'p8_3', 'p8_4'],
      ['move', 'ag1', 'p8_4', 'p8_5'],
      ['move', 'ag1', 'p8_5', 'p8_6'],
      ['drop', 'ag1', 'g2', 'p8_6'],
      ['move', 'ag1', 'p8_6', 'p8_5'],
      ['move', 'ag1', 'p8_5', 'p7_5'],
      ['move', 'ag1', 'p7_5', 'p6_5'],
      ['move', 'ag1', 'p6_5', 'p5_5'],
      ['move', 'ag1', 'p5_5', 'p5_6'],
      ['move', 'ag1', 'p5_6', 'p5_7'],
      ['move', 'ag1', 'p5_7', 'p5_8'],
      ['move', 'ag1', 'p5_8', 'p5_9'],
      ['pick', 'ag1', 'g3', 'p5_9'],
      ['move', 'ag1', 'p5_9', 'p5_8'],
      ['move', 'ag1', 'p5_8', 'p5_7'],
      ['move', 'ag1', 'p5_7', 'p5_6'],
      ['move', 'ag1', 'p5_6', 'p5_5'],
      ['move', 'ag1', 'p5_5', 'p6_5'],
      ['move', 'ag1', 'p6_5', 'p7_5'],
      ['move', 'ag1', 'p7_5', 'p8_5'],
      ['move', 'ag1', 'p8_5', 'p8_6'],
      ['drop', 'ag1', 'g3', 'p8_6']
    ]
    assert_equal(expected, Goldminer.plan)
  end
end