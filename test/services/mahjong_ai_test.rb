# frozen_string_literal: true

require 'test_helper'

class MahjongAiTest < ActiveSupport::TestCase
  def setup
    @game = games(:tonpuu)
    @game.deal_initial_hands
  end

  test '#infer returns UnsupportedAiVersionError when player is user' do
    assert_raise(MahjongAi::UnsupportedAi) do
      MahjongAi.infer(@game, @game.user_player)
    end
  end

  test '#infer returns UnsupportedAiVersionError when unsupported ai version' do
    ai = @game.ais.sample
    ai.ai.update!(version: 'unknown_v999"')

    assert_raise(MahjongAi::UnsupportedAi) do
      MahjongAi.infer(@game, ai)
    end
  end

  test '#infer returns valid action index for an AI player' do
    ai = @game.ais.sample
    action_index = MahjongAi.infer(@game, ai)
    action_size = AI_CONFIGS.fetch(ai.ai_version)[:output_size]
    valid_range = (0..action_size)
    assert_includes valid_range, action_index
  end
end
