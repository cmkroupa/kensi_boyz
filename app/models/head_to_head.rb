# The history between two exact sides: two players in 1v1, or two fixed pairs in
# 2v2. Everything is from side A's point of view, then mirrored for side B.
class HeadToHead
  SECOND_COLOR = "#64748b".freeze
  RECENT_MEETINGS = 8

  Meeting = Struct.new(:game, :a_won, :a_points, :b_points) do
    def margin = (a_points - b_points).abs
  end
  Streak = Struct.new(:side_a, :length)

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

  # Oldest first.
  def meetings
    @meetings ||= Game.where(mode: mode).preloaded.chronologically.filter_map { |game| meeting_for(game) }
  end

  def games = meetings.size
  def a_wins = meetings.count(&:a_won)
  def b_wins = games - a_wins
  def a_win_rate = games.zero? ? nil : a_wins.fdiv(games)

  def average_points(side)
    return if games.zero?

    meetings.sum { |meeting| side == :a ? meeting.a_points : meeting.b_points }.fdiv(games)
  end

  def average_win_margin(side)
    wins = meetings.select { |meeting| meeting.a_won == (side == :a) }
    wins.sum(&:margin).fdiv(wins.size) if wins.any?
  end

  def biggest_win(side)
    meetings.select { |meeting| meeting.a_won == (side == :a) }.max_by { |meeting| [ meeting.margin, meeting.game.played_at ] }
  end

  def current_streak
    return if meetings.empty?

    latest = meetings.last.a_won
    Streak.new(latest, meetings.reverse.take_while { |meeting| meeting.a_won == latest }.size)
  end

  def recent = meetings.last(RECENT_MEETINGS).reverse

  def prediction = Prediction.new(mode: mode, side_a: side_a, side_b: side_b)

  # Each side's rating over time, so the two lines can be read against each other.
  def series
    [ line_for(side_a, RatingHistory::COLOR), line_for(side_b, SECOND_COLOR) ].compact
  end

  private
    def ids(players) = players.map(&:id).sort

    def meeting_for(game)
      a = ids(game.participants_on("a").map(&:player))
      b = ids(game.participants_on("b").map(&:player))
      if a == ids(side_a) && b == ids(side_b)
        Meeting.new(game, game.winner_side == "a", game.side_a_score, game.side_b_score)
      elsif a == ids(side_b) && b == ids(side_a)
        Meeting.new(game, game.winner_side == "b", game.side_b_score, game.side_a_score)
      end
    end

    def line_for(players, color)
      series = if players.one?
        RatingHistory.for_player(players.first, mode).first
      else
        pair = Partnership.between(*players)
        RatingHistory.for_team(pair).first if pair
      end
      RatingHistory::Series.new(series.name, color, series.points) if series && series.points.size > 1
    end
end
