class AddNumberToMelds < ActiveRecord::Migration[8.0]
  def change
    add_column :melds, :number, :integer, null: false
  end
end
