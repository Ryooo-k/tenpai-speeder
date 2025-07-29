class AddCodeToBaseTiles < ActiveRecord::Migration[8.0]
  def change
    add_column :base_tiles, :code, :integer
  end
end
