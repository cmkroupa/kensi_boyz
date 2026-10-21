# How well the predictor would have called every game, using each game's ratings
# going in. It's a backtest with the current formula, so changing the Elo settings
# changes this history too. Toss-ups (exactly 50%) are left out of the pick count.
class PredictorAccuracy
  BUCKET_EDGES = [ 0.5, 0.6, 0.7, 0.8, 0.9, 1.0001 ].freeze
  # Below this many games the numbers bounce around too much to mean anything.
  MIN_GAMES = 30

  Call = Struct.new(:winner_chance, :predicted_margin, :actual_margin) do
    def favorite_chance = [ winner_chance, 1 - winner_chance ].max
    def toss_up? = winner_chance == 0.5
    def favorite_won? = winner_chance >= 0.5
  end
  Bucket = Struct.new(:from, :to, :games, :favorite_wins, :expected)

  attr_reader :calls

  def initialize(games = Game.preloaded.chronologically)
    @calls = games.map { |game| call_for(game) }
  end

  def games = calls.size
  def enough_games? = games >= MIN_GAMES
  def toss_ups = calls.count(&:toss_up?)

  def called = calls.reject(&:toss_up?)
  def correct_picks = called.count(&:favorite_won?)
  def pick_accuracy = called.empty? ? nil : correct_picks.fdiv(called.size)

  # Mean squared miss of the winner's win chance (a coin flip scores 0.25; lower is better).
  def brier_score = calls.empty? ? nil : calls.sum { |call| (1 - call.winner_chance)**2 }.fdiv(games)

  # How far off the predicted margin was, on average, in points.
  def margin_error = calls.empty? ? nil : calls.sum { |call| (call.predicted_margin - call.actual_margin).abs }.fdiv(games)

  # When it said 60-70%, did the favourite win about that often?
  def calibration
    BUCKET_EDGES.each_cons(2).filter_map do |from, to|
      inside = called.select { |call| call.favorite_chance >= from && call.favorite_chance < to }
      next if inside.empty?

      Bucket.new(from, [ to, 1.0 ].min, inside.size, inside.count(&:favorite_won?), inside.sum(&:favorite_chance).fdiv(inside.size))
    end
  end

  private
    def call_for(game)
      breakdown = game.elo_breakdown
      predicted_margin = Prediction::TABLE_MAX - Prediction.underdog_points_for(breakdown.winner_rating - breakdown.loser_rating)
      Call.new(breakdown.chance, predicted_margin, breakdown.chance >= 0.5 ? game.margin : -game.margin)
    end
end
