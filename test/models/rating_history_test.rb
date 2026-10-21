require "test_helper"

class RatingHistoryTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn, @tyler, @evan = %w[ Cam Quinn Tyler Evan ].map { |name| Player.create!(name: name) }
    2.times do |i|
      Game.create!(mode: "singles", side_a_score: 8, side_b_score: i + 1,
        side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])
    end
  end

  test "a player's line starts at 1000 a day before their first game and has a point per game" do
    line = RatingHistory.for_player(@cam.reload, "singles").first

    assert_equal 3, line.points.size
    assert_equal line.points.second.first - 1.day.to_f, line.points.first.first
    assert_in_delta @cam.reload.singles_rating, line.points.last.last
  end

  test "a team's line averages both members' ratings" do
    Game.create!(mode: "doubles", side_a_score: 8, side_b_score: 3,
      side_a_player_ids: [ @cam.id, @quinn.id ], side_b_player_ids: [ @tyler.id, @evan.id ])
    team = Partnership.between(@cam, @quinn)
    line = RatingHistory.for_team(team).first

    assert_equal 2, line.points.size
    assert_in_delta (@cam.reload.doubles_rating + @quinn.reload.doubles_rating) / 2, line.points.last.last
  end
end
