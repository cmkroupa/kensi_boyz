require "test_helper"

class HeadToHeadTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn, @tyler, @evan = %w[ Cam Quinn Tyler Evan ].map { |name| Player.create!(name: name) }
  end

  def log(mode, a_players, b_players, a_score, b_score)
    Game.create!(mode: mode, side_a_score: a_score, side_b_score: b_score,
      side_a_player_ids: a_players.map(&:id), side_b_player_ids: b_players.map(&:id))
  end

  def versus(a, b, mode = "singles") = HeadToHead.new(mode: mode, side_a: a, side_b: b)

  test "counts wins either way round the sides were logged" do
    log("singles", [ @cam ], [ @quinn ], 8, 3)
    log("singles", [ @quinn ], [ @cam ], 8, 6)
    log("singles", [ @cam ], [ @quinn ], 8, 1)
    pair = versus([ @cam ], [ @quinn ])

    assert_equal [ 3, 2, 1 ], [ pair.games, pair.a_wins, pair.b_wins ]
    assert_in_delta 2 / 3.0, pair.a_win_rate
  end

  test "ignores games against anyone else" do
    log("singles", [ @cam ], [ @tyler ], 8, 3)

    assert_equal 0, versus([ @cam ], [ @quinn ]).games
  end

  test "margins, points and biggest wins are per side" do
    log("singles", [ @cam ], [ @quinn ], 8, 4)
    big = log("singles", [ @cam ], [ @quinn ], 8, 0)
    log("singles", [ @quinn ], [ @cam ], 8, 7)
    pair = versus([ @cam ], [ @quinn ])

    assert_in_delta 6.0, pair.average_win_margin(:a)
    assert_in_delta 1.0, pair.average_win_margin(:b)
    assert_equal big, pair.biggest_win(:a).game
    assert_in_delta 23 / 3.0, pair.average_points(:a)
  end

  test "the current streak is whoever won the latest meetings" do
    log("singles", [ @cam ], [ @quinn ], 8, 4)
    log("singles", [ @quinn ], [ @cam ], 8, 2)
    log("singles", [ @quinn ], [ @cam ], 8, 5)
    streak = versus([ @cam ], [ @quinn ]).current_streak

    assert_not streak.side_a
    assert_equal 2, streak.length
  end

  test "doubles needs the exact same pairs" do
    log("doubles", [ @cam, @quinn ], [ @tyler, @evan ], 8, 3)
    log("doubles", [ @cam, @tyler ], [ @quinn, @evan ], 8, 3)

    assert_equal 1, versus([ @cam, @quinn ], [ @tyler, @evan ], "doubles").games
    assert_equal 1, versus([ @tyler, @evan ], [ @quinn, @cam ], "doubles").games
  end

  test "sides must be the right size and not overlap" do
    assert_not versus([ @cam ], [ @cam ]).valid?
    assert_not versus([ @cam, @quinn ], [ @tyler ], "doubles").valid?
    assert_predicate versus([ @cam ], [ @quinn ]), :valid?
  end

  test "each side gets a rating line once it has played" do
    log("singles", [ @cam ], [ @quinn ], 8, 3)

    assert_equal [ "Cam", "Quinn" ], versus([ @cam ], [ @quinn ]).series.map(&:name)
    assert_empty versus([ @tyler ], [ @evan ]).series
  end
end
