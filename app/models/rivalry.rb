# Head-to-head record between two players across games where they faced each other.
class Rivalry
  attr_reader :player, :other, :mode

  def initialize(player, other, mode:)
    @player = player
    @other = other
    @mode = mode
  end

  def results
    @results ||= player.results(mode)
      .select { |result| result.opponents.any? { |opponent| opponent.player_id == other.id } }
  end

  def wins = results.count(&:won?)
  def losses = results.count { |result| !result.won? }
  def games = results.size
  def win_rate = wins.fdiv(games)
end
