# Settles everything one player owes another in one go.
class DebtSettlementsController < ApplicationController
  def create
    Debt.unpaid.where(debtor_id: params.expect(:debtor_id), creditor_id: params.expect(:creditor_id)).find_each(&:pay)
    redirect_back_or_to debts_path, notice: "Marked paid."
  end
end
