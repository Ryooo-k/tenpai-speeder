# frozen_string_literal: true

class GameRecord < ApplicationRecord
  belongs_to :player
  belongs_to :honba, optional: true

  validates :player, presence: true
  validates :honba, presence: true, on: :update
  validates :score, presence: true

  scope :ordered, -> { order(:honba_id) }
end
