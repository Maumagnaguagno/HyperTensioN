#-----------------------------------------------
# Apply operator with side effects
#-----------------------------------------------

def apply_operator_with_side_effects(precond_pos, precond_not, effect_add, effect_del, side_precond_pos, side_precond_not, *free, &block)
  if applicable?(precond_pos, precond_not)
    # Side-effects
    generate(side_precond_pos, side_precond_not, *free, &block)
    # Apply effect only once, avoid intermediate state creation
    apply(effect_add, effect_del)
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  require 'test/unit'
  require_relative '../../Hypertension'

  class Side_Effects < Test::Unit::TestCase
    include Hypertension

    def move_briefcase(briefcase, from, to)
      if applicable?(
        # Positive preconditions
        [[:at, briefcase, from]],
        # Negative preconditions
        [[:at, briefcase, to]]
      )
        # Effects
        effect_add = [[:at, briefcase, to]]
        effect_del = [[:at, briefcase, from]]
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
          effect_add << [:at, obj_dup, to]
          effect_del << [:at, obj_dup, from]
        }
        # Apply effect only once to avoid intermediate state creation
        apply(effect_add, effect_del)
      end
    end

    def move_briefcase_with_side_effects(briefcase, from, to)
      object = ''
      effect_add = [[:at, briefcase, to]]
      effect_del = [[:at, briefcase, from]]
      apply_operator_with_side_effects(
        # Primary positive preconditions
        [[:at, briefcase, from]],
        # Primary negative preconditions
        [[:at, briefcase, to]],
        # Primary effects
        effect_add,
        effect_del,
        # Side-effects positive preconditions
        [
          [:at, object, from],
          [:in, object, briefcase]
        ],
        # Side-effects negative preconditions
        [],
        # Free variables
        object
      ) {
        obj_dup = object.dup
        effect_add << [:at, obj_dup, to]
        effect_del << [:at, obj_dup, from]
      }
    end

    def setup_initial_state
      # Move briefcase and all its contents as a side-effect while rotten cookie is left behind
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
    end

    def assert_briefcase_content
      assert_equal([
        ['rotten_cookie', 'a'],
        ['red_briefcase', 'b'],
        ['cookie', 'b'],
        ['documents', 'b']
      ], @state[:at])
    end

    def test_briefcase_side_effects_without_helper
      setup_initial_state
      move_briefcase('red_briefcase','a','b')
      assert_briefcase_content
    end

    def test_briefcase_side_effects_with_helper
      setup_initial_state
      move_briefcase_with_side_effects('red_briefcase','a','b')
      assert_briefcase_content
    end
  end
end