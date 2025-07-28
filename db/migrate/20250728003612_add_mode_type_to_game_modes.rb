class AddModeTypeToGameModes < ActiveRecord::Migration[8.0]
  def change
    add_column :game_modes, :mode_type, :integer, null: false
  end
end
