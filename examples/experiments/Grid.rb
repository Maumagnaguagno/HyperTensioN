module Grid
  extend self

  def objects(width, height, prefix = 'p')
    Array.new(height) {|j| Array.new(width) {|i| "#{prefix}#{i}_#{j}"}}
  end

  def generate(width, height, prefix = 'p', objects = objects(width, height, prefix))
    adjacent = []
    height.times {|j|
      width.times {|i|
        center = objects[j][i]
        adjacent.push([center, right  = objects[j][i+1]], [right, center]) if i+1 != width
        adjacent.push([center, bottom = objects[j+1][i]], [bottom, center]) if j+1 != height
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
  puts (objects = Grid.objects(width, height, prefix)).map {|i| i.join(' ')}
  Grid.generate(width, height, prefix, objects).each {|a,b| puts "(#{predicate} #{a} #{b})"}
end