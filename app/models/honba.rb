# frozen_string_literal: true

class Honba < ApplicationRecord
  belongs_to :round

  has_many :turns, dependent: :destroy
  has_many :tile_orders, dependent: :destroy
  has_many :game_records, dependent: :destroy

  validates :round, presence: true
  validates :number, presence: true
  validates :riichi_stick_count, presence: true

  after_create :create_tile_orders_and_turn

  def current_turn
    turns.order(:number).last
  end

  def top_tile
    order = draw_count - kan_count
    tile_orders.find_by(order:).tile
  end

  private

    def create_tile_orders_and_turn
      setup_tile_orders
      turns.create!
    end

    def setup_tile_orders
      shuffled_tiles = tiles.shuffle
      shuffled_tiles.each_with_index do |tile, order|
        tile_orders.create!(tile:, order:)
      end
    end

    def tiles
      round.game.tiles
    end

    def players
      round.game.players.ordered
    end
end
