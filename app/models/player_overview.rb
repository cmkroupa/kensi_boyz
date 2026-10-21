# One player's headline numbers in a mode, computed from a single load of their
# results so a page of overviews doesn't re-query for every stat.
class PlayerOverview
  attr_reader :player, :mode

  def initialize(player, mode, net_cents: 0)
    @player = player
    @mode = mode
    @net_cents = net_cents
  end

  def results = @results ||= player.results(mode)

  def games = results.size
  def ranked? = games.positive?
  def wins = results.count(&:won?)
  def losses = games - wins
  def win_rate = ranked? ? wins.fdiv(games) : nil

  def goals_for = results.sum(&:points)
  def goals_against = results.sum(&:opponent_points)
  def clean_sheets = results.count { |result| result.opponent_points.zero? }

  attr_reader :net_cents

  def rating = player.rating(mode)
  def rank = player.rank(mode)
  def provisional? = player.provisional?(mode)
  def idle_days = player.idle_days(mode)

  def current_streak
    latest_first = results.reverse
    return Player::Stats::Streak.new(true, 0) if latest_first.empty?

    won = latest_first.first.won?
    Player::Stats::Streak.new(won, latest_first.take_while { |result| result.won? == won }.size)
  end

  def best_win_streak
    results.slice_when { |before, after| before.won? != after.won? }.select { |run| run.first.won? }.map(&:size).max || 0
  end
end
