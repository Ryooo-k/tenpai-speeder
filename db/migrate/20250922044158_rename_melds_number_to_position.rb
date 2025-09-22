class RenameMeldsNumberToPosition < ActiveRecord::Migration[8.0]
  def change
    rename_column :melds, :number, :position
  end
end
