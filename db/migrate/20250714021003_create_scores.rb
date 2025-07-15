class CreateScores < ActiveRecord::Migration[8.0]
  def change
    create_table :scores do |t|
      t.belongs_to :player, foreign_key: true, null: false
      t.belongs_to :honba, foreign_key: true, null: false
      t.integer :score, null: false
      t.integer :point

      t.timestamps
    end
  end
end
