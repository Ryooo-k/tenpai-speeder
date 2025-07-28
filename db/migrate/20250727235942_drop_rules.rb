class DropRules < ActiveRecord::Migration[8.0]
  def change
    drop_table :rules
  end
end
