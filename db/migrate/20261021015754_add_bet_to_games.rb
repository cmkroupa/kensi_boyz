class AddBetToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :underdog_stake_cents, :integer, default: 0, null: false
    add_column :games, :favorite_stake_cents, :integer, default: 0, null: false
    add_column :games, :favorite_side, :string
  end
end
