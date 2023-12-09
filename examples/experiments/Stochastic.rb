module Stochastic

  def planning(tasks, level = 0)
    if not tasks.empty? and (d = @domain[tasks[0][0]]).instance_of?(Array)
      d.shuffle!
    end
    super
  end

  def generate(precond_pos, precond_not, *free)
    unifications = []
    super {unifications << free.map(&:dup)}
    unifications.shuffle!.each {|values|
      free.zip(values) {|f,v| f.replace(v)}
      yield
    }
  end
end