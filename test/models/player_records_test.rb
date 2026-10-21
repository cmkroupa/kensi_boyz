require "test_helper"

class PlayerRecordsTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn, @tyler = %w[ Cam Quinn Tyler ].map { |name| Player.create!(name: name) }
  end

  def log(winner, loser, winner_points = 8, loser_points = 3)
    Game.create!(mode: "singles", side_a_score: winner_points, side_b_score: loser_points,
      side_a_player_ids: [ winner.id ], side_b_player_ids: [ loser.id ])
  end

  test "nemesis and victim need a few games and a lopsided record" do
    2.times { log(@cam, @quinn) }

    assert_nil @quinn.nemesis("singles")

    log(@cam, @quinn)

    assert_equal @cam, @quinn.nemesis("singles").other
    assert_equal @quinn, @cam.victim("singles").other
    assert_nil @cam.nemesis("singles")
    assert_nil @quinn.victim("singles")
  end

  test "the nemesis is the opponent with the worst record against you" do
    3.times { log(@cam, @quinn) }
    log(@quinn, @cam)
    4.times { log(@tyler, @quinn) }

    assert_equal @tyler, @quinn.nemesis("singles").other
  end

  test "biggest upset is the win with the lowest chance, and only if it was against the odds" do
    log(@cam, @quinn)

    assert_nil @cam.biggest_upset("singles")

    3.times { log(@cam, @quinn) }
    upset = log(@quinn, @cam, 8, 6)

    assert_equal upset, @quinn.biggest_upset("singles").game
    assert_predicate upset, :upset?
  end

  test "biggest blowout and worst loss are the largest margins" do
    log(@cam, @quinn, 8, 6)
    blowout = log(@cam, @quinn, 8, 0)
    log(@quinn, @cam, 8, 7)

    assert_equal blowout, @cam.biggest_blowout("singles").game
    assert_equal blowout, @quinn.worst_loss("singles").game
    assert_equal 8, @cam.biggest_blowout("singles").points - @cam.biggest_blowout("singles").opponent_points
  end

  test "an even game is not an upset" do
    game = log(@cam, @quinn)

    assert_not game.upset?
  end
end
