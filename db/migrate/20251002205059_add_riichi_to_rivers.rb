class AddRiichiToRivers < ActiveRecord::Migration[8.0]
  def change
    add_column :rivers, :riichi, :boolean, default: false
  end
end
