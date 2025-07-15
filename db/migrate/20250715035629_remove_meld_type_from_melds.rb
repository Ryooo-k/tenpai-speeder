class RemoveMeldTypeFromMelds < ActiveRecord::Migration[8.0]
  def change
    remove_column :melds, :meld_type, :integer
  end
end
