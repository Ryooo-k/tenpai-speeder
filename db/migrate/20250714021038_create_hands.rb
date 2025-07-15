class CreateHands < ActiveRecord::Migration[8.0]
  def change
    create_table :hands do |t|
      t.belongs_to :player_state, foreign_key: true, null: false
      t.belongs_to :tile, foreign_key: true, null: false

      t.timestamps
    end
  end
end
