# frozen_string_literal: true

class Hand < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile

  validates :player_state, presence: true
  validates :tile, presence: true
  validates :drawn, inclusion: { in: [ true, false ] }

  scope :sorted, -> {
    joins(tile: :base_tile)
      .order(drawn: :asc)
      .order('base_tiles.code ASC', 'tile.kind ASC')
  }
end
