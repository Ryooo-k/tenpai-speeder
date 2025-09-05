class RemoveActionFromMelds < ActiveRecord::Migration[8.0]
  def change
    remove_reference :melds, :action, foreign_key: true, index: true
  end
end
