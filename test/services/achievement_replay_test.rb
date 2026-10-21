require "test_helper"

class AchievementReplayTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn, @tyler, @evan = %w[ Cam Quinn Tyler Evan ].map { |name| Player.create!(name: name) }
    @clock = Time.zone.local(2026, 3, 2, 10)
  end

  def log(winner, loser, winner_points = 8, loser_points = 3, **extra)
    @clock += 5.minutes
    Game.create!(mode: "singles", side_a_score: winner_points, side_b_score: loser_points, played_at: @clock,
      side_a_player_ids: [ winner.id ], side_b_player_ids: [ loser.id ], **extra)
  end

  def keys(player, scope = nil)
    Achievement.where(player: player).then { |rows| scope ? rows.where(scope: scope) : rows }.pluck(:key)
  end

  test "a first win and games played" do
    10.times { log(@cam, @quinn) }

    assert_includes keys(@cam), "first_win"
    assert_includes keys(@cam), "games_10"
    assert_not_includes keys(@cam), "games_25"
    assert_includes keys(@quinn), "games_10"
    assert_not_includes keys(@quinn), "first_win"
  end

  test "win streaks stack up and reset on a loss" do
    5.times { log(@cam, @quinn) }
    log(@quinn, @cam)

    assert_equal %w[ win_streak_3 win_streak_5 ], keys(@cam).grep(/win_streak/).sort
    assert_empty keys(@quinn).grep(/win_streak/)
  end

  test "a comeback needs three losses first" do
    2.times { log(@quinn, @cam) }
    log(@cam, @quinn)

    assert_not_includes keys(@cam), "comeback"

    Game.destroy_all
    3.times { log(@quinn, @cam) }
    log(@cam, @quinn)

    assert_includes keys(@cam), "comeback"
  end

  test "shutouts, shutout streaks and getting zeroed" do
    log(@cam, @quinn, 8, 0)

    assert_includes keys(@cam), "shutout"
    assert_includes keys(@quinn), "got_zeroed"
    assert_not_includes keys(@cam), "shutout_streak_2"

    log(@cam, @quinn, 8, 0)

    assert_includes keys(@cam), "shutout_streak_2"
  end

  test "a non-shutout win breaks the shutout streak" do
    log(@cam, @quinn, 8, 0)
    log(@cam, @quinn, 8, 4)
    log(@cam, @quinn, 8, 0)

    assert_not_includes keys(@cam), "shutout_streak_2"
  end

  test "nail-biters and clutch" do
    2.times { log(@cam, @quinn, 8, 7) }

    assert_includes keys(@cam), "nail_biter"
    assert_not_includes keys(@cam), "clutch"

    log(@cam, @quinn, 8, 7)

    assert_includes keys(@cam), "clutch"
  end

  test "an upset earns giant killer" do
    4.times { log(@cam, @quinn) }
    upset = log(@quinn, @cam, 8, 6)

    assert_equal upset.id, Achievement.find_by(player: @quinn, key: "giant_killer").game_id
  end

  test "beating the top-rated player counts only once they've played enough" do
    2.times { log(@cam, @quinn) }
    log(@tyler, @cam)

    assert_not_includes keys(@tyler), "beat_the_best"

    log(@cam, @quinn)
    log(@tyler, @cam)

    assert_includes keys(@tyler), "beat_the_best"
  end

  test "rating clubs" do
    12.times { log(@cam, @quinn, 8, 0) }

    assert_includes keys(@cam), "rating_1100"
    assert_not_includes keys(@cam), "rating_1200"
  end

  test "five wins with the same partner make a dynamic duo, in doubles only" do
    5.times do
      @clock += 5.minutes
      Game.create!(mode: "doubles", side_a_score: 8, side_b_score: 3, played_at: @clock,
        side_a_player_ids: [ @cam.id, @quinn.id ], side_b_player_ids: [ @tyler.id, @evan.id ])
    end

    assert_includes keys(@cam, "doubles"), "duo_5"
    assert_includes keys(@quinn, "doubles"), "duo_5"
    assert_not_includes keys(@tyler), "duo_5"
  end

  test "winning bets in a row and winning big" do
    3.times { log(@cam, @quinn, bet_dollars: 5) }

    assert_includes keys(@cam), "bet_streak_3"
    assert_not_includes keys(@cam), "big_bet"

    log(@cam, @quinn, bet_dollars: 25)

    assert_includes keys(@cam), "big_bet"
  end

  test "a lost bet resets the bet streak" do
    2.times { log(@cam, @quinn, bet_dollars: 5) }
    log(@quinn, @cam, bet_dollars: 5)
    log(@cam, @quinn, bet_dollars: 5)

    assert_not_includes keys(@cam), "bet_streak_3"
  end

  test "records are only set once they are impressive" do
    2.times { log(@cam, @quinn) }

    assert_empty RecordBreak.where(key: "win_streak")

    log(@cam, @quinn)
    streak = RecordBreak.current.find { |record| record.key == "win_streak" }

    assert_equal [ @cam.id, 3.0, "singles" ], [ streak.player_id, streak.value, streak.scope ]
  end

  test "a longer streak by someone else breaks the record" do
    3.times { log(@cam, @quinn) }
    log(@quinn, @cam)
    4.times { log(@quinn, @cam) }
    streak = RecordBreak.current.find { |record| record.key == "win_streak" }

    assert_equal [ @quinn.id, 5.0 ], [ streak.player_id, streak.value ]
  end

  test "the biggest blowout and upset records point at the game" do
    log(@cam, @quinn, 8, 4)
    blowout = log(@cam, @quinn, 8, 1)
    4.times { log(@cam, @quinn, 8, 4) }
    upset = log(@quinn, @cam, 8, 6)
    current = RecordBreak.current.index_by(&:key)

    assert_equal blowout.id, current["biggest_blowout"].game_id
    assert_equal upset.id, current["biggest_upset"].game_id
    assert_operator current["biggest_upset"].value, :<, Game::UPSET_CHANCE
  end

  test "most games in a day" do
    4.times { log(@cam, @quinn) }
    record = RecordBreak.current.find { |row| row.key == "most_games_in_day" }

    assert_equal 4.0, record.value
  end

  test "deleting the game that earned a badge takes the badge away" do
    game = log(@cam, @quinn, 8, 0)

    assert_includes keys(@cam), "shutout"

    game.destroy

    assert_empty Achievement.all
    assert_empty RecordBreak.all
  end

  test "correcting a score can remove or move a badge" do
    game = log(@cam, @quinn, 8, 0)
    game.update!(side_b_score: 4)

    assert_not_includes keys(@cam), "shutout"
  end
end
