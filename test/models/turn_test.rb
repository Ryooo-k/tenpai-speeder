# frozen_string_literal: true

require 'test_helper'

class TurnTest < ActiveSupport::TestCase
  test 'destroying turn should also destroy steps' do
    turn = turns(:turn_1)
    assert_difference('Step.count', -turn.steps.count) do
      turn.destroy
    end
  end

  test 'is valid with honba' do
    honba = honbas(:ton_1_kyoku_0_honba)
    turn = Turn.new(honba:)
    assert turn.valid?
  end

  test 'is invalid without honba' do
    turn = Turn.new
    assert turn.invalid?
  end

  test 'number default to 0' do
    honba = honbas(:ton_1_kyoku_0_honba)
    turn = Turn.new(honba:)
    assert_equal 0, turn.number
  end
end
