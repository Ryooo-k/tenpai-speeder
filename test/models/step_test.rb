# frozen_string_literal: true

require 'test_helper'

class StepTest < ActiveSupport::TestCase
  test 'destroying step should also destroy player_states' do
    step = steps(:step_1)
    assert_difference('PlayerState.count', -step.player_states.count) do
      step.destroy
    end
  end

  test 'number default to 0' do
    honba = honbas(:honba_0)
    step = Step.new(honba:)
    assert_equal 0, step.number
  end

  test 'snapshots honba counters on create' do
    honba = honbas(:honba_0)
    honba.update!(draw_count: 10, kan_count: 2, riichi_stick_count: 1)

    step = honba.steps.create!(number: honba.steps.maximum(:number).to_i + 1)

    assert_equal 10, step.draw_count
    assert_equal 2, step.kan_count
    assert_equal 1, step.riichi_stick_count
  end
end
