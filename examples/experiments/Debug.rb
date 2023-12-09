module Debug

  def print(*argv)
    puts argv.join(' ')
    true
  end

  def print_state
    puts 'State'.center(20,'-')
    @state.each {|k,v| v.each {|i| puts "(#{i.unshift(k).join(' ')})"; i.shift}}
    true
  end

  def input
    STDIN.gets.chomp!
  end

  def assert(pre)
    if pre[0] == 'not'
      pre = pre[1]
      raise "Unexpected (#{pre.join(' ')}) in state" if @state[pre[0]].include?(pre.drop(1))
    elsif not @state[pre[0]].include?(pre.drop(1))
      raise "Expected (#{pre.join(' ')}) in state"
    end
  end
end