require "test_helper"

class PredictionTest < ActiveSupport::TestCase
  setup do
    @strong = Player.create!(name: "Strong", singles_rating: 1300)
    @weak = Player.create!(name: "Weak", singles_rating: 1000)
  end

  def predict(a, b)
    Prediction.new(mode: "singles", side_a: [ a ], side_b: [ b ])
  end

  test "the favorite is capped at 8 and the underdog stays below it" do
    prediction = predict(@weak, @strong)

    assert_equal 8, prediction.score_b
    assert_operator prediction.score_a, :<, 8
  end

  test "even matchups predict 8-7 with 50% confidence" do
    other = Player.create!(name: "Other", singles_rating: 1000)
    prediction = predict(@weak, other)

    assert_equal [ 8, 7 ], [ prediction.score_a, prediction.score_b ]
    assert_in_delta 0.5, prediction.confidence
  end

  test "a lopsided matchup is more confident and more lopsided" do
    assert_operator predict(@strong, @weak).confidence, :>, 0.8
    assert_operator predict(@strong, @weak).underdog_points, :<=, 2
  end

  test "a modest rating gap already shifts the score off 8-7" do
    close = Player.create!(name: "Close", singles_rating: 1060)

    assert_operator predict(close, @weak).underdog_points, :<, 7
  end

  test "rejects the wrong team size or a shared player" do
    assert_not Prediction.new(mode: "doubles", side_a: [ @strong ], side_b: [ @weak ]).valid?
    assert_not predict(@strong, @strong).valid?
  end

  test "an upset would move more rating than the favourite winning" do
    prediction = predict(@strong, @weak)

    assert_operator prediction.elo_change_if_wins(prediction.side_b), :>, prediction.elo_change_if_wins(prediction.side_a)
  end
end
