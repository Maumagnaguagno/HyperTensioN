require_relative '../../Hypertension'
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
# Main
#-----------------------------------------------
if $0 == __FILE__
  puts 'variable x may assume any value from set {1,2,3}'
  x = ''
  @state = {:number => [['1'],['2'],['3']]}

  # Query forall
  puts "For all numbers x, x != 0: #{forall?([[:number, x]], [], x) {x.to_i != 0}}"
  puts "For all numbers x, x != 1: #{forall?([[:number, x]], [], x.clear) {x.to_i != 1}}"
  puts "For all numbers x, x == 4: #{forall?([[:number, x]], [], x.clear) {x.to_i == 4}}"
  puts "For all numbers x, x is odd or even: #{forall?([[:number, x]], [], x.clear) {x.to_i.odd? or x.to_i.even?}}"

  # Query exists
  puts "There exists a number x, x != 0: #{exists?([[:number, x]], [], x.clear) {x.to_i != 0}}"
  puts "There exists a number x, x != 1: #{exists?([[:number, x]], [], x.clear) {x.to_i != 1}}"
  puts "There exists a number x, x == 4: #{exists?([[:number, x]], [], x.clear) {x.to_i == 4}}"
  puts "There exists a number x, x is odd and even: #{exists?([[:number, x]], [], x.clear) {x.to_i.odd? and x.to_i.even?}}"
end