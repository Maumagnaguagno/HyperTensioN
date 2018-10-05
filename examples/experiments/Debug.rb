module Debug

  def breakpoint
    STDIN.gets
    true
  end

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
end