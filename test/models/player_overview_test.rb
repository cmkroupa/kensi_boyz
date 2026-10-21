require "test_helper"

class PlayerOverviewTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn = %w[ Cam Quinn ].map { |name| Player.create!(name: name) }
    [ [ @cam, @quinn, 8, 0 ], [ @cam, @quinn, 8, 4 ], [ @quinn, @cam, 8, 6 ] ].each do |winner, loser, a, b|
      Game.create!(mode: "singles", side_a_score: a, side_b_score: b,
        side_a_player_ids: [ winner.id ], side_b_player_ids: [ loser.id ])
    end
  end

  def overview(player) = PlayerOverview.new(player.reload, "singles", net_cents: 500)

  test "headline numbers match the player's results" do
    cam = overview(@cam)

    assert_equal [ 3, 2, 1 ], [ cam.games, cam.wins, cam.losses ]
    assert_in_delta 2 / 3.0, cam.win_rate
    assert_equal [ 22, 12, 1 ], [ cam.goals_for, cam.goals_against, cam.clean_sheets ]
    assert_equal 2, cam.best_win_streak
    assert_equal "1L", cam.current_streak.label
    assert_equal 500, cam.net_cents
  end

  test "agrees with the stats on the player" do
    cam = overview(@cam)

    assert_equal @cam.goals_for("singles"), cam.goals_for
    assert_equal @cam.goals_against("singles"), cam.goals_against
    assert_equal @cam.current_streak("singles").label, cam.current_streak.label
    assert_equal @cam.longest_win_streak("singles"), cam.best_win_streak
    assert_equal @cam.rank("singles"), cam.rank
  end

  test "someone with no games has no win rate" do
    tyler = Player.create!(name: "Tyler")

    assert_not PlayerOverview.new(tyler, "singles").ranked?
    assert_nil PlayerOverview.new(tyler, "singles").win_rate
    assert_equal "—", PlayerOverview.new(tyler, "singles").current_streak.label
  end
end
