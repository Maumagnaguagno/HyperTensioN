require File.expand_path('../../../Hypertension', __FILE__)
include Hypertension

def forall?(precond_pos, precond_not, *free)
  generate(precond_pos, precond_not, *free) {return false unless yield}
  true
end

def exists?(precond_pos, precond_not, *free)
  generate(precond_pos, precond_not, *free) {return true if yield}
  false
end

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

# Conditional effects
puts 'Move briefcase and all its content, rotten cookie is left behind'
@state = {
  :at => [
    ['red_briefcase', 'a'],
    ['cookie', 'a'],
    ['rotten_cookie', 'a'],
    ['documents', 'a']
  ],
  :in => [
    ['cookie', 'red_briefcase'],
    ['rotten_cookie', 'thrash'],
    ['documents', 'red_briefcase']
  ]
}

def move_briefcase(briefcase, from, to)
  if applicable?(
    # Positive preconditions
    [[:at, briefcase, from]],
    # Negative preconditions
    [[:at, briefcase, to]]
  )
    # Primary effects
    add_effects = [[:at, briefcase, to]]
    del_effects = [[:at, briefcase, from]]
    # Conditional effects
    object = ''
    generate(
      # Positive preconditions
      [
        [:at, object, from],
        [:in, object, briefcase]
      ],
      # Negative preconditions
      [], object
    ) {
      obj_dup = object.dup
      add_effects << [:at, obj_dup, to]
      del_effects << [:at, obj_dup, from]
    }
    apply(add_effects, del_effects)
  end
end

p @state[:at]
move_briefcase('red_briefcase','a','b')
p @state[:at]