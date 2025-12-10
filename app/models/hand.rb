# frozen_string_literal: true

class Hand < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile

  validates :player_state, presence: true
  validates :tile, presence: true
  validates :drawn, inclusion: { in: [ true, false ] }

  scope :sorted_base, -> {
    joins(tile: :base_tile)
      .includes(tile: :base_tile)
      .order('base_tiles.code ASC')
      .order('tile.kind ASC')
  }
  scope :sorted_with_drawn, -> {
    joins(tile: :base_tile)
      .includes(tile: :base_tile)
      .order(drawn: :asc)
      .order('base_tiles.code ASC')
      .order('tile.kind ASC')
  }

  delegate :suit, :name, :number, :code, :aka?, to: :tile
end
