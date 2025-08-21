class AddCurrentSeatNumberToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :current_seat_number, :integer, default: 0, null: false
  end
end
