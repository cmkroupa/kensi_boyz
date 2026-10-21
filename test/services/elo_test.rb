require "test_helper"

class EloTest < ActiveSupport::TestCase
  test "equal ratings expect a coin flip" do
    assert_in_delta 0.5, Elo.expected(1000, 1000)
  end

  test "a 400 point favourite is expected to win about 91%" do
    assert_in_delta 0.909, Elo.expected(1400, 1000), 0.001
  end

  test "a blowout scores higher than a nail-biter" do
    assert_operator Elo.actual(8, 1), :>, Elo.actual(8, 7)
  end

  test "a narrow loss scores higher than a blowout loss" do
    assert_operator Elo.actual(7, 8), :>, Elo.actual(1, 8)
  end

  test "new players move faster than settled ones" do
    assert_operator Elo.k_factor(0), :>, Elo.k_factor(Elo::PROVISIONAL_GAMES)
  end
end
