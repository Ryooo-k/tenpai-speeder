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

  delegate :suit, :name, :number, :code, to: :base_tile
end
