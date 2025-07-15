class CreateRules < ActiveRecord::Migration[8.0]
  def change
    create_table :rules do |t|
      t.boolean :aka_dora, null: false, default: true
      t.integer :round_type, null: false

      t.timestamps
    end
  end
end
