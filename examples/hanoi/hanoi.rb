module Hanoi
  extend self

  def generate(discs)
    problem = "(defproblem pb#{discs - 2} hanoi\n  ; Initial state\n  (\n    ; Towers\n"
    2.upto(discs) {|d| problem << "    (on disk#{d - 1} disk#{d})\n"}
    problem << "    (on disk#{discs}  pegA)\n    (top disk1 pegA)\n    (top  pegB pegB)\n    (top  pegC pegC)\n    ; Decrement\n"
    1.upto(discs) {|d| problem << "    (dec n#{d} n#{d - 1})\n"}
    problem << "  )\n  ; Task list\n  (\n    (keep_moving n#{discs} pegA pegC pegB)\n  )\n)"
  end
end

puts Hanoi.generate(ARGV[0].to_i) if $0 == __FILE__