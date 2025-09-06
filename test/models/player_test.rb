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

  test '.ordered orders by seat_order' do
    game = games(:training)
    game.players.delete_all
    player_4 = game.players.create!(user: @user, seat_order: 3)
    player_3 = game.players.create!(ai: @ai, seat_order: 2)
    player_2 = game.players.create!(ai: @ai, seat_order: 1)
    player_1 = game.players.create!(ai: @ai, seat_order: 0)
    assert_equal [ player_1, player_2, player_3, player_4 ], game.players.ordered.to_a
  end

  test '#hands orders by tile_code/tile_kind with drawn last of latest hands' do
    current_state = @user_player.player_states.ordered.last
    current_state.hands.delete_all

    drawn_hand = current_state.hands.create!(tile: @manzu_1, drawn: true)
    hand_3 = current_state.hands.create!(tile: @manzu_3)
    hand_2 = current_state.hands.create!(tile: @manzu_2)
    assert_equal [ hand_2, hand_3, drawn_hand ], @user_player.hands
  end

  test '#rivers orders created_at of latest rivers' do
    current_state = @user_player.player_states.ordered.last
    current_state.rivers.delete_all

    first_river = current_state.rivers.create!(tile: @manzu_3, tsumogiri: false)
    second_river = current_state.rivers.create!(tile: @manzu_1, tsumogiri: false)
    third_river = current_state.rivers.create!(tile: @manzu_2, tsumogiri: false)
    assert_equal [ first_river, second_river, third_river ], current_state.rivers
  end

  test '#melds orders number of latest melds' do
    current_state = @user_player.player_states.ordered.last
    current_state.melds.delete_all

    first_melds = current_state.melds.create!(tile: @manzu_3, kind: :chi, number: 0)
    second_melds = current_state.melds.create!(tile: @manzu_1, kind: :chi, number: 1)
    third_melds = current_state.melds.create!(tile: @manzu_2, kind: :chi, number: 2)
    assert_equal [ first_melds, second_melds, third_melds ], current_state.melds
  end

  test '#receive creates hands in current_state' do
    state_count = @user_player.player_states.count
    @user_player.receive(@manzu_2)
    current_hand_tiles = @user_player.player_states.ordered.last.hands.all.map(&:tile)
    assert_equal [ @manzu_2 ], current_hand_tiles
    assert_equal state_count, @user_player.player_states.count

    @user_player.receive(@manzu_1)
    current_hand_tiles = @user_player.player_states.ordered.last.hands.all.map(&:tile)
    assert_equal [ @manzu_2, @manzu_1 ], current_hand_tiles
    assert_equal state_count, @user_player.player_states.count
  end

  test '#draw adds drawn tile to hands in new player_state' do
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

  test '#discard moves target tile from hands to rivers in new player_state' do
    hand_1 = @user_player.hands.create!(tile: @manzu_1)
    hand_2 = @user_player.hands.create!(tile: @manzu_2, drawn: true)
    assert_equal [ hand_1, hand_2 ], @user_player.hands
    assert_not @user_player.rivers

    before_state_count = @user_player.player_states.count
    discarded_tile = @user_player.discard(hand_2.id, steps(:step_2))
    assert_equal [ @manzu_1 ], @user_player.hands.map(&:tile)
    assert_equal [ @manzu_2 ], @user_player.rivers.map(&:tile)
    assert @user_player.rivers.first.tsumogiri?
    assert_equal before_state_count + 1, @user_player.player_states.count
    assert_not_equal hand_1, @user_player.hands.first
    assert_equal @manzu_2, discarded_tile

    manzu_1_hand_id = @user_player.hands.last.id
    discarded_tile = @user_player.discard(manzu_1_hand_id, steps(:step_3))
    assert_equal [], @user_player.hands
    assert_equal [ @manzu_2, @manzu_1 ], @user_player.rivers.map(&:tile)
    assert @user_player.rivers.first.tsumogiri?
    assert_not @user_player.rivers.last.tsumogiri?
    assert_equal before_state_count + 2, @user_player.player_states.count
    assert_equal @manzu_1, discarded_tile
  end

  test '#steal chi from kamicha removes hands and sets melds' do
    state = @user_player.player_states.ordered.last
    state.hands.create!(tile: @manzu_1)
    state.hands.create!(tile: @manzu_2)
    kamicha_player = @ai_player
    before_state_count = @user_player.player_states.count

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        furo_tiles = [ @manzu_1, @manzu_2 ]
        discarded_tile = @manzu_3
        @user_player.steal(kamicha_player, :chi, furo_tiles, discarded_tile, steps(:step_2))
        assert_equal [ discarded_tile, @manzu_1, @manzu_2 ], @user_player.melds.map(&:tile)
        assert_equal [ 'kamicha', nil, nil ], @user_player.melds.map(&:from)
        assert_equal [ 'chi', 'chi', 'chi' ], @user_player.melds.map(&:kind)
        assert_equal [], @user_player.hands.map(&:tile)
        assert_equal before_state_count + 1, @user_player.player_states.count
      end
    end
  end

  test '#steal pon from shimocha removes hands and sets melds' do
    state = @user_player.player_states.ordered.last
    ton_1 = tiles(:first_ton)
    ton_2 = tiles(:second_ton)
    ton_3 = tiles(:third_ton)
    state.hands.create!(tile: ton_1)
    state.hands.create!(tile: ton_2)
    shimocha_player = @ai_player
    before_state_count = @user_player.player_states.count

    shimocha_player.stub(:seat_order, 0) do
      @user_player.stub(:seat_order, 3) do
        furo_tiles = [ ton_1, ton_2 ]
        discarded_tile = ton_3
        @user_player.steal(shimocha_player, :pon, furo_tiles, discarded_tile, steps(:step_2))
        assert_equal [ ton_1, ton_2, discarded_tile ], @user_player.melds.map(&:tile)
        assert_equal [ nil, nil, 'shimocha' ], @user_player.melds.map(&:from)
        assert_equal [ 'pon', 'pon', 'pon' ], @user_player.melds.map(&:kind)
        assert_equal [], @user_player.hands.map(&:tile)
        assert_equal before_state_count + 1, @user_player.player_states.count
      end
    end
  end

  test '#steal daiminkan from toimen removes hands and sets melds' do
    state = @user_player.player_states.ordered.last
    ton_1 = tiles(:first_ton)
    ton_2 = tiles(:second_ton)
    ton_3 = tiles(:third_ton)
    ton_4 = tiles(:fourth_ton)
    state.hands.create!(tile: ton_1)
    state.hands.create!(tile: ton_2)
    state.hands.create!(tile: ton_3)
    toimen_player = @ai_player
    before_state_count = @user_player.player_states.count

    toimen_player.stub(:seat_order, 2) do
      @user_player.stub(:seat_order, 0) do
        furo_tiles = [ ton_1, ton_2, ton_3 ]
        discarded_tile = ton_4
        @user_player.steal(toimen_player, :daiminkan, furo_tiles, discarded_tile, steps(:step_2))
        assert_equal [ ton_1, discarded_tile, ton_2, ton_3 ], @user_player.melds.map(&:tile)
        assert_equal [ nil, 'toimen', nil, nil ], @user_player.melds.map(&:from)
        assert_equal [ 'daiminkan', 'daiminkan', 'daiminkan', 'daiminkan' ], @user_player.melds.map(&:kind)
        assert_equal [], @user_player.hands.map(&:tile)
        assert_equal before_state_count + 1, @user_player.player_states.count
      end
    end
  end

  test '#steal consecutive furo remove hands and sets melds' do
    state = @user_player.player_states.ordered.last
    ton_1 = tiles(:first_ton)
    ton_2 = tiles(:second_ton)
    ton_3 = tiles(:third_ton)
    state.hands.create!(tile: @manzu_1)
    state.hands.create!(tile: @manzu_2)
    state.hands.create!(tile: ton_1)
    state.hands.create!(tile: ton_2)
    toimen_player = @ai_player
    kamicha_player = players(:tenpai_speeder)
    before_state_count = @user_player.player_states.count

    toimen_player.stub(:seat_order, 2) do
      kamicha_player.stub(:seat_order, 3) do
        @user_player.stub(:seat_order, 0) do
          @user_player.steal(toimen_player, :pon, [ ton_1, ton_2 ], ton_3, steps(:step_2))
          assert_equal [ ton_1, ton_3, ton_2 ], @user_player.melds.map(&:tile)
          assert_equal [ nil, 'toimen', nil ], @user_player.melds.map(&:from)
          assert_equal [ 'pon', 'pon', 'pon' ], @user_player.melds.map(&:kind)
          assert_equal [ @manzu_1, @manzu_2 ], @user_player.hands.map(&:tile)
          assert_equal before_state_count + 1, @user_player.player_states.count

          @user_player.steal(kamicha_player, :chi, [ @manzu_1, @manzu_2 ], @manzu_3, steps(:step_3))
          assert_equal [ ton_1, ton_3, ton_2, @manzu_3, @manzu_1, @manzu_2 ], @user_player.melds.map(&:tile)
          assert_equal [ nil, 'toimen', nil, 'kamicha', nil, nil ], @user_player.melds.map(&:from)
          assert_equal [ 'pon', 'pon', 'pon', 'chi', 'chi', 'chi' ], @user_player.melds.map(&:kind)
          assert_equal [], @user_player.hands.map(&:tile)
          assert_equal before_state_count + 2, @user_player.player_states.count
        end
      end
    end
  end

  test '#stolen marks only the targeted river as stolen' do
    river_1 = @ai_player.player_states.last.rivers.create!(tile: @manzu_1, tsumogiri: false)
    river_2 = @ai_player.player_states.last.rivers.create!(tile: @manzu_2, tsumogiri: false)
    before_state_count = @ai_player.player_states.count
    assert_not river_1.stolen?
    assert_not river_2.stolen?

    @ai_player.stolen(@manzu_1, steps(:step_2))
    river_3 = @ai_player.rivers.first
    river_4 = @ai_player.rivers.last
    assert_equal @manzu_1, river_3.tile
    assert_equal @manzu_2, river_4.tile
    assert river_3.stolen?
    assert_not river_4.stolen?
    assert_equal before_state_count + 1, @ai_player.player_states.count

    @ai_player.stolen(@manzu_2, steps(:step_3))
    river_5 = @ai_player.rivers.first
    river_6 = @ai_player.rivers.last
    assert_equal @manzu_1, river_5.tile
    assert_equal @manzu_2, river_6.tile
    assert river_5.stolen?
    assert river_6.stolen?
    assert_equal before_state_count + 2, @ai_player.player_states.count
  end

  test '#ai?' do
    assert_not @user_player.ai?
    assert @ai_player.ai?
  end

  test '#user?' do
    assert_not @ai_player.user?
    assert @user_player.user?
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

  test '#can_furo? returns false when target_player is current_player' do
    player_state = @user_player.player_states.ordered.last
    hand_1_manzu_1 = Hand.create!(tile: tiles(:first_manzu_1), player_state:)
    hand_2_manzu_1 = Hand.create!(tile: tiles(:second_manzu_1), player_state:)
    pon_hands = [ hand_1_manzu_1, hand_2_manzu_1 ]
    target_player = @user_player

    @user_player.stub(:hands, pon_hands) do
      is_furo = @user_player.can_furo?(tiles(:third_manzu_1), target_player)
      assert_not is_furo
    end
  end

  test '#can_furo? returns true when user can pon' do
    player_state = @user_player.player_states.ordered.last
    hand_1_manzu_1 = Hand.create!(tile: tiles(:first_manzu_1), player_state:)
    hand_2_manzu_1 = Hand.create!(tile: tiles(:second_manzu_1), player_state:)
    pon_hands = [ hand_1_manzu_1, hand_2_manzu_1 ]

    @user_player.stub(:hands, pon_hands) do
      is_furo = @user_player.can_furo?(tiles(:third_manzu_1), @ai_player)
      assert is_furo
    end
  end

  test '#can_furo? returns true when target_player is kamicha' do
    player_state = @user_player.player_states.ordered.last
    manzu_1 = Hand.create!(tile: tiles(:first_manzu_1), player_state:)
    manzu_2 = Hand.create!(tile: tiles(:first_manzu_2), player_state:)
    chi_hands = [ manzu_1, manzu_2 ]
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:hands, chi_hands) do
          is_furo = @user_player.can_furo?(tiles(:first_manzu_3), kamicha_player)
          assert is_furo
        end
      end
    end
  end

  test '#can_furo? returns false when target_player is shimocha' do
    player_state = @user_player.player_states.ordered.last
    manzu_1 = Hand.create!(tile: tiles(:first_manzu_1), player_state:)
    manzu_2 = Hand.create!(tile: tiles(:first_manzu_2), player_state:)
    chi_hands = [ manzu_1, manzu_2 ]
    shimocha_player = @ai_player

    shimocha_player.stub(:seat_order, 1) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:hands, chi_hands) do
          is_furo = @user_player.can_furo?(tiles(:first_manzu_3), shimocha_player)
          assert_not is_furo
        end
      end
    end
  end

  test '#can_furo? returns false when target_player is toimen' do
    player_state = @user_player.player_states.ordered.last
    manzu_1 = Hand.create!(tile: tiles(:first_manzu_1), player_state:)
    manzu_2 = Hand.create!(tile: tiles(:first_manzu_2), player_state:)
    chi_hands = [ manzu_1, manzu_2 ]
    toimen_player = @ai_player

    toimen_player.stub(:seat_order, 2) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:hands, chi_hands) do
          is_furo = @user_player.can_furo?(tiles(:first_manzu_3), toimen_player)
          assert_not is_furo
        end
      end
    end
  end

  test '#can_furo? returns false when user can not pon and chi' do
    player_state = @user_player.player_states.ordered.last
    manzu_1 = Hand.create!(tile: tiles(:first_manzu_1), player_state:)
    manzu_5 = Hand.create!(tile: tiles(:first_manzu_5), player_state:)
    hands = [ manzu_1, manzu_5 ]
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:hands, hands) do
          is_furo = @user_player.can_furo?(tiles(:first_manzu_3), kamicha_player)
          assert_not is_furo
        end
      end
    end
  end

  test 'player can not chi zihai' do
    player_state = @user_player.player_states.ordered.last
    ton = Hand.create!(tile: tiles(:first_ton), player_state:)
    nan = Hand.create!(tile: tiles(:first_nan), player_state:)
    haku = Hand.create!(tile: tiles(:first_haku), player_state:)
    hatsu = Hand.create!(tile: tiles(:first_hatsu), player_state:)
    zihai_hands = [ ton, nan, haku, hatsu ]
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:hands, zihai_hands) do
          is_furo = @user_player.can_furo?(tiles(:first_sha), kamicha_player)
          assert_not is_furo

          is_furo = @user_player.can_furo?(tiles(:first_chun), kamicha_player)
          assert_not is_furo
        end
      end
    end
  end

  test '#find_furo_candidates only pon' do
    player_state = @user_player.player_states.ordered.last
    hand_1_manzu_1 = Hand.create!(tile: tiles(:first_manzu_1), player_state:)
    hand_2_manzu_1 = Hand.create!(tile: tiles(:second_manzu_1), player_state:)
    pon_hands = [ hand_1_manzu_1, hand_2_manzu_1 ]

    @user_player.stub(:hands, pon_hands) do
      furo_candidates = @user_player.find_furo_candidates(tiles(:third_manzu_1), @ai_player)
      assert_equal pon_hands, furo_candidates[:pon]
      assert_nil furo_candidates[:chi]
      assert_nil furo_candidates[:kan]
    end
  end

  test '#find_furo_candidates only kan' do
    player_state = @user_player.player_states.ordered.last
    hand_1_manzu_1 = Hand.create!(tile: tiles(:first_manzu_1), player_state:)
    hand_2_manzu_1 = Hand.create!(tile: tiles(:second_manzu_1), player_state:)
    hand_3_manzu_1 = Hand.create!(tile: tiles(:third_manzu_1), player_state:)
    kan_hands = [ hand_1_manzu_1, hand_2_manzu_1, hand_3_manzu_1 ]

    @user_player.stub(:hands, kan_hands) do
      furo_candidates = @user_player.find_furo_candidates(tiles(:fourth_manzu_1), @ai_player)
      assert_equal [ hand_1_manzu_1, hand_2_manzu_1 ], furo_candidates[:pon]
      assert_nil furo_candidates[:chi]
      assert_equal kan_hands, furo_candidates[:kan]
    end
  end

  test '#find_furo_candidates only chi' do
    player_state = @user_player.player_states.ordered.last
    manzu_1 = Hand.create!(tile: tiles(:first_manzu_1), player_state:)
    manzu_2 = Hand.create!(tile: tiles(:first_manzu_2), player_state:)
    manzu_4 = Hand.create!(tile: tiles(:first_manzu_4), player_state:)
    manzu_5 = Hand.create!(tile: tiles(:first_manzu_5), player_state:)
    manzu_6 = Hand.create!(tile: tiles(:first_manzu_6), player_state:)
    manzu_8 = Hand.create!(tile: tiles(:first_manzu_8), player_state:)
    manzu_9 = Hand.create!(tile: tiles(:first_manzu_9), player_state:)
    chi_hands = [ manzu_1, manzu_2, manzu_4, manzu_5, manzu_6, manzu_8, manzu_9 ]
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:hands, chi_hands) do
          furo_candidates = @user_player.find_furo_candidates(tiles(:first_manzu_3), kamicha_player)
          assert_nil furo_candidates[:pon]
          assert_equal [ [ manzu_1, manzu_2 ], [ manzu_2, manzu_4 ], [ manzu_4, manzu_5 ] ], furo_candidates[:chi]
          assert_nil furo_candidates[:kan]

          furo_candidates = @user_player.find_furo_candidates(tiles(:first_manzu_7), kamicha_player)
          assert_nil furo_candidates[:pon]
          assert_equal [ [ manzu_5, manzu_6 ], [ manzu_6, manzu_8 ], [ manzu_8, manzu_9 ] ], furo_candidates[:chi]
          assert_nil furo_candidates[:kan]
        end
      end
    end
  end

  test '#find_furo_candidates pon_and_chi_candidates' do
    player_state = @user_player.player_states.ordered.last
    manzu_1a = Hand.create!(tile: tiles(:first_manzu_1), player_state:)
    manzu_1b = Hand.create!(tile: tiles(:second_manzu_1), player_state:)
    manzu_2a = Hand.create!(tile: tiles(:first_manzu_2), player_state:)
    manzu_2b = Hand.create!(tile: tiles(:second_manzu_2), player_state:)
    manzu_3a = Hand.create!(tile: tiles(:first_manzu_3), player_state:)
    manzu_3b = Hand.create!(tile: tiles(:second_manzu_3), player_state:)
    manzu_4a = Hand.create!(tile: tiles(:first_manzu_4), player_state:)
    manzu_4b = Hand.create!(tile: tiles(:second_manzu_4), player_state:)
    manzu_5a = Hand.create!(tile: tiles(:first_manzu_5), player_state:)
    manzu_5b = Hand.create!(tile: tiles(:second_manzu_5), player_state:)
    pon_and_chi_hands = [ manzu_1a, manzu_1b, manzu_2a, manzu_2b, manzu_3a, manzu_3b, manzu_4a, manzu_4b, manzu_5a, manzu_5b ]
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:hands, pon_and_chi_hands) do
          furo_candidates = @user_player.find_furo_candidates(tiles(:third_manzu_3), kamicha_player)
          assert_equal [ manzu_3a, manzu_3b ], furo_candidates[:pon]
          assert_equal [ [ manzu_1a, manzu_2a ], [ manzu_2a, manzu_4a ], [ manzu_4a, manzu_5a ] ], furo_candidates[:chi]
          assert_nil furo_candidates[:kan]
        end
      end
    end
  end

  test '#find_furo_candidates nothing' do
    player_state = @user_player.player_states.ordered.last
    manzu_1 = Hand.create!(tile: tiles(:first_manzu_1), player_state:)
    manzu_5 = Hand.create!(tile: tiles(:first_manzu_5), player_state:)
    manzu_9 = Hand.create!(tile: tiles(:first_manzu_9), player_state:)
    hands = [ manzu_1, manzu_5, manzu_9 ]

    @user_player.stub(:hands, hands) do
      furo_candidates = @user_player.find_furo_candidates(tiles(:second_manzu_1), @ai_player)
      assert_equal({}, furo_candidates)
    end
  end
end
