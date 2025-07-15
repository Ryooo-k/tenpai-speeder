class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.belongs_to :user, foreign_key: true
      t.belongs_to :ai, foreign_key: true
      t.belongs_to :game, foreign_key: true, null: false
      t.integer :seat_order, null: false

      t.timestamps
    end
  end
end
