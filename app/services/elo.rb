# Chess-style Elo with a margin-of-victory tweak: the "actual score" blends
# the win/loss result with the share of points won, so 8-7 moves ratings far
# less than 8-1.
module Elo
  BASE_RATING = 1000.0
  PROVISIONAL_GAMES = 10
  PROVISIONAL_K = 40.0
  SETTLED_K = 24.0

  # New players move fast until their rating has had time to settle.
  def self.k_factor(games_played)
    games_played < PROVISIONAL_GAMES ? PROVISIONAL_K : SETTLED_K
  end

  def self.expected(rating, opponent_rating)
    1.0 / (1.0 + 10**((opponent_rating - rating) / 400.0))
  end

  # 0.5 for the result + 0.5 for the share of points: a narrow loss still
  # earns a decent score, a blowout win earns nearly a full one.
  def self.actual(points, opponent_points)
    result = points > opponent_points ? 1.0 : 0.0
    0.5 * result + 0.5 * points / (points + opponent_points)
  end

  def self.delta(rating:, opponent_rating:, points:, opponent_points:, games_played:)
    k_factor(games_played) * (actual(points, opponent_points) - expected(rating, opponent_rating))
  end
end
