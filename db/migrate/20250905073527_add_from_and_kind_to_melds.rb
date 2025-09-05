class AddFromAndKindToMelds < ActiveRecord::Migration[8.0]
  def change
    add_column :melds, :from, :integer
    add_column :melds, :kind, :integer, null: false
  end
end
