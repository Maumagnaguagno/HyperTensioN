require 'test/unit'
require './Hype'

module Hypest

  def parser_tests(domain, problem, parser, extensions, expected)
    Hype.parse(domain, problem)
    extensions.each {|e| Hype.extend(e)}
    expected.each {|att,value| assert_equal(value, parser.send(att))}
  end

  def compiler_tests(domain, problem, extensions, type, domain_expected, problem_expected)
    domain_type = "#{domain}.#{type}"
    problem_type = "#{problem}.#{type}"
    File.delete(domain_type) if File.exist?(domain_type)
    File.delete(problem_type) if File.exist?(problem_type)
    Hype.parse(domain, problem)
    extensions.each {|e| Hype.extend(e)}
    Hype.compile(domain, problem, type)
    if domain_expected
      assert_true(File.exist?(domain_type))
      assert_equal(domain_expected, File.read(domain_type))
    else assert_false(File.exist?(domain_type))
    end
    if problem_expected
      assert_true(File.exist?(problem_type))
      assert_equal(problem_expected, File.read(problem_type))
    else assert_false(File.exist?(problem_type))
    end
  ensure
    File.delete(domain_type) if File.exist?(domain_type)
    File.delete(problem_type) if File.exist?(problem_type)
  end

  def interpreted_execution_tests(domain, problem, script, output_expected)
    assert_true(`ruby #{script} #{domain} #{problem} run`.include?(output_expected))
  end

  def native_execution_tests(domain, problem, compiler, output_expected)
    domain_type = "#{domain}.cpp"
    domain_bin = "#{domain}.bin"
    File.delete(domain_type) if File.exist?(domain_type)
    File.delete(domain_bin) if File.exist?(domain_bin)
    Hype.parse(domain, problem)
    Hype.compile(domain, problem, 'cpp')
    system("#{compiler} #{domain_type} -o #{domain_bin}")
    assert_equal(output_expected, `./#{domain_bin}`)
  ensure
    File.delete(domain_type) if File.exist?(domain_type)
    File.delete(domain_bin) if File.exist?(domain_bin)
  end
end