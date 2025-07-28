class AddColumnsToGameModes < ActiveRecord::Migration[8.0]
  def change
    add_column :game_modes, :description, :text
    add_column :game_modes, :round_type, :integer, null: false
    add_column :game_modes, :aka_dora, :boolean, default: true, null: false
  end
end
