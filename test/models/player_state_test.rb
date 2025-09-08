# frozen_string_literal: true

require 'test_helper'

class PlayerStateTest < ActiveSupport::TestCase
  def setup
    @player_state = player_states(:ryo)
    @step_1 = steps(:step_1)
    @player = players(:ryo)
  end

  test 'destroying player_state should also destroy hands' do
    assert_difference('Hand.count', -@player_state.hands.count) do
      @player_state.destroy
    end
  end

  test 'destroying player_state should also destroy rivers' do
    assert_difference('River.count', -@player_state.rivers.count) do
      @player_state.destroy
    end
  end

  test 'destroying player_state should also destroy melds' do
    assert_difference('Meld.count', -@player_state.melds.count) do
      @player_state.destroy
    end
  end

  test 'is valid with step and player' do
    player_state = PlayerState.new(step: @step_1, player: @player)
    assert player_state.valid?
  end

  test 'is invalid without step' do
    player_state = PlayerState.new(player: @player)
    assert player_state.invalid?
  end

  test 'is invalid without player' do
    player_state = PlayerState.new(step: @step_1)
    assert player_state.invalid?
  end

  test 'riichi default to false' do
    player_state = PlayerState.new(step: @step_1, player: @player)
    assert_not player_state.riichi?
  end

  test 'riichi must be true or false' do
    player_state = PlayerState.new(step: @step_1, player: @player, riichi: nil)
    assert player_state.invalid?

    player_state = PlayerState.new(step: @step_1, player: @player, riichi: true)
    assert player_state.valid?
  end

  test '.ordered' do
    @player.player_states.delete_all
    fourth_state = @player.player_states.create!(step: steps(:step_4), player: @player)
    third_state = @player.player_states.create!(step: steps(:step_3), player: @player)
    second_state = @player.player_states.create!(step: steps(:step_2), player: @player)
    first_state = @player.player_states.create!(step: steps(:step_1), player: @player)
    assert_equal [ first_state, second_state, third_state, fourth_state ], @player.player_states.ordered
  end
end
