class CreateActions < ActiveRecord::Migration[8.0]
  def change
    create_table :actions do |t|
      t.belongs_to :step, foreign_key: true, null: false
      t.belongs_to :player, foreign_key: true, null: false
      t.belongs_to :from_player, foreign_key: { to_table: :players }
      t.integer :action_type, null: false

      t.timestamps
    end
  end
end
