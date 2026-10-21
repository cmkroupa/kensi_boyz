class DropPayments < ActiveRecord::Migration[8.1]
  def change
    drop_table :payments do |t|
      t.references :from_player, null: false, foreign_key: { to_table: :players }
      t.references :to_player, null: false, foreign_key: { to_table: :players }
      t.integer :cents, null: false

      t.timestamps
    end
  end
end
