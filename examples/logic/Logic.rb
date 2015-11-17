require File.expand_path('../../../Hypertension', __FILE__)

module Logic
  include Hypertension
  extend self

  def forall?(precond_pos, precond_not, *free)
    generate(precond_pos, precond_not, *free) {return false unless yield}
    true
  end

  def exists?(precond_pos, precond_not, *free)
    generate(precond_pos, precond_not, *free) {return true if yield}
    false
  end
end

def not_zero?(x)
  x.to_i != 0
end

def not_one?(x)
  x.to_i != 1
end

def four?(x)
  x.to_i == 4
end

Logic.state = {:number => [['1'],['2'],['3']]}

x = ''
puts "For all numbers x, x != 0: #{Logic.forall?([[:number, x]], [], x) {not_zero?(x)}}"
x = ''
puts "For all numbers x, x != 1: #{Logic.forall?([[:number, x]], [], x) {not_one?(x)}}"
x = ''
puts "For all numbers x, x == 4: #{Logic.forall?([[:number, x]], [], x) {four?(x)}}"
x = ''
puts "For all numbers x, x is odd or even: #{Logic.forall?([[:number, x]], [], x) {x.to_i.odd? or x.to_i.even?}}"

x = ''
puts "There exists a number x, x != 0: #{Logic.exists?([[:number, x]], [], x) {not_zero?(x)}}"
x = ''
puts "There exists a number x, x != 1: #{Logic.exists?([[:number, x]], [], x) {not_one?(x)}}"
x = ''
puts "There exists a number x, x == 4: #{Logic.exists?([[:number, x]], [], x) {four?(x)}}"
x = ''
puts "There exists a number x, x is odd and even: #{Logic.exists?([[:number, x]], [], x) {x.to_i.odd? and x.to_i.even?}}"