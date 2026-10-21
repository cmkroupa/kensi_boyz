require "test_helper"

class LedgerTest < ActiveSupport::TestCase
  setup do
    @cam, @quinn, @tyler, @evan = %w[ Cam Quinn Tyler Evan ].map { |name| Player.create!(name: name) }
  end

  def log(mode, a_players, b_players, a_score, b_score, bet: 0)
    Game.create!(mode: mode, side_a_score: a_score, side_b_score: b_score, bet_dollars: bet,
      side_a_player_ids: a_players.map(&:id), side_b_player_ids: b_players.map(&:id))
  end

  def net(player) = Ledger.lines.find { |line| line.player == player }.net_cents

  test "an even bet moves the stake from loser to winner" do
    log("singles", [ @cam ], [ @quinn ], 8, 3, bet: 5)

    assert_equal 500, net(@cam)
    assert_equal(-500, net(@quinn))
  end

  test "an underdog win pays what the favourite risked" do
    5.times { log("singles", [ @cam ], [ @quinn ], 8, 3) }
    game = log("singles", [ @cam ], [ @quinn ], 3, 8, bet: 5)

    assert_equal "a", game.favorite_side
    assert_operator game.favorite_stake_cents, :>, 500
    assert_equal game.favorite_stake_cents, net(@quinn)
    assert_equal(-game.favorite_stake_cents, net(@cam))
  end

  test "money is zero-sum in doubles" do
    log("doubles", [ @cam, @quinn ], [ @tyler, @evan ], 8, 3, bet: 5)

    assert_equal 0, Ledger.lines.sum(&:net_cents)
    assert_equal 500, net(@quinn)
    assert_equal(-500, net(@evan))
  end

  test "games without a bet leave money alone" do
    log("singles", [ @cam ], [ @quinn ], 8, 3)

    assert_equal 0, net(@cam)
    assert_not Game.last.bet?
  end

  test "the odds stay locked when earlier history changes" do
    first = log("singles", [ @cam ], [ @tyler ], 8, 1)
    game = log("singles", [ @cam ], [ @quinn ], 8, 3, bet: 5)
    stake = game.reload.favorite_stake_cents
    first.destroy

    assert_equal stake, game.reload.favorite_stake_cents
  end

  test "settling up lists the fewest payments and payments clear them" do
    log("singles", [ @cam ], [ @quinn ], 8, 3, bet: 5)
    transfer = Ledger.transfers.sole

    assert_equal [ @quinn, @cam, 500 ], [ transfer.from, transfer.to, transfer.cents ]

    Payment.create!(from_player: @quinn, to_player: @cam, cents: 500)

    assert_empty Ledger.transfers
    assert_equal 0, net(@cam)
  end

  test "a payment must be to someone else and positive" do
    assert_not Payment.new(from_player: @cam, to_player: @cam, cents: 100).valid?
    assert_not Payment.new(from_player: @cam, to_player: @quinn, cents: 0).valid?
  end
end
