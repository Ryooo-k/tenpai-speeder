# frozen_string_literal: true

require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  test 'destroying player should also destroy results' do
    player = players(:ryo)
    assert_difference('Result.count', -player.results.count) do
      player.destroy
    end
  end

  test 'destroying player should also destroy scores' do
    player = players(:ryo)
    assert_difference('Score.count', -player.scores.count) do
      player.destroy
    end
  end

  test 'destroying player should also destroy actions' do
    player = players(:ryo)
    assert_difference('Action.count', -player.actions.count) do
      player.destroy
    end
  end

  test 'destroying player should also destroy player_states' do
    player = players(:ryo)
    assert_difference('PlayerState.count', -player.player_states.count) do
      player.destroy
    end
  end

  test 'is valid with user and seat_order and game' do
    user = users(:ryo)
    game = games(:tonpuu)
    player = Player.new(user:, game:, seat_order: 0)
    assert player.valid?
  end

  test 'is valid with ai and seat_order and game' do
    ai = ais(:tenpai_speeder)
    game = games(:tonpuu)
    player = Player.new(ai:, game:, seat_order: 0)
    assert player.valid?
  end

  test 'is invalid without user or ai' do
    game = games(:tonpuu)
    player = Player.new(game:, seat_order: 0)
    assert player.invalid?
  end

  test 'is invalid without game' do
    user = users(:ryo)
    player = Player.new(user:, seat_order: 0)
    assert player.invalid?
  end

  test 'is invalid without seat_order' do
    user = users(:ryo)
    game = games(:tonpuu)
    player = Player.new(user:, game:)
    assert player.invalid?
  end

  test 'validate player type' do
    game = games(:tonpuu)
    player = Player.new(game:, seat_order: 0)
    assert player.invalid?
    assert_includes player.errors[:base], 'UserまたはAIのいずれかを指定してください'

    user = users(:ryo)
    ai = ais(:tenpai_speeder)
    player = Player.new(user:, ai:, game:, seat_order: 0)
    assert player.invalid?
    assert_includes player.errors[:base], 'UserとAIの両方を同時に指定することはできません'
  end
end
