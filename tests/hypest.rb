require 'test/unit'
require './Hype'

module Hypest

  def parser_tests(domain, problem, expected_parser, extensions, expected)
    Hype.parse(domain, problem)
    extensions.each {|e| Hype.extend(e)}
    parser = Hype.parser
    assert_equal(expected_parser, parser)
    expected.each {|att,value| assert_equal(value, parser.send(att))}
  end

  def compiler_tests(domain, problem, expected_parser, extensions, type, domain_expected, problem_expected)
    domain_type = "#{domain}.#{type}"
    problem_type = "#{problem}.#{type}"
    File.delete(domain_type) if File.exist?(domain_type)
    File.delete(problem_type) if File.exist?(problem_type)
    parser_tests(domain, problem, expected_parser, extensions, {})
    Hype.compile(domain, problem, type)
    if domain_expected
      assert_equal(true, File.exist?(domain_type))
      assert_equal(domain_expected, IO.read(domain_type))
    else assert_equal(false, File.exist?(domain_type))
    end
    if problem_expected
      assert_equal(true, File.exist?(problem_type))
      assert_equal(problem_expected, IO.read(problem_type))
    else assert_equal(false, File.exist?(problem_type))
    end
  ensure
    File.delete(domain_type) if domain_expected
    File.delete(problem_type) if problem_expected
  end
end