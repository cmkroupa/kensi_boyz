# Chess-style Elo with the margin-of-victory multiplier from FiveThirtyEight's
# NFL ratings. The winner takes rating from the loser: a lot for beating someone
# stronger, little for beating someone weaker. The margin only ever adds to that,
# so a win never costs rating.
module Elo
  BASE_RATING = 1000.0
  K = 24.0
  SCALE = 400.0
  MIN_TRANSFER = 1.0

  # A player's first games in a mode move their rating faster while it settles.
  PROVISIONAL_GAMES = 10
  PROVISIONAL_BOOST = 1.5

  # Fewer games than this and a rating is shown with a "?".
  UNSETTLED_GAMES = 5

  def self.expected(rating, opponent_rating)
    1.0 / (1.0 + 10**((opponent_rating - rating) / SCALE))
  end

  # Points moving from loser to winner: K x margin multiplier x how surprising the win was.
  def self.transfer(winner_rating:, loser_rating:, winner_points:, loser_points:)
    surprise = 1.0 - expected(winner_rating, loser_rating)
    [ K * margin_multiplier(winner_rating - loser_rating, winner_points - loser_points) * surprise, MIN_TRANSFER ].max
  end

  def self.provisional_boost(games_played)
    games_played < PROVISIONAL_GAMES ? PROVISIONAL_BOOST : 1.0
  end

  # ln(margin + 1) rewards bigger wins with diminishing returns. The second term
  # is 538's autocorrelation fix: favourites win by more, so their margins count
  # a little less and an underdog's a little more.
  def self.margin_multiplier(rating_gap, margin)
    Math.log(margin + 1) * 2.2 / ([ rating_gap, -1000.0 ].max * 0.001 + 2.2)
  end
end
