require "test_helper"

class AccessTest < ActionDispatch::IntegrationTest
  setup do
    Player.create!(name: "Cam")
    Player.create!(name: "Quinn")
  end

  def sign_in(passcode = "7742")
    post session_path, params: { passcode: passcode }
  end

  test "the web app manifest is public" do
    get pwa_manifest_path(format: :json)

    assert_response :success
    assert_equal "KFL", response.parsed_body["short_name"]
  end

  test "visitors are sent to the passcode page" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "the nav marks the current page" do
    sign_in
    get games_path

    assert_select "nav a[aria-current=page]", text: "Games"
    assert_select "nav a[aria-current=page]", count: 1
  end

  test "logging out clears the cookie so the PIN is needed again" do
    sign_in("2477")
    delete session_path
    get root_path

    assert_redirected_to new_session_path
  end

  test "a wrong passcode is rejected" do
    post session_path, params: { passcode: "0000" }
    get root_path

    assert_redirected_to new_session_path
  end

  test "the right passcode unlocks the app" do
    sign_in
    get root_path

    assert_response :success
  end

  test "all pages render once signed in" do
    sign_in
    cam, quinn = Player.order(:name).to_a
    Game.create!(mode: "singles", side_a_score: 8, side_b_score: 4,
      side_a_player_ids: [ cam.id ], side_b_player_ids: [ quinn.id ])

    doubles = Game.create!(mode: "doubles", side_a_score: 8, side_b_score: 6,
      side_a_player_ids: [ cam.id, quinn.id ], side_b_player_ids: Player.create!([ { name: "T" }, { name: "E" } ]).map(&:id))

    [ root_path(mode: "doubles"), games_path, game_path(Game.first), game_path(doubles), team_path("#{cam.id}-#{quinn.id}"), games_path(player_id: cam.id),
      player_path(cam), player_path(cam, mode: "doubles"),
      prediction_path, play_path, play_path(rematch: 1), root_path(view: "money"), root_path(view: "activity"), debts_path, records_path, head_to_head_path,
      prediction_path(mode: "singles", side_a_player_ids: [ cam.id ], side_b_player_ids: [ quinn.id ]) ].each do |path|
      get path
      assert_response :success, path
    end
  end

  test "the 2v2 leaderboard shows the top duos" do
    sign_in
    a, b, c, d = %w[ Tyler Evan Angelo Nash ].map { |name| Player.create!(name: name) }
    Game.create!(mode: "doubles", side_a_score: 8, side_b_score: 4,
      side_a_player_ids: [ a.id, b.id ], side_b_player_ids: [ c.id, d.id ])

    get root_path(mode: "doubles")

    assert_select "h2", text: "Top 5 duos"
    assert_select "ol li", minimum: 2
  end

  test "members cannot edit or delete games" do
    sign_in
    cam, quinn = Player.order(:name).to_a
    game = Game.create!(mode: "singles", side_a_score: 8, side_b_score: 4,
      side_a_player_ids: [ cam.id ], side_b_player_ids: [ quinn.id ])

    get edit_game_path(game)
    assert_redirected_to root_path
    patch game_path(game), params: { game: { side_a_score: 1, side_b_score: 8 } }
    assert_equal 8, game.reload.side_a_score
    assert_no_difference("Game.count") { delete game_path(game) }
    get game_path(game)
    assert_select "a", text: "Edit score", count: 0
  end

  test "the admin PIN can edit a score and ratings follow" do
    sign_in("2477")
    cam, quinn = Player.order(:name).to_a
    game = Game.create!(mode: "singles", side_a_score: 8, side_b_score: 7,
      side_a_player_ids: [ cam.id ], side_b_player_ids: [ quinn.id ])
    close = cam.reload.singles_rating

    get edit_game_path(game)
    assert_response :success
    patch game_path(game), params: { game: { side_a_score: 8, side_b_score: 1 } }

    assert_redirected_to game_path(game)
    assert_operator cam.reload.singles_rating, :>, close
  end

  test "logging a game updates the leaderboard" do
    sign_in
    cam, quinn = Player.order(:name).to_a

    post games_path, params: { game: { mode: "singles", side_a_score: 8, side_b_score: 2,
      side_a_player_ids: [ cam.id ], side_b_player_ids: [ quinn.id ] } }

    assert_redirected_to game_path(Game.last)
    assert_operator cam.reload.singles_rating, :>, 1000

    get root_path
    assert_select "svg", 0
    get player_path(cam)
    assert_select "svg polyline", 1
  end

  test "an invalid game re-renders the form" do
    sign_in

    post games_path, params: { game: { mode: "singles", side_a_score: 3, side_b_score: 3 } }

    assert_response :unprocessable_content
  end
end
