class CreateTileOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :tile_orders do |t|
      t.belongs_to :tile, foreign_key: true, null: false
      t.belongs_to :honba, foreign_key: true, null: false
      t.integer :order, null: false

      t.timestamps
    end
  end
end
