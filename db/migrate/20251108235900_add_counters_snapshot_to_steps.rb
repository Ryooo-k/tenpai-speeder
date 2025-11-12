# frozen_string_literal: true

class AddCountersSnapshotToSteps < ActiveRecord::Migration[8.0]
  def change
    add_column :steps, :draw_count, :integer, null: false
    add_column :steps, :kan_count, :integer, null: false
    add_column :steps, :riichi_stick_count, :integer, null: false
  end
end
