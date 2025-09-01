# frozen_string_literal: true

class Honba < ApplicationRecord
  MAX_DRAW_COUNT = 122
  DORA_INDICATOR_ORDER_RANGE = (122..126)

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

  def name
    number_kanji = number.to_s.tr('0123456789', '〇一二三四五六七八九')
    "#{number_kanji}本場"
  end

  def remaining_tile_count
    total_draw_count = draw_count + kan_count
    MAX_DRAW_COUNT - total_draw_count
  end

  def dora_indicator_tiles
    dora_tiles = tile_orders.where(order: DORA_INDICATOR_ORDER_RANGE).order(:order).map(&:tile)
    dora_tiles[..kan_count]
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
