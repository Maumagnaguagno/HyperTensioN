require File.expand_path('../../../Hypertension', __FILE__)
include Hypertension

# Side-effects
puts 'Move briefcase and all its contents as a side-effect while rotten cookie is left behind'
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
    # Side-effects
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
    # Apply effect only once, avoid intermediary state creation
    apply(add_effects, del_effects)
  end
end

p @state[:at]
move_briefcase('red_briefcase','a','b')
p @state[:at]