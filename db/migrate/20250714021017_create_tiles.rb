class CreateTiles < ActiveRecord::Migration[8.0]
  def change
    create_table :tiles do |t|
      t.belongs_to :base_tile, foreign_key: true, null: false
      t.belongs_to :game, foreign_key: true, null: false
      t.integer :code, null: false
      t.boolean :aka, null: false, default: false

      t.timestamps
    end
  end
end
