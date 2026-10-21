# Betting results, derived from the games that had a bet. Nothing is stored per
# player, so editing or deleting a game fixes everyone's numbers. Debts (who has
# actually paid) are tracked separately; net profit ignores whether money has changed hands.
class Ledger
  Line = Struct.new(:player, :net_cents, :won, :lost, :biggest_win_cents)

  def self.lines = new.lines

  # Everyone's net profit, best first.
  def lines
    @lines ||= Player.alphabetically.map { |player| line_for(player) }.sort_by { |line| [ -line.net_cents, line.player.name ] }
  end

  private
    def line_for(player)
      results = bet_participations.select { |participation| participation.player_id == player.id }.map(&:bet_result_cents)
      Line.new(player, results.sum, results.count(&:positive?), results.count(&:negative?), results.max.to_i)
    end

    def bet_participations
      @bet_participations ||= Participation.joins(:game).merge(Game.with_bet).includes(:game).to_a
    end
end
