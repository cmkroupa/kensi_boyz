require "test_helper"

class MoneylineTest < ActiveSupport::TestCase
  def terms(chance_a, stake = 500) = Moneyline.terms(chance_a: chance_a, underdog_stake_cents: stake)

  test "an even game is an even bet" do
    assert_equal 500, terms(0.5).favorite_stake_cents
  end

  test "the favourite risks more than the underdog" do
    result = terms(0.58)

    assert_equal "a", result.favorite_side
    assert_equal 700, result.favorite_stake_cents
    assert_equal 500, result.underdog_stake_cents
  end

  test "the favourite can be either side" do
    assert_equal "b", terms(0.3).favorite_side
  end

  test "stakes round to the quarter" do
    assert_equal 0, terms(0.62).favorite_stake_cents % Moneyline::STEP_CENTS
  end

  test "a lopsided game is capped at 90 percent" do
    assert_equal 4500, terms(0.99).favorite_stake_cents
  end
end
