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

  test '.for_honba' do
    game = games(:tonnan)
    honba_1 = game.latest_round.honbas.create!(number: 1)
    honba_2 = game.latest_round.honbas.create!(number: 2)

    step_1 = honba_1.steps.create!
    step_2 = honba_2.steps.create!

    state_1 = step_1.player_states.create!(player: @player)
    state_2 = step_2.player_states.create!(player: @player)

    assert_includes PlayerState.for_honba(honba_1), state_1
    assert_not_includes PlayerState.for_honba(honba_1), state_2

    assert_includes PlayerState.for_honba(honba_2), state_2
    assert_not_includes PlayerState.for_honba(honba_2), state_1
  end

  test '.up_to_steps' do
    @player.player_states.delete_all
    step_1 = steps(:step_1)
    step_2 = steps(:step_2)
    step_3 = steps(:step_3)
    state_1 = @player.player_states.create!(step: step_1)
    state_2 = @player.player_states.create!(step: step_2)
    state_3 = @player.player_states.create!(step: step_3)

    assert_equal [ state_1 ], @player.player_states.up_to_step(step_1.number)
    assert_equal [ state_1, state_2 ], @player.player_states.up_to_step(step_2.number)
    assert_equal [ state_1, state_2, state_3 ], @player.player_states.up_to_step(step_3.number)
  end

  test '.in_step_range' do
    @player.player_states.delete_all
    step_1 = steps(:step_1)
    step_2 = steps(:step_2)
    step_3 = steps(:step_3)
    state_1 = @player.player_states.create!(step: step_1)
    state_2 = @player.player_states.create!(step: step_2)
    state_3 = @player.player_states.create!(step: step_3)

    assert_equal [ state_1 ],  @player.player_states.in_step_range(step_1.number..step_1.number)
    assert_equal [ state_1, state_2 ], @player.player_states.in_step_range(step_1.number..step_2.number)
    assert_equal [ state_2, state_3 ], @player.player_states.in_step_range(step_2.number..step_3.number)
  end
end
