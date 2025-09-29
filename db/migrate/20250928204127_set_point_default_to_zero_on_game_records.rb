class SetPointDefaultToZeroOnGameRecords < ActiveRecord::Migration[8.0]
  def change
    change_column_default :game_records, :point, from: nil, to: 0
    change_column_null :game_records, :point, false
  end
end
