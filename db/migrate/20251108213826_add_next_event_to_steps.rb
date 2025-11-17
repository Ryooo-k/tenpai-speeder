class AddNextEventToSteps < ActiveRecord::Migration[8.0]
  def change
    add_column :steps, :next_event, :string
  end
end
