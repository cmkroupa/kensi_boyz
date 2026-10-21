# A fixed 2v2 pair and how they do together.
class Partnership
  attr_reader :players, :results

  def initialize(players, results)
    @players = players
    @results = results
  end

  # Every pair that has played a 2v2 game together, best win rate first.
  def self.all
    Participation.joins(:game).where(games: { mode: Game.modes.fetch("doubles") })
      .includes(:player, game: { participations: :player })
      .group_by { |participation| pair_ids(participation) }
      .map { |ids, results| build(ids, results) }
      .sort_by { |pair| [ -pair.win_rate, -pair.games, pair.players.map(&:name) ] }
  end

  def self.between(first, second)
    all.find { |pair| pair.players.sort_by(&:id) == [ first, second ].sort_by(&:id) }
  end

  def self.for(player)
    all.select { |pair| pair.players.include?(player) }
  end

  def self.pair_ids(participation)
    [ participation.player_id, *participation.teammates.map(&:player_id) ].sort
  end

  # Each game shows up once per pair member; keep the lowest id's row so games count once.
  def self.build(ids, results)
    own = results.select { |result| result.player_id == ids.first }
    pair = [ own.first.player, own.first.teammates.first.player ].sort_by(&:name)
    new(pair, own)
  end

  # "3-7" style id pair used in URLs.
  def to_param = players.map(&:id).sort.join("-")

  def chronological = results.sort_by { |result| [ result.game.played_at, result.game_id ] }

  def current_streak
    latest_first = chronological.reverse
    return Player::Stats::Streak.new(true, 0) if latest_first.empty?

    won = latest_first.first.won?
    Player::Stats::Streak.new(won, latest_first.take_while { |result| result.won? == won }.size)
  end

  def longest_win_streak
    chronological.slice_when { |before, after| before.won? != after.won? }
      .select { |run| run.first.won? }.map(&:size).max || 0
  end

  def goals_for = results.sum(&:points)
  def goals_against = results.sum(&:opponent_points)
  def clean_sheets = results.count { |result| result.opponent_points.zero? }

  def games = results.size
  def wins = results.count(&:won?)
  def losses = games - wins
  def win_rate = wins.fdiv(games)
  def average_rating_change = results.sum(&:delta).fdiv(games)
end
