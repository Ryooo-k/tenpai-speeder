class CreateAis < ActiveRecord::Migration[8.0]
  def change
    create_table :ais do |t|
      t.string :name, null: false
      t.string :version, null: false
      t.text :description

      t.timestamps
    end
  end
end
