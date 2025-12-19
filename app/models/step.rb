# frozen_string_literal: true

class Step < ApplicationRecord
  belongs_to :honba

  has_many :player_states, -> { order(:step_id) }, dependent: :destroy

  before_validation :snapshot_honba_counters, on: :create

  validates :number, presence: true

  private

    def snapshot_honba_counters
      return unless honba

      self.draw_count = honba.draw_count
      self.kan_count = honba.kan_count
      self.riichi_stick_count = honba.riichi_stick_count
    end
end
