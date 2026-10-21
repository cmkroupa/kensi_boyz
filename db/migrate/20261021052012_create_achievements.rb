class CreateAchievements < ActiveRecord::Migration[8.1]
  def change
    create_table :achievements do |t|
      t.references :player, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.string :key, null: false
      t.string :scope, null: false

      t.timestamps
    end

    add_index :achievements, %i[ player_id key scope ], unique: true
  end
end
