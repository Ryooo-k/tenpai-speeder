class CreateHonbas < ActiveRecord::Migration[8.0]
  def change
    create_table :honbas do |t|
      t.belongs_to :round, foreign_key: true, null: false
      t.integer :number, null: false, default: 0
      t.integer :riichi_stick_count, null: false, default: 0

      t.timestamps
    end
  end
end
