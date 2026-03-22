class Player < ApplicationRecord
  has_many :won_games, class_name: "Game", foreign_key: "winner_id"
  has_many :lost_games, class_name: "Game", foreign_key: "loser_id"

  before_create :set_defaults

  private

  def set_defaults
    self.elo = 1200
    self.wins = 0
    self.losses = 0
  end
end
