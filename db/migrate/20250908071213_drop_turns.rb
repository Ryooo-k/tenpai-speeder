class DropTurns < ActiveRecord::Migration[8.0]
  def change
    drop_table :turns, if_exists: true
  end
end
