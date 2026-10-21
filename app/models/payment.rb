# Cash actually handed over to settle up what bets left owing.
class Payment < ApplicationRecord
  belongs_to :from_player, class_name: "Player"
  belongs_to :to_player, class_name: "Player"

  validates :cents, numericality: { only_integer: true, greater_than: 0 }
  validate :players_differ

  private
    def players_differ
      errors.add(:base, "Can't pay yourself") if from_player_id == to_player_id
    end
end
