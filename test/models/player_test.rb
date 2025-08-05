# frozen_string_literal: true

require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  def setup
    @ryo = players(:ryo)
    @user = users(:ryo)
    @game = games(:tonpuu)
  end

  test 'destroying player should also destroy results' do
    assert_difference('Result.count', -@ryo.results.count) do
      @ryo.destroy
    end
  end

  test 'destroying player should also destroy game_records' do
    assert_difference('GameRecord.count', -@ryo.game_records.count) do
      @ryo.destroy
    end
  end

  test 'destroying player should also destroy actions' do
    assert_difference('Action.count', -@ryo.actions.count) do
      @ryo.destroy
    end
  end

  test 'destroying player should also destroy player_states' do
    assert_difference('PlayerState.count', -@ryo.player_states.count) do
      @ryo.destroy
    end
  end

  test 'is valid with user and seat_order and game' do
    player = Player.new(user: @user, game: @game, seat_order: 0)
    assert player.valid?
  end

  test 'is valid with ai and seat_order and game' do
    ai = ais(:tenpai_speeder)
    player = Player.new(ai:, game: @game, seat_order: 0)
    assert player.valid?
  end

  test 'is invalid without user or ai' do
    player = Player.new(game: @game, seat_order: 0)
    assert player.invalid?
  end

  test 'is invalid without game' do
    player = Player.new(user: @user, seat_order: 0)
    assert player.invalid?
  end

  test 'is invalid without seat_order' do
    player = Player.new(user: @user, game: @game)
    assert player.invalid?
  end

  test 'validate player type' do
    player = Player.new(game: @game, seat_order: 0)
    assert player.invalid?
    assert_includes player.errors[:base], 'UserまたはAIのいずれかを指定してください'

    ai = ais(:tenpai_speeder)
    player = Player.new(user: @user, ai:, game: @game, seat_order: 0)
    assert player.invalid?
    assert_includes player.errors[:base], 'UserとAIの両方を同時に指定することはできません'
  end

  test '#create_game_record' do
    assert_equal 1, @ryo.game_records.count
    @ryo.create_game_record(honbas(:ton_1_kyoku_0_honba))
    assert_equal 2, @ryo.game_records.count
  end

  test '#create_state' do
    assert_equal 1, @ryo.player_states.count
    @ryo.create_state(steps(:step_1))
    assert_equal 2, @ryo.player_states.count
  end

  test '#state return latest player_state' do
    old_state = @ryo.player_states.create!(step: steps(:step_1), created_at: 1.hour.ago)
    new_state = @ryo.player_states.create!(step: steps(:step_2), created_at: Time.current)
    assert_not_equal old_state, @ryo.state
    assert_equal new_state, @ryo.state
  end

  test '#hands return latest sorted tiles' do
    old_hands = @ryo.hands
    manzu_1 = tiles(:first_manzu_1)
    manzu_9 = tiles(:first_manzu_9)
    new_state = @ryo.player_states.create!(step: steps(:step_1))
    new_state.hands.create!(tile: manzu_9)
    new_state.hands.create!(tile: manzu_1)
    assert_not_equal old_hands, @ryo.hands
    assert_equal [ manzu_1, manzu_9 ], @ryo.hands
  end

  test '#receive' do
    assert_equal 0, @ryo.hands.count
    assert_equal 0, @ryo.game.current_honba.draw_count

    @ryo.receive(tiles(:first_manzu_1))
    assert_equal 1, @ryo.hands.count
    assert_equal 1, @ryo.game.current_honba.draw_count
  end

  test '#shimocha?' do
    main_player = Player.new(user: @user, game: @game, seat_order: 0)
    shimocha_player = Player.new(user: @user, game: @game, seat_order: 1)
    assert shimocha_player.shimocha?(main_player)
  end

  test '#toimen?' do
    main_player = Player.new(user: @user, game: @game, seat_order: 0)
    toimen_player = Player.new(user: @user, game: @game, seat_order: 2)
    assert toimen_player.toimen?(main_player)
  end

  test '#kamicha?' do
    main_player = Player.new(user: @user, game: @game, seat_order: 0)
    kamicha_player = Player.new(user: @user, game: @game, seat_order: 3)
    assert kamicha_player.kamicha?(main_player)
  end
end
