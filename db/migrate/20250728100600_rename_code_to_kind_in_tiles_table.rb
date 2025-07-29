class RenameCodeToKindInTilesTable < ActiveRecord::Migration[8.0]
  def change
    rename_column :tiles, :code, :kind
  end
end
