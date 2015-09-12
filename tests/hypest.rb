require 'test/unit'
require './Hype'

class Hypest < Test::Unit::TestCase

  def parser_tests(domain, problem, expected_parser, execute_patterns, expected)
    Hype.parse(domain, problem)
    parser = Hype.parser
    if execute_patterns
      Patterns.match(
        parser.operators,
        parser.methods,
        parser.predicates,
        parser.tasks,
        parser.goal_pos,
        parser.goal_not
      )
    end
    assert_equal(expected_parser, parser)
    expected.each {|att,value| assert_equal(value, parser.send(att))}
  end

  def compiler_tests(domain, problem, expected_parser, execute_patterns, type, expected_domain, expected_problem)
    domain_type = "#{domain}.#{type}"
    problem_type = "#{problem}.#{type}"
    File.delete(domain_type) if File.exist?(domain_type)
    File.delete(problem_type) if File.exist?(problem_type)
    parser_tests(domain, problem, expected_parser, execute_patterns, {})
    Hype.compile(domain, problem, type)
    assert_equal(true, File.exist?(domain_type))
    assert_equal(true, File.exist?(problem_type))
    domain_generated = IO.read(domain_type)
    problem_generated = IO.read(problem_type)
    assert_equal(expected_domain, domain_generated)
    assert_equal(expected_problem, problem_generated)
    File.delete(domain_type, problem_type)
  end
end