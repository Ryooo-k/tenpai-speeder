class RemoveTurnFromStep < ActiveRecord::Migration[8.0]
  def change
    remove_reference :steps, :turn, foreign_key: true, index: true
  end
end
