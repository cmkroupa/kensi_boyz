require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @player = players(:one)
  end

  test "should get index" do
    get players_url
    assert_response :success
  end

  test "should get new" do
    get new_player_url
    assert_response :success
  end

  test "should create player" do
    assert_difference("Player.count") do
      post players_url, params: { player: { elo: @player.elo, losses: @player.losses, name: @player.name, wins: @player.wins } }
    end

    assert_redirected_to players_url
  end

  test "should show player" do
    get player_url(@player)
    assert_response :success
  end
end
