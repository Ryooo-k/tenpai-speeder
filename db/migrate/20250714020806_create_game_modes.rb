class CreateGameModes < ActiveRecord::Migration[8.0]
  def change
    create_table :game_modes do |t|
      t.integer :mode_type, null: false

      t.timestamps
    end
  end
end
