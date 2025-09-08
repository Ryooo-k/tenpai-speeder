# frozen_string_literal: true

require 'test_helper'

class StepTest < ActiveSupport::TestCase
  test 'destroying step should also destroy player_states' do
    step = steps(:step_1)
    assert_difference('PlayerState.count', -step.player_states.count) do
      step.destroy
    end
  end

  test 'is valid with honba' do
    honba = honbas(:honba_0)
    step = Step.new(honba:)
    assert step.valid?
  end

  test 'is invalid with honba' do
    step = Step.new
    assert step.invalid?
  end

  test 'number default to 0' do
    honba = honbas(:honba_0)
    step = Step.new(honba:)
    assert_equal 0, step.number
  end
end
