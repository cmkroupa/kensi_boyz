# What the loser of a bet owes the winner, one record per bet so each can be
# marked paid (or unpaid again) on its own. Rebuilt from the game whenever it changes.
class Debt < ApplicationRecord
  belongs_to :game
  belongs_to :debtor, class_name: "Player"
  belongs_to :creditor, class_name: "Player"

  scope :unpaid, -> { where(paid_at: nil) }
  scope :paid, -> { where.not(paid_at: nil) }
  scope :involving, ->(player) { where(debtor: player).or(where(creditor: player)) }

  def paid? = paid_at.present?

  def pay
    update!(paid_at: Time.current)
  end

  def unpay
    update!(paid_at: nil)
  end
end
