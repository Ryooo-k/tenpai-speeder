# frozen_string_literal: true

require 'test_helper'

class HonbaTest < ActiveSupport::TestCase
  test 'destroying honba should also destroy turns' do
    honba = honbas(:ton_1_kyoku_0_honba)
    assert_difference('Turn.count', -honba.turns.count) do
      honba.destroy
    end
  end

  test 'destroying honba should also destroy tile_orders' do
    honba = honbas(:ton_1_kyoku_0_honba)
    assert_difference('TileOrder.count', -honba.tile_orders.count) do
      honba.destroy
    end
  end

  test 'destroying honba should also destroy scores' do
    honba = honbas(:ton_1_kyoku_0_honba)
    assert_difference('Score.count', -honba.scores.count) do
      honba.destroy
    end
  end

  test 'is valid with round' do
    round = rounds(:ton_1_kyoku)
    honba = Honba.new(round:)
    assert honba.valid?
  end

  test 'is invalid without round' do
    honba = Honba.new
    assert honba.invalid?
  end

  test 'number default to 0' do
    round = rounds(:ton_1_kyoku)
    honba = Honba.new(round:)
    assert_equal 0, honba.number
  end

  test 'riichi_stick_count default to 0' do
    round = rounds(:ton_1_kyoku)
    honba = Honba.new(round:)
    assert_equal 0, honba.riichi_stick_count
  end
end
