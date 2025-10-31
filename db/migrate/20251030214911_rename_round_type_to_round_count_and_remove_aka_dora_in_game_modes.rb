class RenameRoundTypeToRoundCountAndRemoveAkaDoraInGameModes < ActiveRecord::Migration[8.0]
  def change
    rename_column :game_modes, :round_type, :round_count
    remove_column :game_modes, :aka_dora, :boolean
  end
end
