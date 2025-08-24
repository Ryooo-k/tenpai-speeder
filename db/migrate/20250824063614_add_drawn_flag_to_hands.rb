class AddDrawnFlagToHands < ActiveRecord::Migration[8.0]
  def change
    add_column :hands, :drawn, :boolean, default: false, null: false
  end
end
