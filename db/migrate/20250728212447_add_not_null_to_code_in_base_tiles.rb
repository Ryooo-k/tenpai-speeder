class AddNotNullToCodeInBaseTiles < ActiveRecord::Migration[8.0]
  def change
    change_column_null :base_tiles, :code, false
  end
end
