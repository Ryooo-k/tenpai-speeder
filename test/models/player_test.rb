# frozen_string_literal: true

require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  def setup
    @user_player = players(:ryo)
    @ai_player = players(:menzen_tenpai_speeder)
    @user = users(:ryo)
    @game = games(:tonpuu)
    @manzu_1 = tiles(:first_manzu_1)
    @manzu_2 = tiles(:first_manzu_2)
    @manzu_3 = tiles(:first_manzu_3)
  end

  test 'destroying player should also destroy results' do
    assert_difference('Result.count', -@user_player.results.count) do
      @user_player.destroy
    end
  end

  test 'destroying player should also destroy game_records' do
    assert_difference('GameRecord.count', -@user_player.game_records.count) do
      @user_player.destroy
    end
  end

  test 'destroying player should also destroy actions' do
    assert_difference('Action.count', -@user_player.actions.count) do
      @user_player.destroy
    end
  end

  test 'destroying player should also destroy player_states' do
    assert_difference('PlayerState.count', -@user_player.player_states.count) do
      @user_player.destroy
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

  test '#hands return sorted hands of current_state' do
    @user_player.draw(@manzu_3, steps(:step_1))
    assert_equal [ @manzu_3 ], @user_player.hands.all.map(&:tile)

    @user_player.draw(@manzu_1, steps(:step_2))
    assert_equal [ @manzu_3, @manzu_1 ], @user_player.hands.all.map(&:tile)

    @user_player.draw(@manzu_2, steps(:step_3))
    assert_equal [ @manzu_1, @manzu_3, @manzu_2 ], @user_player.hands.all.map(&:tile)
  end

  test '#receive' do
    before_state_count = @user_player.player_states.count
    @user_player.receive(@manzu_2)
    current_hand_tiles = @user_player.player_states.ordered.last.hands.all.map(&:tile)
    assert_equal [ @manzu_2 ], current_hand_tiles
    assert_equal before_state_count, @user_player.player_states.count

    @user_player.receive(@manzu_1)
    current_hand_tiles = @user_player.player_states.ordered.last.hands.all.map(&:tile)
    assert_equal [ @manzu_2, @manzu_1 ], current_hand_tiles
    assert_equal before_state_count, @user_player.player_states.count
  end

  test '#draw' do
    before_state_count = @user_player.player_states.count
    @user_player.draw(@manzu_3, steps(:step_1))
    step_1_hands = @user_player.player_states.ordered.last.hands.all
    assert_equal [ @manzu_3 ], step_1_hands.map(&:tile)
    assert step_1_hands.last.drawn?
    assert_equal before_state_count + 1, @user_player.player_states.count

    @user_player.draw(@manzu_1, steps(:step_2))
    step_2_hands = @user_player.player_states.ordered.last.hands.all
    assert_equal [ @manzu_3, @manzu_1 ], step_2_hands.map(&:tile)
    assert step_2_hands.last.drawn?
    assert_not step_2_hands.first.drawn?
    assert_equal before_state_count + 2, @user_player.player_states.count

    @user_player.draw(@manzu_2, steps(:step_3))
    step_3_hands = @user_player.player_states.ordered.last.hands.all
    assert_equal [ @manzu_3, @manzu_1, @manzu_2 ], step_3_hands.map(&:tile)
    assert step_3_hands.last.drawn?
    step_3_hands[...-1].each { |hand| assert_not hand.drawn? }
    assert_equal before_state_count + 3, @user_player.player_states.count
  end

  test '#discard' do
    @user_player.draw(@manzu_1, steps(:step_1))
    @user_player.draw(@manzu_2, steps(:step_2))
    assert_equal [ @manzu_1, @manzu_2 ], @user_player.hands.all.map(&:tile)
    assert_equal [], @user_player.rivers

    before_state_count = @user_player.player_states.count
    manzu_2_hand_id = @user_player.hands.last.id
    @user_player.discard(manzu_2_hand_id, steps(:step_3))
    assert_equal [ @manzu_1 ], @user_player.hands.all.map(&:tile)
    assert_equal [ @manzu_2 ], @user_player.rivers.map(&:tile)
    assert @user_player.rivers.first.tsumogiri?
    assert_equal before_state_count + 1, @user_player.player_states.count

    manzu_1_hand_id = @user_player.hands.first.id
    @user_player.discard(manzu_1_hand_id, steps(:step_4))
    assert_equal [], @user_player.hands.all.map(&:tile)
    assert_equal [ @manzu_2, @manzu_1 ], @user_player.rivers.map(&:tile)
    assert @user_player.rivers.first.tsumogiri?
    assert_not @user_player.rivers.last.tsumogiri?
    assert_equal before_state_count + 2, @user_player.player_states.count
  end

  test '#ai?' do
    assert_not @user_player.ai?
    assert @ai_player.ai?
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
