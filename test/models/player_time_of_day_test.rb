require "test_helper"

class PlayerTimeOfDayTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn = %w[ Cam Quinn ].map { |name| Player.create!(name: name) }
  end

  def log(at, winner = @cam, loser = @quinn)
    Game.create!(mode: "singles", side_a_score: 8, side_b_score: 3, played_at: at,
      side_a_player_ids: [ winner.id ], side_b_player_ids: [ loser.id ])
  end

  def eastern(month, day, hour) = Time.zone.local(2026, month, day, hour, 30)

  test "a player's results are bucketed by time of day" do
    5.times { log(eastern(10, 20, 21), @cam, @quinn) }
    log(eastern(10, 21, 8), @quinn, @cam)
    log(eastern(10, 21, 2), @cam, @quinn)

    record = @cam.time_of_day("singles")

    assert_equal [ 5, 0 ], record["Evening"]
    assert_equal [ 0, 1 ], record["Morning"]
    assert_equal [ 1, 0 ], record["Late night"]
    assert_equal "Evening", @cam.best_time_of_day("singles")
    assert_nil @quinn.best_time_of_day("singles")
  end
end
