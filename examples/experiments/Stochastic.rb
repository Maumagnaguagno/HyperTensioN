module Hypertension
  extend self

  alias deterministic_planning planning
  def planning(tasks, level = 0)
    if not tasks.empty? and (d = @domain[tasks.first.first]).instance_of?(Array)
      d.shuffle!
    end
    deterministic_planning(tasks, level)
  end

  alias deterministic_generate generate
  def generate(precond_pos, precond_not, *free)
    unifications = []
    deterministic_generate(precond_pos, precond_not, *free) {unifications << free.map {|i| i.dup}}
    unifications.shuffle!.each {|values|
      free.zip(values) {|f,v| f.replace(v)}
      yield
    }
  end
end