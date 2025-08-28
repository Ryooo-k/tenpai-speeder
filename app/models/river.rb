# frozen_string_literal: true

class River < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile

  validates :tsumogiri, inclusion: { in: [ true, false ] }
  validates :player_state, presence: true
  validates :tile, presence: true

  scope :ordered, -> { order(:created_at) }
end
