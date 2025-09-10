class AddCalledToRivers < ActiveRecord::Migration[8.0]
  def change
    add_column :rivers, :called, :boolean, default: false
  end
end
