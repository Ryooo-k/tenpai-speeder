# frozen_string_literal: true

class Tile < ApplicationRecord
  belongs_to :game
  belongs_to :base_tile

  has_many :tile_orders, dependent: :destroy
  has_many :hands, dependent: :destroy
  has_many :rivers, dependent: :destroy
  has_many :melds, dependent: :destroy

  validates :kind, presence: true
  validates :aka, inclusion: { in: [ true, false ] }

  def suit
    base_tile.suit
  end

  def name
    base_tile.name
  end

  def number
    base_tile.number
  end

  def code
    base_tile.code
  end
end
