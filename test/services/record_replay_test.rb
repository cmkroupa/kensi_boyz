require "test_helper"

class RecordReplayTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn = %w[ Cam Quinn ].map { |name| Player.create!(name: name) }
    @clock = Time.zone.local(2026, 3, 2, 10)
  end

  def log(winner, loser, winner_points = 8, loser_points = 3)
    @clock += 5.minutes
    Game.create!(mode: "singles", side_a_score: winner_points, side_b_score: loser_points, played_at: @clock,
      side_a_player_ids: [ winner.id ], side_b_player_ids: [ loser.id ])
  end

  def current = RecordBreak.current.index_by { |record| [ record.key, record.scope ] }

  test "records are only set once they are impressive" do
    2.times { log(@cam, @quinn) }

    assert_empty RecordBreak.where(key: "win_streak")

    log(@cam, @quinn)
    streak = current[[ "win_streak", "singles" ]]

    assert_equal [ @cam.id, 3.0 ], [ streak.player_id, streak.value ]
  end

  test "a longer streak by someone else breaks the record" do
    3.times { log(@cam, @quinn) }
    log(@quinn, @cam)
    4.times { log(@quinn, @cam) }
    streak = current[[ "win_streak", "singles" ]]

    assert_equal [ @quinn.id, 5.0 ], [ streak.player_id, streak.value ]
  end

  test "a loss ends a streak, so it can't extend the record" do
    3.times { log(@cam, @quinn) }
    log(@quinn, @cam)
    log(@cam, @quinn)

    assert_equal 3.0, current[[ "win_streak", "singles" ]].value
  end

  test "shutout streaks break on a game that isn't a shutout" do
    log(@cam, @quinn, 8, 0)
    log(@cam, @quinn, 8, 4)
    log(@cam, @quinn, 8, 0)

    assert_nil current[[ "shutout_streak", "all" ]]

    log(@cam, @quinn, 8, 0)

    assert_equal 2.0, current[[ "shutout_streak", "all" ]].value
  end

  test "the biggest blowout and upset records point at the game" do
    log(@cam, @quinn, 8, 4)
    blowout = log(@cam, @quinn, 8, 1)
    4.times { log(@cam, @quinn, 8, 4) }
    upset = log(@quinn, @cam, 8, 6)

    assert_equal blowout.id, current[[ "biggest_blowout", "all" ]].game_id
    assert_equal upset.id, current[[ "biggest_upset", "all" ]].game_id
    assert_operator current[[ "biggest_upset", "all" ]].value, :<, Game::UPSET_CHANCE
  end

  test "the highest rating is tracked per mode" do
    12.times { log(@cam, @quinn, 8, 0) }
    record = current[[ "highest_rating", "singles" ]]

    assert_equal @cam.id, record.player_id
    assert_operator record.value, :>=, 1050
    assert_nil current[[ "highest_rating", "doubles" ]]
  end

  test "most games in a day" do
    4.times { log(@cam, @quinn) }

    assert_equal 4.0, current[[ "most_games_in_day", "all" ]].value
  end

  test "deleting the game that set a record takes the record away" do
    game = log(@cam, @quinn, 8, 0)
    game.destroy

    assert_empty RecordBreak.all
  end

  test "correcting a score can remove a record" do
    game = log(@cam, @quinn, 8, 0)
    assert_equal 8.0, current[[ "biggest_blowout", "all" ]].value

    game.update!(side_b_score: 6)

    assert_nil current[[ "biggest_blowout", "all" ]]
  end
end
