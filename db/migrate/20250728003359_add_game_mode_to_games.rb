class AddGameModeToGames < ActiveRecord::Migration[8.0]
  def change
    add_reference :games, :game_mode, null: false, foreign_key: true
  end
end
