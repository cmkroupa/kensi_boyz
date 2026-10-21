require "test_helper"

class EloTest < ActiveSupport::TestCase
  def transfer(winner, loser, points = [ 8, 4 ])
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

  test "a bigger margin moves more, with diminishing returns" do
    assert_operator transfer(1000, 1000, [ 8, 0 ]), :>, transfer(1000, 1000, [ 8, 4 ])
    assert_operator transfer(1000, 1000, [ 8, 4 ]), :>, transfer(1000, 1000, [ 8, 7 ])
    assert_operator transfer(1000, 1000, [ 8, 4 ]) - transfer(1000, 1000, [ 8, 7 ]), :>,
      transfer(1000, 1000, [ 8, 0 ]) - transfer(1000, 1000, [ 8, 4 ])
  end

  test "the margin is the point gap, not the ratio" do
    assert_in_delta transfer(1000, 1000, [ 8, 6 ]), transfer(1000, 1000, [ 4, 2 ])
    assert_operator transfer(1000, 1000, [ 8, 4 ]), :>, transfer(1000, 1000, [ 4, 2 ])
  end

  test "equal players follow K x ln(margin + 1) / 2" do
    assert_in_delta 26.37, transfer(1000, 1000, [ 8, 0 ]), 0.01
    assert_in_delta 19.31, transfer(1000, 1000, [ 8, 4 ]), 0.01
    assert_in_delta 8.32, transfer(1000, 1000, [ 8, 7 ]), 0.01
  end

  test "favourites' margins count for a little less than underdogs'" do
    assert_operator Elo.margin_multiplier(300, 4), :<, Elo.margin_multiplier(0, 4)
    assert_operator Elo.margin_multiplier(-300, 4), :>, Elo.margin_multiplier(0, 4)
  end

  test "a huge favourite still gains the minimum" do
    assert_operator transfer(2000, 1000, [ 8, 7 ]), :>=, Elo::MIN_TRANSFER
  end

  test "new players move faster than settled ones" do
    assert_equal Elo::PROVISIONAL_BOOST, Elo.provisional_boost(0)
    assert_equal 1.0, Elo.provisional_boost(Elo::PROVISIONAL_GAMES)
  end
end
