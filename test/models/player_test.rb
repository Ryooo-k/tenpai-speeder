# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class PlayerTest < ActiveSupport::TestCase
  def setup
    @user_player = players(:ryo)
    @ai_player = players(:menzen_tenpai_speeder)
    @user = users(:ryo)
    @game = games(:tonpuu)
    @manzu_1 = tiles(:first_manzu_1)
    @manzu_2 = tiles(:first_manzu_2)
    @manzu_3 = tiles(:first_manzu_3)
    @ton_1 = tiles(:first_ton)
    @ton_2 = tiles(:second_ton)
    @ton_3 = tiles(:third_ton)
    @haku = tiles(:first_haku)
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
    ai = ais(:tenpai_speeder)
    game.players.delete_all
    player_4 = game.players.create!(user: @user, seat_order: 3)
    player_3 = game.players.create!(ai:, seat_order: 2)
    player_2 = game.players.create!(ai:, seat_order: 1)
    player_1 = game.players.create!(ai:, seat_order: 0)
    assert_equal [ player_1, player_2, player_3, player_4 ], game.players.ordered.to_a
  end

  test '#hands returns sorted hands from latest state with hands' do
    @user_player.current_state.hands.delete_all
    assert_equal [], @user_player.hands

    @user_player.current_state.hands.create!(tile: @manzu_2)
    assert_equal [ @manzu_2 ], @user_player.hands.map(&:tile)

    @user_player.current_state.hands.create!(tile: @manzu_1)
    assert_equal [ @manzu_1, @manzu_2 ], @user_player.hands.map(&:tile)

    @user_player.player_states.create!(step: steps(:step_2))
    assert_not_equal [], @user_player.hands
    assert_equal [ @manzu_1, @manzu_2 ], @user_player.hands.map(&:tile)
  end

  test 'drawn hand is last position' do
    @user_player.current_state.hands.create!(tile: @manzu_1, drawn: true)
    assert_equal [ @manzu_1 ], @user_player.hands.map(&:tile)

    @user_player.current_state.hands.create!(tile: @manzu_2)
    assert_equal [ @manzu_2, @manzu_1 ], @user_player.hands.map(&:tile)

    @user_player.current_state.hands.create!(tile: @manzu_3)
    assert_equal [ @manzu_2, @manzu_3, @manzu_1 ], @user_player.hands.map(&:tile)
  end

  test '#rivers returns ordered rivers from latest state with rivers' do
    @user_player.current_state.rivers.delete_all
    assert_equal [], @user_player.rivers

    @user_player.current_state.rivers.create!(tile: @manzu_2, tsumogiri: false)
    assert_equal [ @manzu_2 ], @user_player.rivers.map(&:tile)

    @user_player.current_state.rivers.create!(tile: @manzu_1, tsumogiri: false)
    assert_equal [ @manzu_2, @manzu_1 ], @user_player.rivers.map(&:tile)

    @user_player.player_states.create!(step: steps(:step_2))
    assert_not_equal [], @user_player.rivers
    assert_equal [ @manzu_2, @manzu_1 ], @user_player.rivers.map(&:tile)
  end

  test '#rivers not includes stolen river' do
    @user_player.current_state.rivers.delete_all
    assert_equal [], @user_player.rivers

    @user_player.current_state.rivers.create!(tile: @manzu_2, tsumogiri: false, stolen: true)
    assert_equal [], @user_player.rivers
  end

  test '#melds returns ordered melds from latest state with melds' do
    @user_player.current_state.melds.delete_all
    assert_equal [], @user_player.melds

    @user_player.current_state.melds.create!(tile: @manzu_3, kind: :chi, number: 0)
    @user_player.current_state.melds.create!(tile: @manzu_1, kind: :chi, number: 1)
    @user_player.current_state.melds.create!(tile: @manzu_2, kind: :chi, number: 2)
    assert_equal [ @manzu_3, @manzu_1, @manzu_2 ], @user_player.melds.map(&:tile)

    @user_player.player_states.create!(step: steps(:step_2))
    assert_not_equal [], @user_player.melds
    assert_equal [ @manzu_3, @manzu_1, @manzu_2 ], @user_player.melds.map(&:tile)
  end

  test '#current_state returns state of current_step_number ' do
    step_1 = steps(:step_1)
    step_2 = steps(:step_2)
    @user_player.player_states.create!(step: step_1)
    @user_player.player_states.create!(step: step_2)

    @user_player.stub(:current_step_number, step_1.number) do
      expected = @user_player.player_states.find_by!(step: step_1)
      assert_equal expected, @user_player.current_state
    end

    @user_player.stub(:current_step_number, step_2.number) do
      expected = @user_player.player_states.find_by!(step: step_2)
      assert_equal expected, @user_player.current_state
    end
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

  test '#draw adds drawn tile to hands' do
    step_1 = steps(:step_1)
    @user_player.stub(:current_step_number, step_1.number) do 
      @user_player.draw(@manzu_3, step_1)
      assert_equal [ @manzu_3 ], @user_player.hands.map(&:tile)
      assert @user_player.hands.first.drawn?
    end

    step_2 = steps(:step_2)
    @user_player.stub(:current_step_number, step_2.number) do 
      @user_player.draw(@manzu_1, step_2)
      assert_equal [ @manzu_3, @manzu_1 ], @user_player.hands.map(&:tile)
      assert @user_player.hands.last.drawn?
      assert_not @user_player.hands.first.drawn?
    end

    step_3 = steps(:step_3)
    @user_player.stub(:current_step_number, step_3.number) do 
      @user_player.draw(@manzu_2, step_3)
      assert_equal [ @manzu_1, @manzu_3, @manzu_2 ], @user_player.hands.map(&:tile)
      assert @user_player.hands.last.drawn?
      @user_player.hands[...-1].each { |hand| assert_not hand.drawn? }
    end
  end

  test '#draw creates player_state' do
    before_state_count = @user_player.player_states.count

    step_1 = steps(:step_1)
    @user_player.stub(:current_step_number, step_1.number) do 
      @user_player.draw(@manzu_3, step_1)
      assert_equal before_state_count + 1, @user_player.player_states.count
    end

    step_2 = steps(:step_2)
    @user_player.stub(:current_step_number, step_2.number) do 
      @user_player.draw(@manzu_1, step_2)
      assert_equal before_state_count + 2, @user_player.player_states.count
    end
  end

  test '#discard moves target tile from hands to rivers' do
    hand_1 = @user_player.current_state.hands.create!(tile: @manzu_1)
    hand_2 = @user_player.current_state.hands.create!(tile: @manzu_2)
    hand_3 = @user_player.current_state.hands.create!(tile: @manzu_3, drawn: true)
    assert_equal [ hand_1, hand_2, hand_3 ], @user_player.hands
    assert_equal [], @user_player.rivers

    step_2 = steps(:step_2)
    @user_player.stub(:current_step_number, step_2.number) do 
      discarded_tile = @user_player.discard(hand_3.id, step_2)
      assert_equal [ @manzu_1, @manzu_2 ], @user_player.hands.map(&:tile)
      assert_equal [ @manzu_3 ], @user_player.rivers.map(&:tile)
      assert @user_player.rivers.first.tsumogiri?
      assert_not_equal hand_1, @user_player.hands.first
      assert_equal @manzu_3, discarded_tile
    end

    step_3 = steps(:step_3)
    @user_player.stub(:current_step_number, step_3.number) do 
      manzu_1_hand_id = @user_player.hands.first.id
      discarded_tile = @user_player.discard(manzu_1_hand_id, step_3)
      assert_equal [ @manzu_2 ], @user_player.hands.map(&:tile)
      assert_equal [ @manzu_3, @manzu_1 ], @user_player.rivers.map(&:tile)
      assert @user_player.rivers.first.tsumogiri?
      assert_not @user_player.rivers.last.tsumogiri?
      assert_equal @manzu_1, discarded_tile
    end
  end

  test '#discard creates player_state' do
    hand_1 = @user_player.current_state.hands.create!(tile: @manzu_1)
    hand_2 = @user_player.current_state.hands.create!(tile: @manzu_2)
    hand_3 = @user_player.current_state.hands.create!(tile: @manzu_3, drawn: true)
    before_state_count = @user_player.player_states.count

    step_2 = steps(:step_2)
    @user_player.stub(:current_step_number, step_2.number) do 
      discarded_tile = @user_player.discard(hand_3.id, step_2)
      assert_equal before_state_count + 1, @user_player.player_states.count
    end

    step_3 = steps(:step_3)
    @user_player.stub(:current_step_number, step_3.number) do 
      manzu_1_hand_id = @user_player.hands.first.id
      discarded_tile = @user_player.discard(manzu_1_hand_id, step_3)
      assert_equal before_state_count + 2, @user_player.player_states.count
    end
  end

  test '#steal chi from kamicha removes hands and sets melds' do
    @user_player.current_state.hands.create!(tile: @manzu_1)
    @user_player.current_state.hands.create!(tile: @manzu_2)
    @user_player.current_state.hands.create!(tile: @haku)
    kamicha_player = @ai_player
    step_2 = steps(:step_2)

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:current_step_number, step_2.number) do
          furo_tiles = [ @manzu_1, @manzu_2 ]
          discarded_tile = @manzu_3
          @user_player.steal(kamicha_player, :chi, furo_tiles, discarded_tile, step_2)
          assert_equal [ discarded_tile, @manzu_1, @manzu_2 ], @user_player.melds.map(&:tile)
          assert_equal [ 'kamicha', nil, nil ], @user_player.melds.map(&:from)
          assert_equal [ 'chi', 'chi', 'chi' ], @user_player.melds.map(&:kind)
          assert_equal [ @haku ], @user_player.hands.map(&:tile)
        end
      end
    end
  end

  test '#steal pon from shimocha removes hands and sets melds' do
    @user_player.current_state.hands.create!(tile: @ton_1)
    @user_player.current_state.hands.create!(tile: @ton_2)
    @user_player.current_state.hands.create!(tile: @haku)
    shimocha_player = @ai_player
    step_2 = steps(:step_2)

    shimocha_player.stub(:seat_order, 0) do
      @user_player.stub(:seat_order, 3) do
        @user_player.stub(:current_step_number, step_2.number) do
          furo_tiles = [ @ton_1, @ton_2 ]
          discarded_tile = @ton_3
          @user_player.steal(shimocha_player, :pon, furo_tiles, discarded_tile, step_2)
          assert_equal [ @ton_1, @ton_2, discarded_tile ], @user_player.melds.map(&:tile)
          assert_equal [ nil, nil, 'shimocha' ], @user_player.melds.map(&:from)
          assert_equal [ 'pon', 'pon', 'pon' ], @user_player.melds.map(&:kind)
          assert_equal [ @haku ], @user_player.hands.map(&:tile)
        end
      end
    end
  end

  test '#steal daiminkan from toimen removes hands and sets melds' do
    @user_player.current_state.hands.create!(tile: @ton_1)
    @user_player.current_state.hands.create!(tile: @ton_2)
    @user_player.current_state.hands.create!(tile: @ton_3)
    @user_player.current_state.hands.create!(tile: @haku)
    toimen_player = @ai_player
    step_2 = steps(:step_2)

    toimen_player.stub(:seat_order, 2) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:current_step_number, step_2.number) do
          furo_tiles = [ @ton_1, @ton_2, @ton_3 ]
          discarded_tile = tiles(:fourth_ton)
          @user_player.steal(toimen_player, :daiminkan, furo_tiles, discarded_tile, steps(:step_2))
          assert_equal [ @ton_1, discarded_tile, @ton_2, @ton_3 ], @user_player.melds.map(&:tile)
          assert_equal [ nil, 'toimen', nil, nil ], @user_player.melds.map(&:from)
          assert_equal [ 'daiminkan', 'daiminkan', 'daiminkan', 'daiminkan' ], @user_player.melds.map(&:kind)
          assert_equal [ @haku ], @user_player.hands.map(&:tile)
        end
      end
    end
  end

  test '#steal consecutive furo remove hands and sets melds' do
    @user_player.current_state.hands.create!(tile: @manzu_1)
    @user_player.current_state.hands.create!(tile: @manzu_2)
    @user_player.current_state.hands.create!(tile: @ton_1)
    @user_player.current_state.hands.create!(tile: @ton_2)
    @user_player.current_state.hands.create!(tile: @haku)
    toimen_player = @ai_player
    kamicha_player = players(:tenpai_speeder)
    step_2 = steps(:step_2)
    step_3 = steps(:step_3)

    toimen_player.stub(:seat_order, 2) do
      kamicha_player.stub(:seat_order, 3) do
        @user_player.stub(:seat_order, 0) do
          @user_player.stub(:current_step_number, step_2.number) do
            @user_player.steal(toimen_player, :pon, [ @ton_1, @ton_2 ], @ton_3, step_2)
            assert_equal [ @ton_1, @ton_3, @ton_2 ], @user_player.melds.map(&:tile)
            assert_equal [ nil, 'toimen', nil ], @user_player.melds.map(&:from)
            assert_equal [ 'pon', 'pon', 'pon' ], @user_player.melds.map(&:kind)
            assert_equal [ @manzu_1, @manzu_2, @haku ], @user_player.hands.map(&:tile)
          end

          @user_player.stub(:current_step_number, step_3.number) do
            @user_player.steal(kamicha_player, :chi, [ @manzu_1, @manzu_2 ], @manzu_3, step_3)
            assert_equal [ @manzu_3, @manzu_1, @manzu_2 , @ton_1, @ton_3, @ton_2], @user_player.melds.map(&:tile)
            assert_equal [ 'kamicha', nil, nil, nil, 'toimen', nil ], @user_player.melds.map(&:from)
            assert_equal [ 'chi', 'chi', 'chi', 'pon', 'pon', 'pon' ], @user_player.melds.map(&:kind)
            assert_equal [ @haku ], @user_player.hands.map(&:tile)
          end
        end
      end
    end
  end

  test '#steal creates player_state' do
    @user_player.current_state.hands.create!(tile: @manzu_1)
    @user_player.current_state.hands.create!(tile: @manzu_2)
    @user_player.current_state.hands.create!(tile: @haku)
    kamicha_player = @ai_player
    before_state_count = @user_player.player_states.count
    step_2 = steps(:step_2)

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:current_step_number, step_2.number) do
          @user_player.steal(kamicha_player, :chi, [ @manzu_1, @manzu_2 ], @manzu_3, step_2)
          assert_equal before_state_count + 1, @user_player.player_states.count
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

    step_2 = steps(:step_2)
    @ai_player.stub(:current_step_number, step_2.number) do
      @ai_player.stolen(@manzu_1, step_2)
      manzu_1 = @ai_player.current_state.rivers.first
      manzu_2 = @ai_player.current_state.rivers.last
      assert manzu_1.stolen?
      assert_not manzu_2.stolen?
    end

    step_3 = steps(:step_3)
    @ai_player.stub(:current_step_number, step_3.number) do
      @ai_player.stolen(@manzu_2, steps(:step_3))
      manzu_1 = @ai_player.current_state.rivers.first
      manzu_2 = @ai_player.current_state.rivers.last
      assert manzu_1.stolen?
      assert manzu_2.stolen?
    end
  end

  test '#stolen creates player_state' do
    river_1 = @ai_player.player_states.last.rivers.create!(tile: @manzu_1, tsumogiri: false)
    river_2 = @ai_player.player_states.last.rivers.create!(tile: @manzu_2, tsumogiri: false)
    before_state_count = @ai_player.player_states.count

    step_2 = steps(:step_2)
    @ai_player.stub(:current_step_number, step_2.number) do
      @ai_player.stolen(@manzu_1, step_2)
      assert_equal before_state_count + 1, @ai_player.player_states.count
    end

    step_3 = steps(:step_3)
    @ai_player.stub(:current_step_number, step_3.number) do
      @ai_player.stolen(@manzu_2, steps(:step_3))
      assert_equal before_state_count + 2, @ai_player.player_states.count
    end
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
    @user_player.current_state.hands.create!(tile: @manzu_1)
    assert_not @user_player.drawn?

    @user_player.current_state.hands.create!(tile: @manzu_2, drawn: true)
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
    hand_1_manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    hand_2_manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:second_manzu_1))
    pon_hands = [ hand_1_manzu_1, hand_2_manzu_1 ]

    @user_player.stub(:hands, pon_hands) do
      is_furo = @user_player.can_furo?(tiles(:third_manzu_1), @user_player)
      assert_not is_furo
    end
  end

  test '#can_furo? returns true when user can pon' do
    hand_1_manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    hand_2_manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:second_manzu_1))
    pon_hands = [ hand_1_manzu_1, hand_2_manzu_1 ]

    @user_player.stub(:hands, pon_hands) do
      is_furo = @user_player.can_furo?(tiles(:third_manzu_1), @ai_player)
      assert is_furo
    end
  end

  test '#can_furo? returns true when target_player is kamicha' do
    manzu_1 =  @user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    manzu_2 =  @user_player.current_state.hands.create!(tile: tiles(:first_manzu_2))
    chi_hands = [ manzu_1, manzu_2 ]
    manzu_3 = tiles(:first_manzu_3)
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:hands, chi_hands) do
          is_furo = @user_player.can_furo?(manzu_3, kamicha_player)
          assert is_furo
        end
      end
    end
  end

  test '#can_furo? returns false when target_player is shimocha' do
    manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    manzu_2 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_2))
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
    manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    manzu_2 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_2))
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
    manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    manzu_5 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_5))
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
    ton = @user_player.current_state.hands.create!(tile: tiles(:first_ton))
    nan = @user_player.current_state.hands.create!(tile: tiles(:first_nan))
    haku = @user_player.current_state.hands.create!(tile: tiles(:first_haku))
    hatsu = @user_player.current_state.hands.create!(tile: tiles(:first_hatsu))
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
    hand_1_manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    hand_2_manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:second_manzu_1))
    pon_hands = [ hand_1_manzu_1, hand_2_manzu_1 ]

    @user_player.stub(:hands, pon_hands) do
      furo_candidates = @user_player.find_furo_candidates(tiles(:third_manzu_1), @ai_player)
      assert_equal pon_hands, furo_candidates[:pon]
      assert_nil furo_candidates[:chi]
      assert_nil furo_candidates[:kan]
    end
  end

  test '#find_furo_candidates only kan' do
    hand_1_manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    hand_2_manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:second_manzu_1))
    hand_3_manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:third_manzu_1))
    kan_hands = [ hand_1_manzu_1, hand_2_manzu_1, hand_3_manzu_1 ]

    @user_player.stub(:hands, kan_hands) do
      furo_candidates = @user_player.find_furo_candidates(tiles(:fourth_manzu_1), @ai_player)
      assert_equal [ hand_1_manzu_1, hand_2_manzu_1 ], furo_candidates[:pon]
      assert_nil furo_candidates[:chi]
      assert_equal kan_hands, furo_candidates[:kan]
    end
  end

  test '#find_furo_candidates only chi' do
    manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    manzu_2 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_2))
    manzu_4 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_4))
    manzu_5 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_5))
    manzu_6 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_6))
    manzu_8 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_8))
    manzu_9 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_9))
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
    manzu_1a = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    manzu_1b = @user_player.current_state.hands.create!(tile: tiles(:second_manzu_1))
    manzu_2a = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_2))
    manzu_2b = @user_player.current_state.hands.create!(tile: tiles(:second_manzu_2))
    manzu_3a = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_3))
    manzu_3b = @user_player.current_state.hands.create!(tile: tiles(:second_manzu_3))
    manzu_4a = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_4))
    manzu_4b = @user_player.current_state.hands.create!(tile: tiles(:second_manzu_4))
    manzu_5a = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_5))
    manzu_5b = @user_player.current_state.hands.create!(tile: tiles(:second_manzu_5))
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
    manzu_1 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_1))
    manzu_5 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_5))
    manzu_9 = @user_player.current_state.hands.create!(tile: tiles(:first_manzu_9))
    hands = [ manzu_1, manzu_5, manzu_9 ]

    @user_player.stub(:hands, hands) do
      furo_candidates = @user_player.find_furo_candidates(tiles(:second_manzu_1), @ai_player)
      assert_equal({}, furo_candidates)
    end
  end
end
