class RenameCalledToStolenInRivers < ActiveRecord::Migration[8.0]
  def change
    rename_column :rivers, :called, :stolen
  end
end
