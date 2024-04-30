require './tests/hypest'

class Polyglot < Test::Unit::TestCase

  def intermediate_representation(parser)
    [
      parser.domain_name,
      parser.problem_name,
      parser.operators,
      parser.methods,
      parser.predicates,
      parser.state,
      parser.tasks,
      parser.goal_pos,
      parser.goal_not
    ]
  end

  def compile(ir)
    expected = Marshal.load(Marshal.dump(ir))
    [
      Hyper_Compiler,
      Cyber_Compiler,
      JSHOP_Compiler,
      HDDL_Compiler,
      PDDL_Compiler,
      Dot_Compiler,
      Markdown_Compiler
    ].each {|compiler|
      next if compiler == Cyber_Compiler and not ir[6][0]
      compiler.compile_domain(*ir)
      compiler.compile_problem(*ir, nil)
      assert_equal(expected, ir)
    }
  end

  def test_basic_pb1_pddl_compilation
    PDDL_Parser.parse_domain('examples/basic/basic.pddl')
    PDDL_Parser.parse_problem('examples/basic/pb1.pddl')
    compile(intermediate_representation(PDDL_Parser))
  end

  def test_basic_pb1_hddl_compilation
    HDDL_Parser.parse_domain('examples/basic/basic.hddl')
    HDDL_Parser.parse_problem('examples/basic/pb1.hddl')
    compile(intermediate_representation(HDDL_Parser))
  end

  def test_basic_pb1_jshop_compilation
    JSHOP_Parser.parse_domain('examples/basic/basic.jshop')
    JSHOP_Parser.parse_problem('examples/basic/pb1.jshop')
    compile(intermediate_representation(JSHOP_Parser))
  end

  def test_tsp_pb1_pddl_compilation
    PDDL_Parser.parse_domain('examples/tsp/tsp.pddl')
    PDDL_Parser.parse_problem('examples/tsp/pb1.pddl')
    compile(ir = intermediate_representation(PDDL_Parser))
    Patterns.apply(*ir.drop(2))
    compile(ir)
  end
end