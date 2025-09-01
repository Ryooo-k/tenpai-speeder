# frozen_string_literal: true

require 'test_helper'

class HonbaTest < ActiveSupport::TestCase
  def setup
    @honba = honbas(:ton_1_kyoku_0_honba)
  end

  test 'destroying honba should also destroy turns' do
    assert_difference('Turn.count', -@honba.turns.count) do
      @honba.destroy
    end
  end

  test 'destroying honba should also destroy tile_orders' do
    assert_difference('TileOrder.count', -@honba.tile_orders.count) do
      @honba.destroy
    end
  end

  test 'destroying honba should also destroy game_records' do
    assert_difference('GameRecord.count', -@honba.game_records.count) do
      @honba.destroy
    end
  end

  test 'is valid with round' do
    honba = Honba.new(round: rounds(:ton_1_kyoku))
    assert honba.valid?
  end

  test 'is invalid without round' do
    honba = Honba.new
    assert honba.invalid?
  end

  test 'number default to 0' do
    honba = Honba.new(round: rounds(:ton_1_kyoku))
    assert_equal 0, honba.number
  end

  test 'draw_count default to 0' do
    honba = Honba.new(round: rounds(:ton_1_kyoku))
    assert_equal 0, honba.draw_count
  end

  test 'kan_count default to 0' do
    honba = Honba.new(round: rounds(:ton_1_kyoku))
    assert_equal 0, honba.kan_count
  end

  test 'riichi_stick_count default to 0' do
    honba = Honba.new(round: rounds(:ton_1_kyoku))
    assert_equal 0, honba.riichi_stick_count
  end

  test 'create first turn and 136 tile_orders and when after_create calls create_tile_orders_and_turn' do
    honba = Honba.new(round: rounds(:ton_1_kyoku))
    assert_equal 0, honba.turns.count
    assert_equal 0, honba.tile_orders.count
    honba.save

    assert_equal 1, honba.turns.count
    assert_equal 136, honba.tile_orders.count
  end

  test '#current_turn' do
    max_number = @honba.turns.maximum(:number)
    max_number_turn = @honba.turns.find_by(number: max_number)
    assert_equal max_number_turn, @honba.current_turn
  end

  test '#top_tile' do
    @honba.draw_count = 10
    @honba.kan_count = 0
    top_tile_order = @honba.draw_count - @honba.kan_count
    expected = @honba.tile_orders.find_by(order: top_tile_order).tile
    assert_equal expected, @honba.top_tile

    @honba.draw_count = 20
    @honba.kan_count = 2
    top_tile_order = @honba.draw_count - @honba.kan_count
    expected = @honba.tile_orders.find_by(order: top_tile_order).tile
    assert_equal expected, @honba.top_tile
  end

  test '#name' do
    @honba.number = 0
    assert_equal '〇本場', @honba.name
    @honba.number = 1
    assert_equal '一本場', @honba.name
    @honba.number = 2
    assert_equal '二本場', @honba.name
    @honba.number = 10
    assert_equal '一〇本場', @honba.name
  end

  test '#remaining_tile_count' do
    @honba.draw_count = 0
    @honba.kan_count = 0
    initial_remaining_tile_count = 122
    assert_equal initial_remaining_tile_count, @honba.remaining_tile_count

    draw_count = 10
    @honba.draw_count = draw_count
    expected = initial_remaining_tile_count - draw_count
    assert_equal expected, @honba.remaining_tile_count

    kan_count = 3
    @honba.kan_count = kan_count
    expected = initial_remaining_tile_count - draw_count - kan_count
    assert_equal expected, @honba.remaining_tile_count
  end

  test '#dora_indicator_tiles' do
    @honba.kan_count = 0
    first_dora_order = 122
    first_dora_tile = @honba.tile_orders.find_by(order: first_dora_order).tile
    assert_equal [ first_dora_tile ], @honba.dora_indicator_tiles

    @honba.kan_count = 1
    second_dora_order = 123
    second_dora_tile = @honba.tile_orders.find_by(order: second_dora_order).tile
    assert_equal [ first_dora_tile, second_dora_tile ], @honba.dora_indicator_tiles

    @honba.kan_count = 2
    third_dora_order = 124
    third_dora_tile = @honba.tile_orders.find_by(order: third_dora_order).tile
    assert_equal [ first_dora_tile, second_dora_tile, third_dora_tile ], @honba.dora_indicator_tiles

    @honba.kan_count = 3
    fourth_dora_order = 125
    fourth_dora_tile = @honba.tile_orders.find_by(order: fourth_dora_order).tile
    assert_equal [ first_dora_tile, second_dora_tile, third_dora_tile, fourth_dora_tile ], @honba.dora_indicator_tiles

    @honba.kan_count = 4
    fifth_dora_order = 126
    fifth_dora_tile = @honba.tile_orders.find_by(order: fifth_dora_order).tile
    assert_equal [ first_dora_tile, second_dora_tile, third_dora_tile, fourth_dora_tile, fifth_dora_tile ], @honba.dora_indicator_tiles
  end
end
