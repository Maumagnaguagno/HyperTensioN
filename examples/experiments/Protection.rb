#-----------------------------------------------
# Protection
#-----------------------------------------------

def setup_protection(protection_pos = [], protection_not = [])
  @state[:protection_pos] = protection_pos
  @state[:protection_not] = protection_not
end

def protect(protection_pos, protection_not)
  @state[:protection_pos].concat(protection_pos)
  @state[:protection_not].concat(protection_not)
end

def unprotect(protection_pos, protection_not)
  @state[:protection_pos] -= protection_pos
  @state[:protection_not] -= protection_not
end

def protected?(effect_add, effect_del)
  effect_add.any? {|pre| @state[:protection_not].include?(pre)} and effect_del.any? {|pre| @state[:protection_pos].include?(pre)}
end

def apply_protected_operator(precond_pos, precond_not, effect_add, effect_del)
  # Apply operator unless interfere with protected
  apply_operator(precond_pos, precond_not, effect_add, effect_del) unless protected?(effect_add, effect_del)
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  require_relative '../../Hypertension'
  include Hypertension

  @state = {:something => [['a'], ['b']]}
  setup_protection
  protect([[:something, 'a']], [[:something, 'c']])
  p @state
  p apply_protected_operator([], [], [[:something, 'c']], [[:something, 'a']])
  p @state
  p apply_protected_operator([], [], [[:something, 'x']], [[:something, 'b']])
  p @state
end