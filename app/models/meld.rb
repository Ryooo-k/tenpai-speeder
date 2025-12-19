# frozen_string_literal: true

class Meld < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile

  validates :kind, presence: true
  validates :position, presence: true

  enum :kind, {
    pon: 0,
    chi: 1,
    ankan: 2,
    daiminkan: 3,
    kakan: 4
  }
  enum :from, {
    self: 0,
    shimocha: 1,
    toimen: 2,
    kamicha: 3
  }

  scope :sorted, -> { order(player_state_id: :desc).order(:position) }

  delegate :suit, :name, :number, :code, :aka?, to: :tile
end
