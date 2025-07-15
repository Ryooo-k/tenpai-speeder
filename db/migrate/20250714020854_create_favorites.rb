class CreateFavorites < ActiveRecord::Migration[8.0]
  def change
    create_table :favorites do |t|
      t.belongs_to :user, foreign_key: true, null: false
      t.belongs_to :game, foreign_key: true, null: false

      t.timestamps
    end
  end
end
