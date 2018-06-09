$LOAD_PATH.unshift 'lib'
require 'sho'

class SimpleView
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  include Sho

  sho.inline_template :calculated,
    slim: <<~SLIM
      table
        tr
          th x
          td = x
        tr
          th y
          td = y
        tr
          th
            | x
            = op
            | y
          td = x.send(op, y)
    SLIM
end

puts SimpleView.new(5, 6).calculated(op: :+)
# =>
# <table>
#   <tr><th>x</th><td>5</td></tr>
#   <tr><th>y</th><td>6</td></tr>
#   <tr><th>x+y</th><td>11</td></tr>
# </table>