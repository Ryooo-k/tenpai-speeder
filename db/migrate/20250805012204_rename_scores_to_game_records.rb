class RenameScoresToGameRecords < ActiveRecord::Migration[8.0]
  def change
    rename_table :scores, :game_records
  end
end
