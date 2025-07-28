# frozen_string_literal: true

require 'test_helper'

class RoundTest < ActiveSupport::TestCase
  test 'destroying round should also destroy honbas' do
    round = rounds(:ton_1_kyoku)
    assert_difference('Honba.count', -round.honbas.count) do
      round.destroy
    end
  end

  test 'is valid with game' do
    game = games(:tonpuu)
    round = Round.new(game:)
    assert round.valid?
  end

  test 'is invalid without game' do
    round = Round.new
    assert round.invalid?
  end

  test 'number default to 0' do
    game = games(:tonpuu)
    round = Round.new(game:)
    assert_equal 0, round.number
  end

  test 'host_position default to 0' do
    game = games(:tonpuu)
    round = Round.new(game:)
    assert_equal 0, round.host_position
  end
end
