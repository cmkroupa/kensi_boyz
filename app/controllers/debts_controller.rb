class DebtsController < ApplicationController
  PAID_SHOWN = 20

  def index
    @players = Player.alphabetically
    @player = Player.find_by(id: params[:player_id])
    debts = Debt.includes(:debtor, :creditor, game: { participations: :player })
    debts = debts.involving(@player) if @player

    @pairs = debts.unpaid.group_by { |debt| [ debt.debtor, debt.creditor ] }
      .map { |(debtor, creditor), owed| [ debtor, creditor, owed.sort_by { |debt| debt.game.played_at }.reverse ] }
      .sort_by { |_, _, owed| -owed.sum(&:cents) }
    @paid = debts.paid.order(paid_at: :desc).limit(PAID_SHOWN)
  end
end
