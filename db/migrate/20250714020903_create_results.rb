class CreateResults < ActiveRecord::Migration[8.0]
  def change
    create_table :results do |t|
      t.belongs_to :game, foreign_key: true, null: false
      t.belongs_to :player, foreign_key: true, null: false
      t.integer :score, null: false
      t.integer :rank, null: false

      t.timestamps
    end
  end
end
