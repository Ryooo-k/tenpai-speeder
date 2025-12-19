# frozen_string_literal: true

class River < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile

  validates :tsumogiri, inclusion: { in: [ true, false ] }
  validates :stolen, inclusion: { in: [ true, false ] }
  validates :riichi, inclusion: { in: [ true, false ] }

  scope :not_stolen, -> { where(stolen: false) }

  delegate :suit, :name, :number, :code, :aka?, to: :tile

  def step_number = player_state.step.number
end
