require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @cam = Player.create!(name: "Cam")
    @quinn = Player.create!(name: "Quinn")
  end

  def sign_in(passcode) = post(session_path, params: { passcode: passcode })

  def log_game(winner = @cam, loser = @quinn, winner_points = 8, loser_points = 3)
    Game.create!(mode: "singles", side_a_score: winner_points, side_b_score: loser_points,
      side_a_player_ids: [ winner.id ], side_b_player_ids: [ loser.id ])
  end

  test "members can't open the admin page and don't see the link" do
    sign_in "7742"
    get admin_path

    assert_redirected_to root_path

    get root_path
    assert_select "a", text: "Admin", count: 0
  end

  test "admins get an Admin link in the header and a page behind it" do
    sign_in "2477"
    get root_path

    assert_select "header a[href='#{admin_path}']", text: "Admin"

    get admin_path

    assert_response :success
    assert_select "h1", text: "Admin"
    assert_select "header a[aria-current=page]", text: "Admin"
    %w[ Settings Predictor\ accuracy Backups Players ].each { |section| assert_select "h2", text: section }
  end

  test "only admins can switch decay, and it takes effect" do
    sign_in "7742"
    delete decay_path

    assert_predicate Setting, :decay_enabled?

    delete session_path
    sign_in "2477"
    get admin_path
    assert_select "button", text: "Turn off"

    delete decay_path

    assert_not Setting.decay_enabled?
    get admin_path
    assert_select "button", text: "Turn on"

    post decay_path

    assert_predicate Setting, :decay_enabled?
  end

  test "decay is no longer on the leaderboard" do
    sign_in "2477"
    get root_path

    assert_select "button", text: /Turn (on|off)/, count: 0
  end

  test "the predictor section explains itself with no games, few games and enough games" do
    sign_in "2477"
    get admin_path
    assert_select "body", text: /No games yet/

    log_game
    log_game
    get admin_path

    assert_select "body", text: /of winners called/
    assert_select "body", text: /Only 2 games so far/
    assert_select "dt", text: "Brier score"
  end

  test "backups show their status and can be started by hand" do
    sign_in "2477"
    get admin_path
    assert_select "body", text: /aren't set up/

    ENV["GITHUB_BACKUP_TOKEN"] = "x"
    get admin_path

    assert_select "body", text: /None recorded yet/
    assert_enqueued_with(job: DatabaseBackupJob) { post backup_path }
    assert_redirected_to admin_path
  ensure
    ENV.delete("GITHUB_BACKUP_TOKEN")
  end

  test "members can't start a backup" do
    sign_in "7742"

    assert_no_enqueued_jobs { post backup_path }
    assert_redirected_to root_path
  end

  test "there is no manual recalculate, since it happens automatically" do
    sign_in "2477"
    get admin_path

    assert_select "button", text: /Recalculate/, count: 0
  end

  test "admins can add and rename players" do
    sign_in "2477"
    post players_path, params: { player: { name: "Nash" } }

    assert_redirected_to admin_path
    assert Player.exists?(name: "Nash")

    patch player_path(@cam), params: { player: { name: "Cameron" } }

    assert_equal "Cameron", @cam.reload.name

    post players_path, params: { player: { name: "cameron" } }
    follow_redirect!
    assert_select "body", text: /already been taken/
  end

  test "members can't add or rename players" do
    sign_in "7742"
    post players_path, params: { player: { name: "Nash" } }
    patch player_path(@cam), params: { player: { name: "Cameron" } }

    assert_not Player.exists?(name: "Nash")
    assert_equal "Cam", @cam.reload.name
  end

  test "a new player shows up in the pickers" do
    sign_in "2477"
    post players_path, params: { player: { name: "Nash" } }
    get play_path

    assert_select "input[data-name='Nash']", minimum: 2
  end
end
