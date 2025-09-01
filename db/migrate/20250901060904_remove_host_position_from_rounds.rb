class RemoveHostPositionFromRounds < ActiveRecord::Migration[8.0]
  def change
    remove_column :rounds, :host_position, :integer
  end
end
