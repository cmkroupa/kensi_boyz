require "test_helper"

class DebtsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cam = Player.create!(name: "Cam")
    @quinn = Player.create!(name: "Quinn")
    post session_path, params: { passcode: "7742" }
    @game = Game.create!(mode: "singles", side_a_score: 8, side_b_score: 3, bet_dollars: 5,
      side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])
    @debt = @game.debts.sole
  end

  test "the debts page lists who owes who" do
    get debts_path

    assert_select "nav a[aria-current=page]", text: "Debts"
    assert_select "body", text: /Quinn owes Cam/
  end

  test "a debt can be marked paid and unpaid" do
    post debt_payment_path(@debt)

    assert_predicate @debt.reload, :paid?
    follow_redirect!
    assert_select "body", text: /Quinn paid Cam/

    delete debt_payment_path(@debt)

    assert_not @debt.reload.paid?
  end

  test "mark all paid settles everything between two players" do
    other = Game.create!(mode: "singles", side_a_score: 8, side_b_score: 1, bet_dollars: 10,
      side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])

    post debt_settlements_path, params: { debtor_id: @quinn.id, creditor_id: @cam.id }

    assert_empty Debt.unpaid
    assert_predicate other.debts.sole.reload, :paid?
  end

  test "the page can be filtered to one player" do
    get debts_path(player_id: @cam.id)

    assert_select "body", text: /Quinn owes Cam/
  end

  test "the games page filters to bets only" do
    Game.create!(mode: "singles", side_a_score: 8, side_b_score: 6,
      side_a_player_ids: [ @cam.id ], side_b_player_ids: [ @quinn.id ])

    get games_path
    assert_select "a[href^='/games/']", count: 2

    get games_path(bets: 1)
    assert_select "a[href^='/games/']", count: 1
  end

  test "the profile shows net profit" do
    get player_path(@cam)

    assert_select "dt", text: "Net profit"
    assert_select "dd", text: "+$5"
  end

  test "nested pages link back to their parent" do
    get player_path(@cam)
    assert_select "a[href='#{root_path(mode: "singles")}']", text: /Leaderboard/

    get game_path(@game)
    assert_select "a[href='#{games_path}']", text: /Games/

    get games_path(player_id: @cam.id)
    assert_select "a[href='#{player_path(@cam, mode: "singles")}']", text: /Cam/
  end
end
