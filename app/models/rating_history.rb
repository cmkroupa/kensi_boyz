# Rating-over-time series for charts, plotted against the time each game was played.
class RatingHistory
  COLOR = "#2563eb".freeze

  Series = Struct.new(:name, :color, :points)

  # Lines begin a day before the first game so the starting rating is visible.
  LEAD_IN = 1.day

  # A single player's line over time.
  def self.for_player(player, mode)
    results = player.results(mode)
    start = ((results.first&.game&.played_at || Time.current) - LEAD_IN).to_f
    line = [ [ start, Elo::BASE_RATING ] ] + results.map { |result| [ result.game.played_at.to_f, result.rating_after ] }
    line << [ Time.current.to_f, player.rating(mode) ] if results.any? && (player.rating(mode) - results.last.rating_after).abs > 0.5
    [ Series.new(player.name, COLOR, line) ]
  end

  # A 2v2 team's line: the average of both members' 2v2 ratings after each game together.
  def self.for_team(partnership)
    results = partnership.chronological
    return [] if results.empty?

    average = ->(result, field) { ([ result ] + result.teammates).sum(&field) / 2 }
    start = (results.first.game.played_at - LEAD_IN).to_f
    line = [ [ start, average.(results.first, :rating_before) ] ] +
      results.map { |result| [ result.game.played_at.to_f, average.(result, :rating_after) ] }
    [ Series.new(partnership.players.map(&:name).join(" & "), COLOR, line) ]
  end
end
