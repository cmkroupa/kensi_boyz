# Marking a single debt paid is creating its payment; undoing it is destroying it.
class Debts::PaymentsController < ApplicationController
  before_action :set_debt

  def create
    @debt.pay
    redirect_back_or_to debts_path, notice: "Marked paid."
  end

  def destroy
    @debt.unpay
    redirect_back_or_to debts_path, notice: "Marked unpaid."
  end

  private
    def set_debt
      @debt = Debt.find(params[:debt_id])
    end
end
