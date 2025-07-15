# frozen_string_literal: true

class Hand < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile

  validates :player_states, presence: true
  validates :tile, presence: true
end
