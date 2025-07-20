# frozen_string_literal: true

require 'test_helper'

class StepTest < ActiveSupport::TestCase
  test 'destroying step should also destroy actions' do
    step = steps(:step_1)
    assert_difference('Action.count', -step.actions.count) do
      step.destroy
    end
  end

  test 'destroying step should also destroy player_states' do
    step = steps(:step_1)
    assert_difference('PlayerState.count', -step.player_states.count) do
      step.destroy
    end
  end

  test 'is valid with number and turn' do
    turn = turns(:turn_1)
    step = Step.new(turn:, number: 0)
    assert step.valid?
  end

  test 'is invalid with number' do
    turn = turns(:turn_1)
    step = Step.new(turn:)
    assert step.invalid?
  end

  test 'is invalid with turn' do
    step = Step.new(number: 0)
    assert step.invalid?
  end
end
