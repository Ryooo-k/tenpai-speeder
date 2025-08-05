class AddDefaultsToSteps < ActiveRecord::Migration[8.0]
  def change
        change_column_default :steps, :number, 0
  end
end
