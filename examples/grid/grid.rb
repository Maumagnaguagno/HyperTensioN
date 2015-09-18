module Grid
  extend self

  def generate(width, height)
    adjacent = []
    height.times {|j|
      width.times {|i|
        center = "p#{i}_#{j}"
        if i != width.pred
          right = "p#{i.succ}_#{j}"
          adjacent.push([center, right], [right, center])
        end
        if j != height.pred
          bottom = "p#{i}_#{j.succ}"
          adjacent.push([center, bottom], [bottom, center])
        end
      }
    }
    adjacent
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  width, height, predicate = ARGV
  width ||= 10
  height ||= width
  predicate ||= 'adjacent'
  # Output propositions and objects created
  puts Grid.generate(width, height).each {|a,b| puts "(#{predicate} #{a} #{b})"}.flatten!.sort!.uniq!.join(' ')
end