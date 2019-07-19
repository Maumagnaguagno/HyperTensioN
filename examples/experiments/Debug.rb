module Debug

  def print(*argv)
    puts argv.join(' ')
    true
  end

  def print_state
    puts 'State'.center(20,'-')
    @state.each {|k,v| v.each {|i| puts "(#{k} #{i.join(' ')})"}}
    true
  end

  def input
    STDIN.gets.chomp!
  end

  def assert(pre)
    if pre.first == 'not'
      pre = pre.last
      raise "Unexpected (#{pre.join(' ')}) in state" if @state[pre.first].include(pre.drop(1))
    else
      raise "Expected (#{pre.join(' ')}) in state" unless @state[pre.first].include(pre.drop(1))
    end
  end
end