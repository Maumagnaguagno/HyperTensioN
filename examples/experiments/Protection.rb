require File.expand_path('../../../Hypertension', __FILE__)
include Hypertension

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
  effect_add.none? {|pro| @state[:protection_not].include?(pro)} and effect_del.none? {|pro| @state[:protection_pos].include?(objs)}
end

def apply_protected_operator(precond_pos, precond_not, effect_add, effect_del)
  # Apply operator unless interfere with protected
  apply_operator(precond_pos, precond_not, effect_add, effect_del) unless protected?(effect_add, effect_del)
end