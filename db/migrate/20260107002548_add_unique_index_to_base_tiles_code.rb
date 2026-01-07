class AddUniqueIndexToBaseTilesCode < ActiveRecord::Migration[8.0]
  def change
    add_index :base_tiles, :code, unique: true
  end
end
