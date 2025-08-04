# frozen_string_literal: true

require 'test_helper'

class PlayerStateTest < ActiveSupport::TestCase
  test 'destroying player_state should also destroy hands' do
    player_state = player_states(:ryo)
    assert_difference('Hand.count', -player_state.hands.count) do
      player_state.destroy
    end
  end

  test 'destroying player_state should also destroy rivers' do
    player_state = player_states(:ryo)
    assert_difference('River.count', -player_state.rivers.count) do
      player_state.destroy
    end
  end

  test 'destroying player_state should also destroy melds' do
    player_state = player_states(:ryo)
    assert_difference('Meld.count', -player_state.melds.count) do
      player_state.destroy
    end
  end

  test 'is valid with step and player' do
    step = steps(:step_1)
    player = players(:ryo)
    player_state = PlayerState.new(step:, player:)
    assert player_state.valid?
  end

  test 'is invalid without step' do
    player = players(:ryo)
    player_state = PlayerState.new(player:)
    assert player_state.invalid?
  end

  test 'is invalid without player' do
    step = steps(:step_1)
    player_state = PlayerState.new(step:)
    assert player_state.invalid?
  end

  test 'riichi default to false' do
    step = steps(:step_1)
    player = players(:ryo)
    player_state = PlayerState.new(step:, player:)
    assert_not player_state.riichi?
  end

  test 'riichi must be true or false' do
    step = steps(:step_1)
    player = players(:ryo)
    player_state = PlayerState.new(step:, player:, riichi: nil)
    assert player_state.invalid?

    player_state = PlayerState.new(step:, player:, riichi: true)
    assert player_state.valid?
  end
end
