require "test_helper"

class DebtTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn, @tyler, @evan = %w[ Cam Quinn Tyler Evan ].map { |name| Player.create!(name: name) }
  end

  def log(mode, a_players, b_players, a_score, b_score, bet: 0)
    Game.create!(mode: mode, side_a_score: a_score, side_b_score: b_score, bet_dollars: bet,
      side_a_player_ids: a_players.map(&:id), side_b_player_ids: b_players.map(&:id))
  end

  test "a bet leaves the loser owing the winner" do
    game = log("singles", [ @cam ], [ @quinn ], 8, 3, bet: 5)
    debt = game.debts.sole

    assert_equal [ @quinn, @cam, 500 ], [ debt.debtor, debt.creditor, debt.cents ]
    assert_not debt.paid?
  end

  test "no bet means no debt" do
    assert_empty log("singles", [ @cam ], [ @quinn ], 8, 3).debts
  end

  test "doubles pairs each loser with a winner" do
    game = log("doubles", [ @cam, @quinn ], [ @tyler, @evan ], 8, 3, bet: 5)

    assert_equal 2, game.debts.size
    assert_equal [ @tyler, @evan ].map(&:id).sort, game.debts.map(&:debtor_id).sort
    assert_equal [ @cam, @quinn ].map(&:id).sort, game.debts.map(&:creditor_id).sort
  end

  test "debts can be marked paid and unpaid" do
    debt = log("singles", [ @cam ], [ @quinn ], 8, 3, bet: 5).debts.sole
    debt.pay

    assert_predicate debt, :paid?
    assert_empty Debt.unpaid

    debt.unpay

    assert_not debt.paid?
    assert_equal 1, Debt.unpaid.count
  end

  test "correcting the score to flip the winner flips the debt" do
    game = log("singles", [ @cam ], [ @quinn ], 8, 3, bet: 5)
    game.update!(side_a_score: 3, side_b_score: 8)

    assert_equal [ @cam, @quinn ], [ game.debts.sole.debtor, game.debts.sole.creditor ]
  end

  test "a paid debt stays paid when the score changes but the result does not" do
    game = log("singles", [ @cam ], [ @quinn ], 8, 3, bet: 5)
    game.debts.sole.pay
    game.update!(side_a_score: 8, side_b_score: 5)

    assert_predicate game.debts.sole, :paid?
  end

  test "deleting a game removes its debts" do
    log("singles", [ @cam ], [ @quinn ], 8, 3, bet: 5).destroy

    assert_equal 0, Debt.count
  end
end
