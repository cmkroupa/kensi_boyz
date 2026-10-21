# Forecasts a matchup from current ratings: who wins, by roughly what score,
# and how confident the model is. Scores are capped at the table's 8.
class Prediction
  TABLE_MAX = 8
  POINT_SCALE = 200.0

  attr_reader :mode, :side_a, :side_b

  def initialize(mode:, side_a:, side_b:)
    @mode = mode
    @side_a = side_a
    @side_b = side_b
  end

  def valid?
    size = Game::PLAYERS_PER_SIDE[mode]
    side_a.size == size && side_b.size == size && (side_a & side_b).empty?
  end

  def rating_a = average_rating(side_a)
  def rating_b = average_rating(side_b)

  # Chance that side A wins, straight from the Elo expectation.
  def chance_a = Elo.expected(rating_a, rating_b)

  def favorite = chance_a >= 0.5 ? side_a : side_b
  def underdog = favorite.equal?(side_a) ? side_b : side_a

  # Rating points each player on a team gains if that team wins at the predicted score.
  def elo_change_if_wins(team)
    winner, loser = team.equal?(side_a) ? [ rating_a, rating_b ] : [ rating_b, rating_a ]
    Elo.transfer(winner_rating: winner, loser_rating: loser, winner_points: TABLE_MAX, loser_points: underdog_points)
  end

  def confidence = [ chance_a, 1 - chance_a ].max

  # Rating gaps between roommates are small, so a win chance of 55-65% would
  # make every score 8-6 or 8-7. Points are spread more sharply than wins:
  # the favorite's expected share of points uses a tighter Elo scale, and the
  # underdog scores TABLE_MAX * (1 - share) / share. Even matchups land on 8-7.
  def underdog_points
    (TABLE_MAX * (1 - favorite_point_share) / favorite_point_share).round.clamp(0, TABLE_MAX - 1)
  end

  def score_a = favorite.equal?(side_a) ? TABLE_MAX : underdog_points
  def score_b = favorite.equal?(side_a) ? underdog_points : TABLE_MAX

  private
    def favorite_point_share
      1.0 / (1.0 + 10**(-(rating_a - rating_b).abs / POINT_SCALE))
    end

    def average_rating(players)
      players.sum { |player| player.rating(mode) } / players.size
    end
end
