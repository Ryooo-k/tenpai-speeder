class AddRinshanToHands < ActiveRecord::Migration[8.0]
  def change
    add_column :hands, :rinshan, :boolean, default: false
  end
end
