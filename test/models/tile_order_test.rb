# frozen_string_literal: true

require 'test_helper'

class TileOrderTest < ActiveSupport::TestCase
  test 'is valid with order and honba and tile' do
    tile = tiles(:first_manzu_1)
    honba = honbas(:honba_0)
    tile_order = TileOrder.new(tile:, honba:, order: 0)
    assert tile_order.valid?
  end

  test 'is invalid without order' do
    tile = tiles(:first_manzu_1)
    honba = honbas(:honba_0)
    tile_order = TileOrder.new(tile:, honba:)
    assert tile_order.invalid?
  end

  test 'is invalid without honba' do
    tile = tiles(:first_manzu_1)
    tile_order = TileOrder.new(tile:, order: 0)
    assert tile_order.invalid?
  end

  test 'is invalid without tile' do
    honba = honbas(:honba_0)
    tile_order = TileOrder.new(honba:, order: 0)
    assert tile_order.invalid?
  end
end
