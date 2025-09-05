# frozen_string_literal: true

class Meld < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile

  validates :player_state, presence: true
  validates :tile, presence: true
end
