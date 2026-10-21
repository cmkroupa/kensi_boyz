# Per-mode results derived from a player's participations: record, streaks,
# margins and rating history.
module Player::Stats
  extend ActiveSupport::Concern

  Streak = Struct.new(:won, :length) do
    def label = length.zero? ? "—" : "#{length}#{won ? 'W' : 'L'}"
  end

  # Oldest first, so streaks and charts can walk forward in time.
  def results(mode)
    participations.joins(:game).where(games: { mode: Game.modes.fetch(mode) })
      .includes(game: { participations: :player }).order("games.played_at, games.id").to_a
  end

  def wins(mode) = results(mode).count(&:won?)
  def losses(mode) = results(mode).count { |result| !result.won? }

  def win_rate(mode)
    all = results(mode)
    all.empty? ? nil : all.count(&:won?).fdiv(all.size)
  end

  # Goals scored and conceded across every game, and games where nothing was conceded.
  def goals_for(mode) = results(mode).sum(&:points)
  def goals_against(mode) = results(mode).sum(&:opponent_points)
  def clean_sheets(mode) = results(mode).count { |result| result.opponent_points.zero? }

  def current_streak(mode)
    latest_first = results(mode).reverse
    return Streak.new(true, 0) if latest_first.empty?

    won = latest_first.first.won?
    Streak.new(won, latest_first.take_while { |result| result.won? == won }.size)
  end

  def longest_win_streak(mode)
    results(mode).slice_when { |before, after| before.won? != after.won? }
      .select { |run| run.first.won? }.map(&:size).max || 0
  end

  def rating_history(mode)
    [ Elo::BASE_RATING ] + results(mode).map(&:rating_after)
  end
end
