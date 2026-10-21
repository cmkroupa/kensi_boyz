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

  test "the profile shows records once there are enough games" do
    3.times { Game.create!(mode: "singles", side_a_score: 8, side_b_score: 2, side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ]) }
    get player_path(@cam)

    assert_select "h2", text: "Records"
    assert_select "dt", text: "Victim"
    assert_select "dt", text: "Biggest blowout"
  end

  test "a big upset is tagged on the game" do
    4.times { Game.create!(mode: "singles", side_a_score: 8, side_b_score: 2, side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ]) }
    upset = Game.create!(mode: "singles", side_a_score: 8, side_b_score: 6, side_a_player_ids: [ @quinn.id ], side_b_player_ids: [ @cam.id ])
    get game_path(upset)

    assert_select "span", text: "Upset"
  end

  test "only admins can switch decay, and it takes effect" do
    delete decay_path

    assert_redirected_to root_path
    assert_predicate Setting, :decay_enabled?

    delete session_path
    post session_path, params: { passcode: "2477" }
    get root_path

    assert_select "button", text: "Turn off"

    delete decay_path

    assert_not Setting.decay_enabled?
    get root_path
    assert_select "button", text: "Turn on"

    post decay_path

    assert_predicate Setting, :decay_enabled?
  end

  test "the head to head page shows the record between two players" do
    log_game
    get head_to_head_path(mode: "singles", side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])

    assert_select "body", text: /1–0/
    assert_select "body", text: /Cam win 100%/
    assert_select "h2", text: "Meetings"
  end

  test "the head to head page handles players who have never met" do
    get head_to_head_path(mode: "singles", side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])

    assert_select "body", text: /haven't played each other yet/
  end

  test "head to head is linked from games, profiles and predictions" do
    log_game
    get game_path(Game.last)
    assert_select "a", text: "Head to head"

    get player_path(@cam)
    assert_select "a", text: "vs Quinn"

    get prediction_path(mode: "singles", side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])
    assert_select "a", text: /Head to head/
  end

  test "the activity view shows charts once there are games" do
    get root_path(view: "activity")
    assert_select "body", text: /No games yet/

    log_game
    get root_path(view: "activity")

    assert_select "svg[aria-label='Games per day']"
    assert_select "dt", text: "Peak hour"
    assert_select "a", text: "Activity"
  end

  test "the profile shows when you play" do
    log_game
    get player_path(@cam)

    assert_select "h2", text: "When you play"
    assert_select "li", text: /Morning|Afternoon|Evening|Late night/
  end
end
