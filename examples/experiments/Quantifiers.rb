require File.expand_path('../../../Hypertension', __FILE__)
include Hypertension

#-----------------------------------------------
# Quantifiers
#-----------------------------------------------

def forall?(precond_pos, precond_not, *free)
  # Try all calls
  generate(precond_pos, precond_not, *free) {return false unless yield}
  true
end

def exists?(precond_pos, precond_not, *free)
  # Try until first call succeed
  generate(precond_pos, precond_not, *free) {return true if yield}
  false
end

#-----------------------------------------------
# Examples
#-----------------------------------------------

@state = {:number => [['1'],['2'],['3']]}

# Verbose methods
def not_zero?(x)
  x.to_i != 0
end

def not_one?(x)
  x.to_i != 1
end

def four?(x)
  x.to_i == 4
end

# Query forall
x = ''
puts "For all numbers x, x != 0: #{forall?([[:number, x]], [], x) {not_zero?(x)}}"
x = ''
puts "For all numbers x, x != 1: #{forall?([[:number, x]], [], x) {not_one?(x)}}"
x = ''
puts "For all numbers x, x == 4: #{forall?([[:number, x]], [], x) {four?(x)}}"
x = ''
puts "For all numbers x, x is odd or even: #{forall?([[:number, x]], [], x) {x.to_i.odd? or x.to_i.even?}}"

# Query exists
x = ''
puts "There exists a number x, x != 0: #{exists?([[:number, x]], [], x) {not_zero?(x)}}"
x = ''
puts "There exists a number x, x != 1: #{exists?([[:number, x]], [], x) {not_one?(x)}}"
x = ''
puts "There exists a number x, x == 4: #{exists?([[:number, x]], [], x) {four?(x)}}"
x = ''
puts "There exists a number x, x is odd and even: #{exists?([[:number, x]], [], x) {x.to_i.odd? and x.to_i.even?}}"