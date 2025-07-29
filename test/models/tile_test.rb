# frozen_string_literal: true

require 'test_helper'

class TileTest < ActiveSupport::TestCase
  test 'destroying tile should also destroy tile_orders' do
    tile = tiles(:first_manzu_1)
    assert_difference('TileOrder.count', -tile.tile_orders.count) do
      tile.destroy
    end
  end

  test 'destroying tile should also destroy hands' do
    tile = tiles(:first_manzu_1)
    assert_difference('Hand.count', -tile.hands.count) do
      tile.destroy
    end
  end

  test 'destroying tile should also destroy rivers' do
    tile = tiles(:first_manzu_1)
    assert_difference('River.count', -tile.rivers.count) do
      tile.destroy
    end
  end

  test 'destroying tile should also destroy melds' do
    tile = tiles(:first_manzu_1)
    assert_difference('Meld.count', -tile.melds.count) do
      tile.destroy
    end
  end

  test 'is valid with kind and aka and game and base_tile' do
    base_tile = base_tiles(:manzu_1)
    game = games(:tonpuu)
    tile = Tile.new(base_tile:, game:, kind: 0, aka: false)
    assert tile.valid?
  end

  test 'is invalid without kind' do
    base_tile = base_tiles(:manzu_1)
    game = games(:tonpuu)
    tile = Tile.new(base_tile:, game:, aka: false)
    assert tile.invalid?
  end

  test 'is invalid without game' do
    base_tile = base_tiles(:manzu_1)
    tile = Tile.new(base_tile:, kind: 0, aka: false)
    assert tile.invalid?
  end

  test 'is invalid without base_tile' do
    game = games(:tonpuu)
    tile = Tile.new(game:, kind: 0, aka: false)
    assert tile.invalid?
  end

  test 'aka default to false' do
    base_tile = base_tiles(:manzu_1)
    game = games(:tonpuu)
    tile = Tile.new(base_tile:, game:, kind: 0)
    assert_not tile.aka?
  end

  test 'aka_dora must be true or false' do
    base_tile = base_tiles(:manzu_1)
    game = games(:tonpuu)
    tile = Tile.new(base_tile:, game:, kind: 0, aka: nil)
    assert tile.invalid?

    tile = Tile.new(base_tile:, game:, kind: 0, aka: true)
    assert tile.valid?
  end
end
