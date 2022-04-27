require 'test/unit'
require './Hype'

module Hypest

  def parser_tests(domain, problem, parser, extensions, expected)
    Hype.parse(domain, problem)
    extensions.each {|e| Hype.extend(e)}
    expected.each {|att,value| assert_equal(value, parser.send(att))}
  end

  def compiler_tests(domain, problem, parser, extensions, type, domain_expected, problem_expected)
    domain_type = "#{domain}.#{type}"
    problem_type = "#{problem}.#{type}"
    File.delete(domain_type) if File.exist?(domain_type)
    File.delete(problem_type) if File.exist?(problem_type)
    parser_tests(domain, problem, parser, extensions, {})
    Hype.compile(domain, problem, type)
    if domain_expected
      assert_true(File.exist?(domain_type))
      assert_equal(domain_expected, IO.read(domain_type))
    else assert_false(File.exist?(domain_type))
    end
    if problem_expected
      assert_true(File.exist?(problem_type))
      assert_equal(problem_expected, IO.read(problem_type))
    else assert_false(File.exist?(problem_type))
    end
  ensure
    File.delete(domain_type) if File.exist?(domain_type)
    File.delete(problem_type) if File.exist?(problem_type)
  end
end