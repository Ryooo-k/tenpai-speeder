class CreatePlayerStates < ActiveRecord::Migration[8.0]
  def change
    create_table :player_states do |t|
      t.belongs_to :step, foreign_key: true, null: false
      t.belongs_to :player, foreign_key: true, null: false
      t.boolean :riichi, default: false

      t.timestamps
    end
  end
end
