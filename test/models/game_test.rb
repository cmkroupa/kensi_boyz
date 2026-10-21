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
end
