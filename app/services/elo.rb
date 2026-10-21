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

  # Sit out longer than the grace period and your rating drifts back toward the
  # starting rating, a little more each idle week.
  DECAY_GRACE_DAYS = 7
  DECAY_PER_WEEK = 0.02

  def self.expected(rating, opponent_rating)
    1.0 / (1.0 + 10**((opponent_rating - rating) / SCALE))
  end

  # Points moving from loser to winner: K x margin multiplier x how surprising the win was.
  def self.transfer(winner_rating:, loser_rating:, winner_points:, loser_points:)
    surprise = 1.0 - expected(winner_rating, loser_rating)
    [ K * margin_multiplier(winner_rating - loser_rating, winner_points - loser_points) * surprise, MIN_TRANSFER ].max
  end

  # The rating after sitting idle, pulled toward BASE_RATING (never past it).
  # Smooth in time: no decay inside the grace period, then 2% of the gap per week.
  def self.decayed(rating, idle_days)
    overdue_weeks = [ idle_days - DECAY_GRACE_DAYS, 0 ].max / 7.0
    BASE_RATING + (rating - BASE_RATING) * (1.0 - DECAY_PER_WEEK)**overdue_weeks
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
