class AddNotNullConstraintToGameModes < ActiveRecord::Migration[8.0]
  def change
    change_column_null :game_modes, :name, false
    change_column_null :game_modes, :description, false
  end
end
