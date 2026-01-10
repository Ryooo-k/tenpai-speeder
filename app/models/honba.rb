# frozen_string_literal: true

class Honba < ApplicationRecord
  MAX_DRAW_COUNT = 122
  RINSHAN_WALL = (122..125).to_a
  DORA_INDICATOR_ORDER_RANGE = (126..130)
  URADORA_INDICATOR_ORDER_RANGE = (131..135)

  belongs_to :round

  has_many :steps, dependent: :destroy
  has_many :tile_orders, -> { order(:order) }, dependent: :destroy
  has_many :game_records, dependent: :destroy

  validates :number, presence: true
  validates :riichi_stick_count, presence: true

  after_create :create_tile_orders_and_step

  def top_tile
    tile_orders.find_by(order: draw_count).tile
  end

  def rinshan_tile
    rinshan_order = RINSHAN_WALL[kan_count - 1]
    tile_orders.find_by(order: rinshan_order).tile
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
    tile_orders[DORA_INDICATOR_ORDER_RANGE].map(&:tile)[..kan_count]
  end

  def uradora_indicator_tiles
    tile_orders[URADORA_INDICATOR_ORDER_RANGE].map(&:tile)[..kan_count]
  end

  private

    def create_tile_orders_and_step
      setup_tile_orders
      steps.create!
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
end
