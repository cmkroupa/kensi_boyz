# Betting money, derived from the games that had a bet and the payments made
# since. Nothing is stored per player, so editing or deleting a game fixes
# everyone's numbers.
class Ledger
  Line = Struct.new(:player, :net_cents, :won, :lost, :biggest_win_cents)
  Transfer = Struct.new(:from, :to, :cents)

  def self.lines = new.lines
  def self.transfers = new.transfers

  # Everyone's net winnings, best first.
  def lines
    @lines ||= Player.alphabetically.map { |player| line_for(player) }.sort_by { |line| [ -line.net_cents, line.player.name ] }
  end

  # The fewest payments that clear every debt: biggest debtor pays biggest creditor.
  def transfers
    creditors = owed(lines.select { |line| line.net_cents.positive? }) { |line| line.net_cents }
    debtors = owed(lines.select { |line| line.net_cents.negative? }) { |line| -line.net_cents }
    result = []

    while creditors.any? && debtors.any?
      cents = [ creditors.first.last, debtors.first.last ].min
      result << Transfer.new(debtors.first.first, creditors.first.first, cents)
      creditors.first[1] -= cents
      debtors.first[1] -= cents
      creditors.shift if creditors.first.last.zero?
      debtors.shift if debtors.first.last.zero?
    end

    result
  end

  private
    def owed(lines)
      lines.map { |line| [ line.player, yield(line) ] }.sort_by { |_, cents| -cents }
    end

    def line_for(player)
      results = bet_participations.select { |participation| participation.player_id == player.id }.map(&:bet_result_cents)
      Line.new(player, results.sum + settled_cents(player), results.count(&:positive?), results.count(&:negative?), results.max.to_i)
    end

    # Paying a debt moves you towards zero from below; receiving moves the other way.
    def settled_cents(player)
      payments.select { |payment| payment.from_player_id == player.id }.sum(&:cents) -
        payments.select { |payment| payment.to_player_id == player.id }.sum(&:cents)
    end

    def bet_participations
      @bet_participations ||= Participation.joins(:game).merge(Game.with_bet).includes(:game).to_a
    end

    def payments
      @payments ||= Payment.all.to_a
    end
end
