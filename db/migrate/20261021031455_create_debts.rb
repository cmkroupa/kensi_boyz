class CreateDebts < ActiveRecord::Migration[8.1]
  def change
    create_table :debts do |t|
      t.references :game, null: false, foreign_key: true
      t.references :debtor, null: false, foreign_key: { to_table: :players }
      t.references :creditor, null: false, foreign_key: { to_table: :players }
      t.integer :cents, null: false
      t.datetime :paid_at

      t.timestamps
    end
  end
end
