require './tests/hypest'

class Markup < Test::Unit::TestCase
  include Hypest

  def test_basic_pb1_jshop_parsing_compile_to_markdown
    compiler_tests(
      # Files
      'examples/basic/basic.jshop',
      'examples/basic/pb1.jshop',
      # Parser, extensions and output
      JSHOP_Parser, [], 'md',
      # Domain
'# Basic
## Predicates
- **have**: mutable

## Operators
Pickup | ?a
--- | ---
***Preconditions*** | ***Effects***
|| (have ?a)

Drop | ?a
--- | ---
***Preconditions*** | ***Effects***
(have ?a) | **not** (have ?a)

## Methods
Swap | ?x ?y ||
--- | --- | ---
***Label*** | ***Preconditions*** | ***Subtasks***
case_0 ||
|| (have ?x) | drop ?x
|| **not** (have ?y) | pickup ?y
case_1 ||
|| (have ?y) | drop ?y
|| **not** (have ?x) | pickup ?x',
      # Problem
'# Pb1 of Basic
## Initial state
- (have kiwi)

## Tasks
**ordered**
- (swap banjo kiwi)'
    )
  end
end