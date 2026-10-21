class CreateParticipations < ActiveRecord::Migration[8.1]
  def change
    create_table :participations do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :side, null: false
      t.float :rating_before, null: false, default: 1000.0
      t.float :rating_after, null: false, default: 1000.0

      t.timestamps
    end
    add_index :participations, [ :game_id, :player_id ], unique: true
  end
end
