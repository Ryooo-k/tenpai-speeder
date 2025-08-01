class AddDrawCountAndKanCountToHonbas < ActiveRecord::Migration[8.0]
  def change
    add_column :honbas, :draw_count, :integer, default: 0
    add_column :honbas, :kan_count, :integer, default: 0
  end
end
