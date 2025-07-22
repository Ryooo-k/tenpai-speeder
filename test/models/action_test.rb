# frozen_string_literal: true

require 'test_helper'

class ActionTest < ActiveSupport::TestCase
  test 'destroying action should also destroy melds' do
    action = actions(:pon)
    assert_difference('Meld.count', -action.melds.count) do
      action.destroy
    end
  end

  test 'is valid with step and player and action_type' do
    step = steps(:step_1)
    player = players(:ryo)
    action_type = 0 # drawアクション
    action = Action.new(step:, player:, action_type:)
    assert action.valid?
  end

  test 'is invalid without step' do
    player = players(:ryo)
    action_type = 0
    action = Action.new(player:, action_type:)
    assert action.invalid?
  end

  test 'is invalid without player' do
    step = steps(:step_1)
    action_type = 0
    action = Action.new(step:, action_type:)
    assert action.invalid?
  end

  test 'validate from_player' do
    step = steps(:step_1)
    player = players(:ryo)
    action_type = 2 # ponアクション
    action = Action.new(step:, player:, action_type:)
    assert action.invalid?
    assert_includes action.errors[:from_player], 'ponの時はfrom_playerが必要です'

    action_type = 3 # chiアクション
    action = Action.new(step:, player:, action_type:)
    assert action.invalid?
    assert_includes action.errors[:from_player], 'chiの時はfrom_playerが必要です'

    action_type = 4 # daiminkanアクション
    action = Action.new(step:, player:, action_type:)
    assert action.invalid?
    assert_includes action.errors[:from_player], 'daiminkanの時はfrom_playerが必要です'

    action_type = 9 # ronアクション
    action = Action.new(step:, player:, action_type:)
    assert action.invalid?
    assert_includes action.errors[:from_player], 'ronの時はfrom_playerが必要です'
  end
end
