require "test_helper"

class PredictorAccuracyTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn = %w[ Cam Quinn ].map { |name| Player.create!(name: name) }
    @clock = Time.zone.local(2026, 3, 2, 10)
  end

  def log(winner, loser, winner_points = 8, loser_points = 3)
    @clock += 5.minutes
    Game.create!(mode: "singles", side_a_score: winner_points, side_b_score: loser_points, played_at: @clock,
      side_a_player_ids: [ winner.id ], side_b_player_ids: [ loser.id ])
  end

  def accuracy = PredictorAccuracy.new

  test "the first game between equals is a toss-up and isn't scored as a pick" do
    log(@cam, @quinn)

    assert_equal 1, accuracy.games
    assert_equal 1, accuracy.toss_ups
    assert_nil accuracy.pick_accuracy
    assert_in_delta 0.25, accuracy.brier_score
  end

  test "picks the favourite and counts a win by the favourite as correct" do
    log(@cam, @quinn)
    log(@cam, @quinn)
    result = accuracy

    assert_equal [ 1, 1, 1.0 ], [ result.called.size, result.correct_picks, result.pick_accuracy ]
  end

  test "an upset counts as a miss" do
    2.times { log(@cam, @quinn) }
    log(@quinn, @cam)
    result = accuracy

    assert_equal 2, result.called.size
    assert_equal 1, result.correct_picks
    assert_in_delta 0.5, result.pick_accuracy
  end

  test "the brier score beats a coin flip when favourites keep winning" do
    6.times { log(@cam, @quinn) }

    assert_operator accuracy.brier_score, :<, 0.25
  end

  test "margin error compares the predicted margin with the real one, signed by who was favoured" do
    log(@cam, @quinn, 8, 3)
    call = accuracy.calls.first

    assert_equal 1, call.predicted_margin
    assert_equal 5, call.actual_margin
    assert_in_delta 4.0, accuracy.margin_error

    2.times { log(@cam, @quinn) }
    upset = log(@quinn, @cam, 8, 6)
    assert_operator PredictorAccuracy.new(Game.where(id: upset.id).preloaded).calls.first.actual_margin, :<, 0
  end

  test "calibration groups favourites by how sure the model was" do
    4.times { log(@cam, @quinn) }
    buckets = accuracy.calibration

    assert buckets.any?
    assert_equal accuracy.called.size, buckets.sum(&:games)
    assert(buckets.all? { |bucket| bucket.expected >= bucket.from && bucket.expected <= bucket.to })
  end

  test "enough games is a sample-size warning" do
    assert_not accuracy.enough_games?
    assert_equal 30, PredictorAccuracy::MIN_GAMES
  end

  test "no games gives no numbers" do
    result = accuracy

    assert_nil result.pick_accuracy
    assert_nil result.brier_score
    assert_nil result.margin_error
    assert_empty result.calibration
  end

  test "the score curve is shared with the predictor" do
    assert_equal 7, Prediction.underdog_points_for(0)
    assert_equal Prediction.underdog_points_for(120), Prediction.underdog_points_for(-120)
    assert_operator Prediction.underdog_points_for(400), :<, Prediction.underdog_points_for(50)
  end
end
