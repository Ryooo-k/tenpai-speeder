class AddCurrentStepNumberToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :current_step_number, :integer, default: 0, null: false
  end
end
