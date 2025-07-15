class CreateBaseTiles < ActiveRecord::Migration[8.0]
  def change
    create_table :base_tiles do |t|
      t.integer :suit, null: false
      t.integer :number, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end
