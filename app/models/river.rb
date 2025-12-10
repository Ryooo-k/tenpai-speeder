# frozen_string_literal: true

class River < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile

  validates :player_state, presence: true
  validates :tile, presence: true
  validates :tsumogiri, inclusion: { in: [ true, false ] }
  validates :stolen, inclusion: { in: [ true, false ] }
  validates :riichi, inclusion: { in: [ true, false ] }

  scope :not_stolen, -> { where(stolen: false) }

  delegate :suit, :name, :number, :code, :aka?, to: :tile

end
