require "test_helper"

class PlaysTest < ActionDispatch::IntegrationTest
  setup do
    @cam = Player.create!(name: "Cam")
    @quinn = Player.create!(name: "Quinn")
    post session_path, params: { passcode: "7742" }
  end

  def log_game(bet: 0)
    post games_path, params: { game: { mode: "singles", side_a_score: 8, side_b_score: 3, bet_dollars: bet,
      side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ] } }
  end

  test "the play page has the log form and the nav marks it" do
    get play_path

    assert_response :success
    assert_select "form input[name='game[bet_dollars]']"
    assert_select "nav a[aria-current=page]", text: "Play"
  end

  test "rematch fills in the teams of the last game" do
    log_game
    get play_path(rematch: 1)

    assert_select "input[name='game[side_a_player_ids][]'][value='#{@cam.id}'][checked]"
    assert_select "input[name='game[side_b_player_ids][]'][value='#{@quinn.id}'][checked]"
  end

  test "rematch with no games is just a blank form" do
    get play_path(rematch: 1)

    assert_response :success
  end

  test "a game logged with a bet shows the bet on its page" do
    log_game(bet: 5)
    follow_redirect!

    assert_response :success
    assert_select "h2", text: "Bet"
    assert_select "body", text: /\+\$5/
  end

  test "a bad game re-renders the play page" do
    post games_path, params: { game: { mode: "singles", side_a_score: 5, side_b_score: 5,
      side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ] } }

    assert_response :unprocessable_content
    assert_select "form input[name='game[bet_dollars]']"
  end

  test "the money view ranks net profit" do
    log_game(bet: 5)
    get leaderboard_path(view: "money")

    assert_select "ol li:first-child", text: /Cam.*\+\$5/m
  end

  test "the games page is history only" do
    get games_path

    assert_select "form[action='#{games_path}']", count: 0
  end

  test "predict shows what each side risks and wins when there is a bet" do
    get prediction_path(mode: "singles", side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ], bet_dollars: 5)

    assert_select "body", text: /risks \$5 to win \$5/
  end

  test "predict without a bet shows no payouts" do
    get prediction_path(mode: "singles", side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])

    assert_select "body", text: /risks/, count: 0
  end

  test "predict shows the Elo change for either team winning" do
    get prediction_path(mode: "singles", side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])

    assert_select "body", text: /Elo at 8–7/
    assert_select "body", text: /If Cam win/
    assert_select "body", text: /If Quinn win/
  end

  test "the leaderboard and game page explain the formula" do
    log_game
    get root_path

    assert_select "dialog", text: /How ratings work/
    assert_select "dialog", text: /A winner never loses rating/

    get game_path(Game.last)

    assert_select "dialog h3", text: "This game"
  end
end
