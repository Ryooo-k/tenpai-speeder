class ChangeDefaultScoreInScores < ActiveRecord::Migration[8.0]
  def change
    change_column_default :scores, :score, 25000
  end
end
