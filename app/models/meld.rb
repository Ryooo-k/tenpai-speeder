# frozen_string_literal: true

class Meld < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile

  validates :player_state, presence: true
  validates :tile, presence: true
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

  def suit
    tile.suit
  end

  def name
    tile.name
  end

  def number
    tile.number
  end

  def code
    tile.code
  end
end
