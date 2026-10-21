require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn = %w[ Cam Quinn ].map { |name| Player.create!(name: name) }
  end

  def log(at, winner = @cam, loser = @quinn)
    Game.create!(mode: "singles", side_a_score: 8, side_b_score: 3, played_at: at,
      side_a_player_ids: [ winner.id ], side_b_player_ids: [ loser.id ])
  end

  def eastern(month, day, hour) = Time.zone.local(2026, month, day, hour, 30)

  def activity = Activity.new(Game.chronologically)

  test "counts games by day in Eastern time, not UTC" do
    log(eastern(10, 20, 23))
    log(eastern(10, 20, 9))
    log(eastern(10, 21, 1))

    travel_to eastern(10, 21, 12) do
      days = activity.per_day(3).to_h

      assert_equal 2, days[Date.new(2026, 10, 20)]
      assert_equal 1, days[Date.new(2026, 10, 21)]
      assert_equal 0, days[Date.new(2026, 10, 19)]
      assert_equal 30, activity.per_day.size
    end
  end

  test "hours and weekdays are tallied" do
    log(eastern(10, 20, 21))
    log(eastern(10, 20, 21))
    log(eastern(10, 22, 14))

    assert_equal 2, activity.by_hour[21]
    assert_equal 1, activity.by_hour[14]
    assert_equal 21, activity.peak_hour
    assert_equal [ 0, 2, 0, 1, 0, 0, 0 ], activity.by_weekday
  end

  test "busiest day and streak" do
    log(eastern(10, 18, 20))
    log(eastern(10, 19, 20))
    log(eastern(10, 20, 20))
    log(eastern(10, 20, 21))

    travel_to eastern(10, 21, 8) do
      assert_equal [ Date.new(2026, 10, 20), 2 ], activity.busiest_day
      assert_equal 3, activity.day_streak
    end
    travel_to eastern(10, 25, 8) do
      assert_equal 0, activity.day_streak
    end
  end

  test "no games means no peak hour" do
    assert_nil activity.peak_hour
    assert_equal 0, activity.total
  end

  test "a player's results are bucketed by time of day" do
    5.times { |i| log(eastern(10, 20, 21), @cam, @quinn) }
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
