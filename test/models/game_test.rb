require "test_helper"

class GameTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn, @tyler, @evan = %w[ Cam Quinn Tyler Evan ].map { |name| Player.create!(name: name) }
  end

  def log(mode, a_ids, b_ids, a_score, b_score)
    Game.create!(mode: mode, side_a_score: a_score, side_b_score: b_score,
      side_a_player_ids: a_ids.map(&:id), side_b_player_ids: b_ids.map(&:id))
  end

  test "a win raises the winner's rating and lowers the loser's" do
    log("singles", [ @cam ], [ @quinn ], 8, 3)

    assert_operator @cam.reload.singles_rating, :>, 1000
    assert_operator @quinn.reload.singles_rating, :<, 1000
  end

  test "a bigger margin moves ratings further" do
    log("singles", [ @cam ], [ @quinn ], 8, 7)
    close = @cam.reload.singles_rating
    Game.destroy_all
    log("singles", [ @cam ], [ @quinn ], 8, 1)

    assert_operator @cam.reload.singles_rating, :>, close
  end

  test "winning never costs rating, even as a heavy favourite" do
    5.times { log("singles", [ @cam ], [ @quinn ], 8, 7) }
    before = @cam.reload.singles_rating
    log("singles", [ @cam ], [ @quinn ], 8, 7)

    assert_operator @cam.reload.singles_rating, :>, before
  end

  test "ratings are zero-sum" do
    log("singles", [ @cam ], [ @quinn ], 8, 3)
    log("singles", [ @quinn ], [ @cam ], 8, 6)

    assert_in_delta 2000, @cam.reload.singles_rating + @quinn.reload.singles_rating
  end

  test "1v1 and 2v2 ratings are tracked separately" do
    log("singles", [ @cam ], [ @quinn ], 8, 3)

    assert_equal 1000, @cam.reload.doubles_rating
  end

  test "teammates share the same rating change" do
    log("doubles", [ @cam, @quinn ], [ @tyler, @evan ], 8, 3)

    assert_in_delta @cam.reload.doubles_rating, @quinn.reload.doubles_rating
    assert_operator @cam.doubles_rating, :>, 1000
  end

  test "deleting a game restores ratings" do
    log("singles", [ @cam ], [ @quinn ], 8, 3).destroy

    assert_equal 1000, @cam.reload.singles_rating
    assert_equal 0, @cam.singles_games_count
  end

  test "winner and loser sides follow the score" do
    game = log("singles", [ @cam ], [ @quinn ], 3, 8)

    assert_equal "b", game.winner_side
    assert_equal "a", game.loser_side
  end

  test "ties are rejected" do
    game = Game.new(mode: "singles", side_a_score: 5, side_b_score: 5,
      side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])

    assert_not game.valid?
  end

  test "a player cannot be on both sides" do
    game = Game.new(mode: "singles", side_a_score: 8, side_b_score: 5,
      side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @cam.id ])

    assert_not game.valid?
  end

  test "doubles needs two players per side" do
    game = Game.new(mode: "doubles", side_a_score: 8, side_b_score: 5,
      side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])

    assert_not game.valid?
  end

  test "streaks and partnerships are derived from results" do
    log("singles", [ @cam ], [ @quinn ], 8, 3)
    log("singles", [ @cam ], [ @tyler ], 8, 6)
    log("doubles", [ @cam, @quinn ], [ @tyler, @evan ], 8, 3)

    assert_equal "2W", @cam.current_streak("singles").label
    assert_equal 2, @cam.longest_win_streak("singles")
    assert_equal 1.0, Partnership.all.first.win_rate
    rivalry = Rivalry.new(@cam, @quinn, mode: "singles")
    assert_equal 1, rivalry.games
    assert_equal 1.0, rivalry.win_rate
    assert_equal 0, Rivalry.new(@cam, @quinn, mode: "doubles").games
  end

  test "the Elo breakdown matches what the winners gained" do
    game = log("singles", [ @cam ], [ @quinn ], 8, 4)
    breakdown = game.elo_breakdown

    assert_in_delta 19.31, breakdown.transfer, 0.01
    assert_in_delta 0.5, breakdown.chance
    assert_in_delta breakdown.transfer * Elo::PROVISIONAL_BOOST, game.participations.find { |p| p.player == @cam }.delta, 0.01
  end

  test "an idle player's rating drifts back toward 1000" do
    travel_to Time.zone.local(2026, 1, 1, 12) do
      Game.create!(mode: "singles", side_a_score: 8, side_b_score: 0, played_at: 1.minute.ago,
        side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])
      fresh = @cam.reload.singles_rating

      assert_operator fresh, :>, 1000
      assert_nil @cam.idle_days("singles")

      travel_to 5.weeks.from_now
      RatingReplay.call

      assert_operator @cam.reload.singles_rating, :<, fresh
      assert_operator @cam.singles_rating, :>, 1000
      assert_equal 35, @cam.idle_days("singles")
    end
  end

  test "decay applies before the next game so a returning player starts lower" do
    travel_to Time.zone.local(2026, 1, 1, 12) do
      Game.create!(mode: "singles", side_a_score: 8, side_b_score: 0, played_at: Time.current,
        side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])
      peak = @cam.reload.singles_rating
      Game.create!(mode: "singles", side_a_score: 8, side_b_score: 4, played_at: 6.weeks.from_now,
        side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @tyler.id ])

      assert_operator @cam.participations.joins(:game).order("games.played_at").last.rating_before, :<, peak
    end
  end

  test "players with no games do not decay" do
    travel_to 1.year.from_now do
      RatingReplay.call

      assert_equal 1000, @cam.reload.singles_rating
    end
  end

  test "turning decay off stops ratings drifting and restores them" do
    travel_to Time.zone.local(2026, 1, 1, 12) do
      Game.create!(mode: "singles", side_a_score: 8, side_b_score: 0, played_at: Time.current,
        side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])
      fresh = @cam.reload.singles_rating
      travel_to 6.weeks.from_now
      RatingReplay.call

      assert_operator @cam.reload.singles_rating, :<, fresh

      Setting.switch("decay", false)
      RatingReplay.call

      assert_in_delta fresh, @cam.reload.singles_rating
      assert_nil @cam.idle_days("singles")
    end
  end
end
