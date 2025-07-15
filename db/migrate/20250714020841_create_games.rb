class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.belongs_to :user, foreign_key: true, null: false
      t.belongs_to :game_mode, foreign_key: true, null: false
      t.belongs_to :rule, foreign_key: true, null: false

      t.timestamps
    end
  end
end
