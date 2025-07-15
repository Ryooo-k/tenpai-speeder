class CreateRounds < ActiveRecord::Migration[8.0]
  def change
    create_table :rounds do |t|
      t.belongs_to :game, foreign_key: true, null: false
      t.integer :number, null: false
      t.integer :host_position, null: false

      t.timestamps
    end
  end
end
