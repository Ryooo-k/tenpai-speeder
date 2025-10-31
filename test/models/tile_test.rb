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
    game = games(:tonnan)
    tile = Tile.new(base_tile:, game:, kind: 0, aka: false)
    assert tile.valid?
  end

  test 'is invalid without kind' do
    base_tile = base_tiles(:manzu_1)
    game = games(:tonnan)
    tile = Tile.new(base_tile:, game:, aka: false)
    assert tile.invalid?
  end

  test 'is invalid without game' do
    base_tile = base_tiles(:manzu_1)
    tile = Tile.new(base_tile:, kind: 0, aka: false)
    assert tile.invalid?
  end

  test 'is invalid without base_tile' do
    game = games(:tonnan)
    tile = Tile.new(game:, kind: 0, aka: false)
    assert tile.invalid?
  end

  test 'aka default to false' do
    base_tile = base_tiles(:manzu_1)
    game = games(:tonnan)
    tile = Tile.new(base_tile:, game:, kind: 0)
    assert_not tile.aka?
  end

  test 'aka_dora must be true or false' do
    base_tile = base_tiles(:manzu_1)
    game = games(:tonnan)
    tile = Tile.new(base_tile:, game:, kind: 0, aka: nil)
    assert tile.invalid?

    tile = Tile.new(base_tile:, game:, kind: 0, aka: true)
    assert tile.valid?
  end

  test '#suit' do
    manzu_1 = tiles(:first_manzu_1)
    assert_equal 'manzu', manzu_1.suit

    pinzu_9 = tiles(:second_pinzu_9)
    assert_equal 'pinzu', pinzu_9.suit

    souzu_5 = tiles(:third_souzu_5)
    assert_equal 'souzu', souzu_5.suit

    ton = tiles(:fourth_ton)
    assert_equal 'zihai', ton.suit
  end

  test '#name' do
    manzu_1 = tiles(:first_manzu_1)
    assert_equal '1萬', manzu_1.name

    pinzu_9 = tiles(:second_pinzu_9)
    assert_equal '9筒', pinzu_9.name

    souzu_5 = tiles(:third_souzu_5)
    assert_equal '5索', souzu_5.name

    ton = tiles(:fourth_ton)
    assert_equal '東', ton.name
  end

  test '#number' do
    manzu_1 = tiles(:first_manzu_1)
    assert_equal 1, manzu_1.number

    pinzu_9 = tiles(:second_pinzu_9)
    assert_equal 9, pinzu_9.number

    souzu_5 = tiles(:third_souzu_5)
    assert_equal 5, souzu_5.number

    ton = tiles(:fourth_ton)
    assert_equal 1, ton.number
  end

  test '#code' do
    manzu_1 = tiles(:first_manzu_1)
    assert_equal 0, manzu_1.code

    pinzu_9 = tiles(:second_pinzu_9)
    assert_equal 17, pinzu_9.code

    souzu_5 = tiles(:third_souzu_5)
    assert_equal 22, souzu_5.code

    ton = tiles(:fourth_ton)
    assert_equal 27, ton.code
  end
end
