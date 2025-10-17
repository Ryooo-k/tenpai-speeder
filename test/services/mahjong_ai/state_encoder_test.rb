# frozen_string_literal: true

require 'test_helper'

class StateEncoderTest < ActiveSupport::TestCase
  def setup
    @game = games(:tonpuu)
    @game.deal_initial_hands
  end

  test 'returns UnsupportedAiVersionError when player is user' do
    assert_raise(MahjongAi::StateEncoder::UnsupportedAi) do
      MahjongAi::StateEncoder.call(@game, @game.user_player)
    end
  end

  test 'returns UnsupportedAiVersionError when unsupported ai version' do
    ai = @game.ais.sample
    ai.ai.update!(version: 'unknown_v999"')

    assert_raise(MahjongAi::StateEncoder::UnsupportedAi) do
      MahjongAi::StateEncoder.call(@game, ai)
    end
  end

  test '#build_v0_1_states returns 206 Torch::Tensor states' do
    ai = @game.ais.sample
    ai.ai.update!(version: '0.1')

    states = MahjongAi::StateEncoder.call(@game, @game.ais.sample)
    assert_equal 206, states.count
    assert states.all? { |state| state.is_a?(Torch::Tensor) }
  end
end
