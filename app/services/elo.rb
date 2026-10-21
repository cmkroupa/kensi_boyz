# Chess-style Elo with a margin-of-victory bonus. The winner takes rating from
# the loser: a lot for beating someone stronger, little for beating someone
# weaker. The margin only ever adds to that, so a win never costs rating.
module Elo
  BASE_RATING = 1000.0
  K = 32.0
  SCALE = 400.0
  MIN_TRANSFER = 1.0

  def self.expected(rating, opponent_rating)
    1.0 / (1.0 + 10**((opponent_rating - rating) / SCALE))
  end

  # Points moving from loser to winner. 8-7 adds about 10% on top of the
  # chess amount, 8-0 doubles it.
  def self.transfer(winner_rating:, loser_rating:, winner_points:, loser_points:)
    base = K * (1.0 - expected(winner_rating, loser_rating))
    dominance = (winner_points - loser_points).to_f / winner_points
    [ base * (1.0 + dominance), MIN_TRANSFER ].max
  end
end
