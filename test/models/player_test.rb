# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class PlayerTest < ActiveSupport::TestCase
  def setup
    @user_player = players(:ryo)
    @ai_player = players(:menzen_tenpai_speeder)
    @user = users(:ryo)
    @ai = ais(:tenpai_speeder)
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
    current_state = @user_player.player_states.ordered.last
    current_state.hands.delete_all

    drawn_hand = current_state.hands.create!(tile: @manzu_1, drawn: true)
    hand_3 = current_state.hands.create!(tile: @manzu_3)
    hand_2 = current_state.hands.create!(tile: @manzu_2)
    assert_equal [ hand_2, hand_3, drawn_hand ], @user_player.hands
  end

  test '#rivers return ordered rivers of current_state' do
    current_state = @user_player.player_states.ordered.last
    current_state.rivers.delete_all

    first_river = current_state.rivers.create!(tile: @manzu_3, tsumogiri: false)
    second_river = current_state.rivers.create!(tile: @manzu_1, tsumogiri: false)
    third_river = current_state.rivers.create!(tile: @manzu_2, tsumogiri: false)
    assert_equal [ first_river, second_river, third_river ], current_state.rivers
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
    hand_1 = @user_player.hands.create!(tile: @manzu_1)
    hand_2 = @user_player.hands.create!(tile: @manzu_2, drawn: true)
    assert_equal [ hand_1, hand_2 ], @user_player.hands
    assert_not @user_player.rivers

    before_state_count = @user_player.player_states.count
    @user_player.discard(hand_2.id, steps(:step_2))
    assert_equal [ @manzu_1 ], @user_player.hands.map(&:tile)
    assert_equal [ @manzu_2 ], @user_player.rivers.map(&:tile)
    assert @user_player.rivers.first.tsumogiri?
    assert_equal before_state_count + 1, @user_player.player_states.count
    assert_not_equal hand_1, @user_player.hands.first

    manzu_1_hand_id = @user_player.hands.last.id
    @user_player.discard(manzu_1_hand_id, steps(:step_3))
    assert_equal [], @user_player.hands
    assert_equal [ @manzu_2, @manzu_1 ], @user_player.rivers.map(&:tile)
    assert @user_player.rivers.first.tsumogiri?
    assert_not @user_player.rivers.last.tsumogiri?
    assert_equal before_state_count + 2, @user_player.player_states.count
  end

  test '#ai?' do
    assert_not @user_player.ai?
    assert @ai_player.ai?
  end

  test 'relation_from_user' do
    @ai_player.stub(:user_seat_number, 0) do
      @ai_player.seat_order = 1
      assert_equal :shimocha, @ai_player.relation_from_user

      @ai_player.seat_order = 2
      assert_equal :toimen, @ai_player.relation_from_user

      @ai_player.seat_order = 3
      assert_equal :kamicha, @ai_player.relation_from_user

      @ai_player.seat_order = 0
      assert_equal :self, @ai_player.relation_from_user
    end

    @ai_player.stub(:user_seat_number, 1) do
      @ai_player.seat_order = 2
      assert_equal :shimocha, @ai_player.relation_from_user

      @ai_player.seat_order = 3
      assert_equal :toimen, @ai_player.relation_from_user

      @ai_player.seat_order = 0
      assert_equal :kamicha, @ai_player.relation_from_user

      @ai_player.seat_order = 1
      assert_equal :self, @ai_player.relation_from_user
    end

    @ai_player.stub(:user_seat_number, 2) do
      @ai_player.seat_order = 3
      assert_equal :shimocha, @ai_player.relation_from_user

      @ai_player.seat_order = 0
      assert_equal :toimen, @ai_player.relation_from_user

      @ai_player.seat_order = 1
      assert_equal :kamicha, @ai_player.relation_from_user

      @ai_player.seat_order = 2
      assert_equal :self, @ai_player.relation_from_user
    end

    @ai_player.stub(:user_seat_number, 3) do
      @ai_player.seat_order = 0
      assert_equal :shimocha, @ai_player.relation_from_user

      @ai_player.seat_order = 1
      assert_equal :toimen, @ai_player.relation_from_user

      @ai_player.seat_order = 2
      assert_equal :kamicha, @ai_player.relation_from_user

      @ai_player.seat_order = 3
      assert_equal :self, @ai_player.relation_from_user
    end
  end

  test '#drawn?' do
    @user_player.hands.create!(tile: @manzu_1)
    assert_not @user_player.drawn?

    @user_player.hands.create!(tile: @manzu_2, drawn: true)
    assert @user_player.drawn?
  end

  test '#score' do
    ton_1 = Round.create!(game: @game, number: 0)
    ton_1_honba_0 = Honba.create!(round: ton_1, number: 0)
    @user_player.game_records.create!(honba: ton_1_honba_0, score: 25000)
    assert_equal 25000, @user_player.score

    ton_1_honba_1 = Honba.create!(round: ton_1, number: 1)
    @user_player.game_records.create!(honba: ton_1_honba_1, score: 33000)
    assert_equal 33000, @user_player.score

    ton_2 = Round.create!(game: @game, number: 1)
    ton_2_honba_0 = Honba.create!(round: ton_2, number: 0)
    @user_player.game_records.create!(honba: ton_2_honba_0, score: 45000)
    assert_equal 45000, @user_player.score
  end

  test '#wind_name and #wind_code' do
    @user_player.stub(:host_seat_number, 0) do
      @user_player.seat_order = 0
      assert_equal '東', @user_player.wind_name
      assert_equal base_tiles(:ton).code, @user_player.wind_code

      @user_player.seat_order = 1
      assert_equal '南', @user_player.wind_name
      assert_equal base_tiles(:nan).code, @user_player.wind_code

      @user_player.seat_order = 2
      assert_equal '西', @user_player.wind_name
      assert_equal base_tiles(:sha).code, @user_player.wind_code

      @user_player.seat_order = 3
      assert_equal '北', @user_player.wind_name
      assert_equal base_tiles(:pei).code, @user_player.wind_code
    end

    @user_player.stub(:host_seat_number, 1) do
      @user_player.seat_order = 0
      assert_equal '北', @user_player.wind_name
      assert_equal base_tiles(:pei).code, @user_player.wind_code

      @user_player.seat_order = 1
      assert_equal '東', @user_player.wind_name
      assert_equal base_tiles(:ton).code, @user_player.wind_code

      @user_player.seat_order = 2
      assert_equal '南', @user_player.wind_name
      assert_equal base_tiles(:nan).code, @user_player.wind_code

      @user_player.seat_order = 3
      assert_equal '西', @user_player.wind_name
      assert_equal base_tiles(:sha).code, @user_player.wind_code
    end

    @user_player.stub(:host_seat_number, 2) do
      @user_player.seat_order = 0
      assert_equal '西', @user_player.wind_name
      assert_equal base_tiles(:sha).code, @user_player.wind_code

      @user_player.seat_order = 1
      assert_equal '北', @user_player.wind_name
      assert_equal base_tiles(:pei).code, @user_player.wind_code

      @user_player.seat_order = 2
      assert_equal '東', @user_player.wind_name
      assert_equal base_tiles(:ton).code, @user_player.wind_code

      @user_player.seat_order = 3
      assert_equal '南', @user_player.wind_name
      assert_equal base_tiles(:nan).code, @user_player.wind_code
    end

    @user_player.stub(:host_seat_number, 3) do
      @user_player.seat_order = 0
      assert_equal '南', @user_player.wind_name
      assert_equal base_tiles(:nan).code, @user_player.wind_code

      @user_player.seat_order = 1
      assert_equal '西', @user_player.wind_name
      assert_equal base_tiles(:sha).code, @user_player.wind_code

      @user_player.seat_order = 2
      assert_equal '北', @user_player.wind_name
      assert_equal base_tiles(:pei).code, @user_player.wind_code

      @user_player.seat_order = 3
      assert_equal '東', @user_player.wind_name
      assert_equal base_tiles(:ton).code, @user_player.wind_code
    end
  end
end
