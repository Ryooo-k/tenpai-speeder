class CreateTurns < ActiveRecord::Migration[8.0]
  def change
    create_table :turns do |t|
      t.belongs_to :honba, foreign_key: true, null: false
      t.integer :number, null: false

      t.timestamps
    end
  end
end
