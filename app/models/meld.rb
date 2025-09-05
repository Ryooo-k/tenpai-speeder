# frozen_string_literal: true

class Meld < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile

  validates :player_state, presence: true
  validates :tile, presence: true
  validates :kind, presence: true

  enum :kind, {
    pon: 0,
    chi: 1,
    ankan: 2,
    daiminkan: 3,
    kakan: 4
  }
  enum :from, {
    self: 0,
    kamicha: 1,
    toimen: 2,
    shimocha: 3
  }
end
