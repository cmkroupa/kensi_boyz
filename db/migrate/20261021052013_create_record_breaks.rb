class CreateRecordBreaks < ActiveRecord::Migration[8.1]
  def change
    create_table :record_breaks do |t|
      t.references :game, null: false, foreign_key: true
      t.references :player, foreign_key: true
      t.string :key, null: false
      t.string :scope, null: false
      t.float :value, null: false

      t.timestamps
    end

    add_index :record_breaks, %i[ key scope ]
  end
end
