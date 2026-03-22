class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :name
      t.integer :elo
      t.integer :wins
      t.integer :losses

      t.timestamps
    end
  end
end
