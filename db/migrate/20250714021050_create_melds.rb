class CreateMelds < ActiveRecord::Migration[8.0]
  def change
    create_table :melds do |t|
      t.belongs_to :player_state, foreign_key: true, null: false
      t.belongs_to :tile, foreign_key: true, null: false
      t.belongs_to :action, foreign_key: true, null: false
      t.integer :meld_type, null: false

      t.timestamps
    end
  end
end
