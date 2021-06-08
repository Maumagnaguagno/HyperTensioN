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
  puts 'Grid [width=3] [height=width] [predicate=connected] [prefix=p] => (connected p0_0 p0_1)'
  width, height, predicate, prefix = ARGV
  width = width ? width.to_i : 3
  height = height ? height.to_i : width
  predicate ||= 'connected'
  prefix ||= 'p'
  # Output objects and predicates created
  height.times {|j| puts Array.new(width) {|i| "#{prefix}#{i}_#{j}" }.join(' ')}
  Grid.generate(width, height, prefix).each {|a,b| puts "(#{predicate} #{a} #{b})"}
end