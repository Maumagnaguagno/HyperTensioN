module Grid
  extend self

  def generate(width, height, prefix = 'p')
    adjacent = []
    height.times {|j|
      width.times {|i|
        center = "#{prefix}#{i}_#{j}"
        adjacent.push([center, right = "#{prefix}#{i.succ}_#{j}"], [right, center]) if i != width.pred
        adjacent.push([center, bottom = "#{prefix}#{i}_#{j.succ}"], [bottom, center]) if j != height.pred
      }
    }
    adjacent
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  puts 'Grid [width=3] [height=3] [predicate=connected] [prefix=p] => (connected p0_0 p0_1)'
  width, height, predicate, prefix = ARGV
  predicate ||= 'connected'
  # Output predicates and objects created
  puts Grid.generate(width ? width.to_i : 3, height ? height.to_i : 3, prefix || 'p').each {|a,b|
    puts "(#{predicate} #{a} #{b})"
  }.flatten!.uniq!.sort!.join(' ')
end