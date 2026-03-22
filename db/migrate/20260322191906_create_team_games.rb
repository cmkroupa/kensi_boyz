class CreateTeamGames < ActiveRecord::Migration[8.0]
  def change
    create_table :team_games do |t|
      t.references :winning_team, null: false, foreign_key: { to_table: :teams }
      t.references :losing_team, null: false, foreign_key: { to_table: :teams }
      t.integer :winner_score
      t.integer :loser_score
      t.datetime :played_at

      t.timestamps
    end
  end
end
