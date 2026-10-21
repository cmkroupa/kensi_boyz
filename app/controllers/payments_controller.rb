class PaymentsController < ApplicationController
  def create
    payment = Payment.new(params.expect(payment: %i[ from_player_id to_player_id cents ]))

    if payment.save
      redirect_to leaderboard_path(view: "money"), notice: "Payment recorded."
    else
      redirect_to leaderboard_path(view: "money"), alert: payment.errors.full_messages.to_sentence
    end
  end
end
