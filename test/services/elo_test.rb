require "test_helper"

class EloTest < ActiveSupport::TestCase
  def transfer(winner, loser, points = [ 8, 5 ])
    Elo.transfer(winner_rating: winner, loser_rating: loser, winner_points: points[0], loser_points: points[1])
  end

  test "equal ratings expect a coin flip" do
    assert_in_delta 0.5, Elo.expected(1000, 1000)
  end

  test "a 400 point favourite is expected to win about 91%" do
    assert_in_delta 0.909, Elo.expected(1400, 1000), 0.001
  end

  test "an underdog win moves more than a favourite win" do
    assert_operator transfer(900, 1100), :>, transfer(1100, 900)
  end

  test "a bigger margin moves more" do
    assert_operator transfer(1000, 1000, [ 8, 0 ]), :>, transfer(1000, 1000, [ 8, 7 ])
  end

  test "an 8-0 win doubles the chess amount and 8-7 barely adds" do
    assert_in_delta 32.0, transfer(1000, 1000, [ 8, 0 ]), 0.01
    assert_in_delta 18.0, transfer(1000, 1000, [ 8, 7 ]), 0.01
  end

  test "a huge favourite still gains the minimum" do
    assert_operator transfer(2000, 1000, [ 8, 7 ]), :>=, Elo::MIN_TRANSFER
  end
end
