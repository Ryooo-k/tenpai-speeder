# frozen_string_literal: true

require 'test_helper'

class TurnTest < ActiveSupport::TestCase
  test 'destroying turn should also destroy steps' do
    turn = turns(:turn_1)
    assert_difference('Step.count', -turn.steps.count) do
      turn.destroy
    end
  end

  test 'is valid with number and honba' do
    honba = honbas(:ton_1_kyoku_0_honba)
    turn = Turn.new(honba:, number: 0)
    assert turn.valid?
  end

  test 'is invalid without number' do
    honba = honbas(:ton_1_kyoku_0_honba)
    turn = Turn.new(honba:)
    assert turn.invalid?
  end

  test 'is invalid without honba' do
    turn = Turn.new(number: 0)
    assert turn.invalid?
  end
end
