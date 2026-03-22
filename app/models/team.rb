class Team < ApplicationRecord
  belongs_to :player1, class_name: "Player"
  belongs_to :player2, class_name: "Player"

  has_many :won_team_games, class_name: "TeamGame", foreign_key: "winning_team_id"
  has_many :lost_team_games, class_name: "TeamGame", foreign_key: "losing_team_id"

  def self.find_or_create_for(player_a, player_b)
    find_by(player1_id: player_a.id, player2_id: player_b.id) ||
      find_by(player1_id: player_b.id, player2_id: player_a.id) ||
      create!(player1: player_a, player2: player_b)
  end

  def avg_elo
    (player1.elo + player2.elo) / 2.0
  end

  def players
    [ player1, player2 ]
  end
end
