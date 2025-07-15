class CreateSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :steps do |t|
      t.belongs_to :turn, foreign_key: true, null: false
      t.integer :number, null: false

      t.timestamps
    end
  end
end
