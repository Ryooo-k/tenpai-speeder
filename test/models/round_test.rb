# frozen_string_literal: true

require 'test_helper'

class RoundTest < ActiveSupport::TestCase
  test 'destroying round should also destroy honbas' do
    round = rounds(:ton_1_kyoku)
    assert_difference('Honba.count', -round.honbas.count) do
      round.destroy
    end
  end

  test 'is valid with number and host_position and game' do
    game = games(:tonpuu)
    round = Round.new(game:, number: 0, host_position: 0)
    assert round.valid?
  end

  test 'is invalid without number' do
    game = games(:tonpuu)
    round = Round.new(game:, host_position: 0)
    assert round.invalid?
  end

  test 'is invalid without host_position' do
    game = games(:tonpuu)
    round = Round.new(game:, number: 0)
    assert round.invalid?
  end

  test 'is invalid without game' do
    round = Round.new(number: 0, host_position: 0)
    assert round.invalid?
  end
end
