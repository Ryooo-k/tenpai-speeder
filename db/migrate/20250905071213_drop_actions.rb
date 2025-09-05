class DropActions < ActiveRecord::Migration[8.0]
  def change
    drop_table :actions
  end
end
