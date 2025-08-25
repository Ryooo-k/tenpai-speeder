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
    order = @honba.draw_count - @honba.kan_count
    expected = @honba.tile_orders.find_by(order:).tile
    assert_equal expected, @honba.top_tile
  end
end
