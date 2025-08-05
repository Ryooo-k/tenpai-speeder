class AddDefaultsToRounds < ActiveRecord::Migration[8.0]
  def change
    change_column_default :rounds, :number, 0
    change_column_default :rounds, :host_position, 0
  end
end
