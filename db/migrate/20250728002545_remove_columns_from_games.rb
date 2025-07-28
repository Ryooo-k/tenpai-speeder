class RemoveColumnsFromGames < ActiveRecord::Migration[8.0]
  def change
    remove_column :games, :rule_id, :integer
    remove_column :games, :rule, :integer
    remove_column :games, :game_mode_id, :integer
  end
end
