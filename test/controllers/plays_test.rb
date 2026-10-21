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

  test "the matchup form has no bet input" do
    get head_to_head_path

    assert_select "input[name='bet_dollars']", count: 0
    assert_select "[data-game-form-target='terms']", count: 0
  end

  test "the play form has its payout lines directly under the bet input" do
    get play_path

    assert_select "fieldset [data-controller='amount'] + p[data-game-form-target='terms']"
  end

  test "a matchup shows the predicted score and the Elo change for either team winning" do
    get head_to_head_path(mode: "singles", side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])

    assert_select "h2", text: "Rating change"
    assert_select "h2", text: "Prediction"
    assert_select "body", text: /8–7/
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

  test "a matchup is linked from games and profiles" do
    log_game
    get game_path(Game.last)
    assert_select "a", text: "Matchup"

    get player_path(@cam)
    assert_select "a", text: "vs Quinn"
  end

  test "a record shows on the game that set it" do
    Game.create!(mode: "singles", side_a_score: 8, side_b_score: 4, side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])
    get game_path(Game.last)
    assert_select "h2", text: "Records set in this game", count: 0

    blowout = Game.create!(mode: "singles", side_a_score: 8, side_b_score: 0, side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])
    get game_path(blowout)

    assert_select "h2", text: "Records set in this game"
    assert_select "li", text: /Biggest blowout/
  end

  test "the nav has Matchups and History tabs, and no Predict" do
    get head_to_head_path

    assert_select "nav a[aria-current=page]", text: "Matchups"
    assert_select "nav a", text: "Predict", count: 0
    assert_select "nav a", text: "Versus", count: 0
    assert_select "nav a", text: "Games", count: 0

    get games_path

    assert_select "nav a[aria-current=page]", text: "History"
    assert_select "h1", text: "History"
  end

  test "profiles and teams show goals for, against and clean sheets" do
    Game.create!(mode: "singles", side_a_score: 8, side_b_score: 0, side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])
    Game.create!(mode: "singles", side_a_score: 5, side_b_score: 8, side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])
    get player_path(@cam)

    assert_select "dt", text: "Goals for"
    assert_select "dd", text: "13"
    assert_select "dd", text: "8"
    assert_select "dd", text: "+5"
    assert_select "dt", text: "Clean sheets"
    assert_select "dd", text: "1"

    get player_path(@quinn)

    assert_select "dd", text: "−5"
  end

  test "the players tab gives an overview of everyone, best rating first" do
    3.times { Game.create!(mode: "singles", side_a_score: 8, side_b_score: 0, side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ]) }
    get players_path

    assert_select "nav a[aria-current=page]", text: "Players"
    assert_select "h1", text: "Players"
    assert_select "dt", text: "Goals for", count: 2
    assert_select "dt", text: "Clean sheets", count: 2
    names = css_select("main a[href^='/players/'] span.truncate").map { |node| node.text.gsub(/\s+/, " ").strip }
    assert_equal [ "#1 Cam", "#2 Quinn" ], names
  end

  test "players with no games in a mode show a placeholder" do
    get players_path(mode: "doubles")

    assert_select "body", text: /No 2v2 games yet/
  end
end
