class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.integer :mode, null: false
      t.integer :side_a_score, null: false
      t.integer :side_b_score, null: false
      t.datetime :played_at, null: false

      t.timestamps
    end
    add_index :games, :played_at
  end
end
