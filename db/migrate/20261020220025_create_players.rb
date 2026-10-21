class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :name, null: false
      t.float :singles_rating, null: false, default: 1000.0
      t.float :doubles_rating, null: false, default: 1000.0
      t.integer :singles_games_count, null: false, default: 0
      t.integer :doubles_games_count, null: false, default: 0

      t.timestamps
    end
    add_index :players, :name, unique: true
  end
end
