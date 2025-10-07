# frozen_string_literal: true

require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  include GameTestHelper

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
    assert_equal [], @user_player.hands

    manzu_1, manzu_2 = set_hands('m12', @user_player)
    assert_equal [ manzu_1, manzu_2 ], @user_player.hands

    @user_player.player_states.create!(step: steps(:step_2))
    assert_not_equal [], @user_player.hands
    assert_equal [ manzu_1, manzu_2 ], @user_player.hands
  end

  test 'drawn hand is last position' do
    manzu_2, manzu_3, drawn_tile = set_hands('m23 m1', @user_player)
    assert_equal [ manzu_2, manzu_3, drawn_tile ], @user_player.hands
  end

  test '#rivers returns ordered rivers from latest state with rivers' do
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

  test '#melds returns ordered melds from latest state with melds(kamicha -> chi)' do
    manzu_2, manzu_1, manzu_3 = set_melds('m12+3', @user_player)
    assert_equal [ manzu_2, manzu_1, manzu_3 ], @user_player.melds

    @user_player.player_states.create!(step: steps(:step_2))
    assert_not_equal [], @user_player.melds
    assert_equal [ manzu_2, manzu_1, manzu_3 ], @user_player.melds
  end

  test '#melds returns ordered melds from latest state with melds(toimen -> pon)' do
    manzu_1_a, stone_manzu_1, manzu_1_b = set_melds('m111=', @user_player)
    assert_equal [ manzu_1_a, stone_manzu_1, manzu_1_b ], @user_player.melds

    @user_player.player_states.create!(step: steps(:step_2))
    assert_not_equal [], @user_player.melds
    assert_equal [ manzu_1_a, stone_manzu_1, manzu_1_b ], @user_player.melds
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
    manzu_1, manzu_2, manzu_3 = set_hands('m123', @user_player)

    step_2 = steps(:step_2)
    @user_player.stub(:current_step_number, step_2.number) do
      @user_player.discard(manzu_3.id, step_2)
      assert_equal [ manzu_1.tile, manzu_2.tile ], @user_player.hands.map(&:tile)
      assert_equal [ manzu_3.tile ], @user_player.rivers.map(&:tile)
    end

    step_3 = steps(:step_3)
    @user_player.stub(:current_step_number, step_3.number) do
      manzu_1 = @user_player.hands.first
      @user_player.discard(manzu_1.id, step_3)
      assert_equal [ manzu_2.tile ], @user_player.hands.map(&:tile)
      assert_equal [ manzu_3.tile, manzu_1.tile ], @user_player.rivers.map(&:tile)
    end
  end

  test '#discard returns target tile' do
    manzu_1, manzu_2 = set_hands('m12', @user_player)

    step_2 = steps(:step_2)
    @user_player.stub(:current_step_number, step_2.number) do
      discarded_tile = @user_player.discard(manzu_2.id, step_2)
      assert_equal manzu_2.tile, discarded_tile
    end
  end

  test '#discard drawn tile creates river marked as tsumogiri' do
    manzu_1, drawn_tile = set_hands('m12', @user_player)

    step_2 = steps(:step_2)
    @user_player.stub(:current_step_number, step_2.number) do
      @user_player.discard(drawn_tile.id, step_2)
      river = @user_player.rivers.first

      assert_equal drawn_tile.tile, river.tile
      assert river.tsumogiri?
    end
  end

  test '#discard sets river.riichi to true when player is riichi' do
    @ai_player.current_state.update!(riichi: true)
    set_hands('m123', @ai_player)
    hand = @ai_player.hands.sample
    @ai_player.discard(hand.id, steps(:step_2))
    assert @ai_player.rivers.last.riichi?
  end

  test '#discard creates player_state' do
    _, _, manzu_3 = set_hands('m123', @user_player)
    before_state_count = @user_player.player_states.count

    step_2 = steps(:step_2)
    @user_player.stub(:current_step_number, step_2.number) do
      @user_player.discard(manzu_3.id, step_2)
      assert_equal before_state_count + 1, @user_player.player_states.count
    end

    step_3 = steps(:step_3)
    @user_player.stub(:current_step_number, step_3.number) do
      manzu_1 = @user_player.hands.first
      @user_player.discard(manzu_1.id, step_3)
      assert_equal before_state_count + 2, @user_player.player_states.count
    end
  end

  test '#steal chi from kamicha removes hands and sets melds' do
    manzu_1, manzu_2, ton = set_hands('m12 z1', @user_player)
    kamicha_player = @ai_player
    discarded_tile = @manzu_3
    step_2 = steps(:step_2)

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:current_step_number, step_2.number) do
          furo_tiles = [ manzu_1.tile, manzu_2.tile ]
          @user_player.steal(kamicha_player, :chi, furo_tiles, discarded_tile, step_2)

          assert_equal [ discarded_tile, manzu_1.tile, manzu_2.tile ], @user_player.melds.map(&:tile)
          assert_equal [ 'kamicha', nil, nil ], @user_player.melds.map(&:from)
          assert_equal [ 'chi', 'chi', 'chi' ], @user_player.melds.map(&:kind)
          assert_equal [ ton.tile ], @user_player.hands.map(&:tile)
        end
      end
    end
  end

  test '#steal pon from shimocha removes hands and sets melds' do
    manzu_1, ton_1, ton_2 = set_hands('m1 z11', @user_player)
    shimocha_player = @ai_player
    discarded_tile = @ton_3
    step_2 = steps(:step_2)

    shimocha_player.stub(:seat_order, 0) do
      @user_player.stub(:seat_order, 3) do
        @user_player.stub(:current_step_number, step_2.number) do
          furo_tiles = [ ton_1.tile, ton_2.tile ]
          @user_player.steal(shimocha_player, :pon, furo_tiles, discarded_tile, step_2)
          assert_equal [ ton_1.tile, ton_2.tile, discarded_tile ], @user_player.melds.map(&:tile)
          assert_equal [ nil, nil, 'shimocha' ], @user_player.melds.map(&:from)
          assert_equal [ 'pon', 'pon', 'pon' ], @user_player.melds.map(&:kind)
          assert_equal [ manzu_1.tile ], @user_player.hands.map(&:tile)
        end
      end
    end
  end

  test '#steal daiminkan from toimen removes hands and sets melds' do
    manzu_1, ton_1, ton_2, ton_3 = set_hands('m1 z111', @user_player)
    toimen_player = @ai_player
    discarded_tile = @ton_3
    step_2 = steps(:step_2)

    toimen_player.stub(:seat_order, 2) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:current_step_number, step_2.number) do
          furo_tiles = [ ton_1.tile, ton_2.tile, ton_3.tile ]
          @user_player.steal(toimen_player, :daiminkan, furo_tiles, discarded_tile, steps(:step_2))
          assert_equal [ ton_1.tile, discarded_tile, ton_2.tile, ton_3.tile ], @user_player.melds.map(&:tile)
          assert_equal [ nil, 'toimen', nil, nil ], @user_player.melds.map(&:from)
          assert_equal [ 'daiminkan', 'daiminkan', 'daiminkan', 'daiminkan' ], @user_player.melds.map(&:kind)
          assert_equal [ manzu_1.tile ], @user_player.hands.map(&:tile)
        end
      end
    end
  end

  test '#steal consecutive furo remove hands and sets melds' do
    manzu_1, manzu_2, ton_1, ton_2, haku = set_hands('m12 z11 z5', @user_player)
    toimen_player = @ai_player
    kamicha_player = players(:tenpai_speeder)
    step_2 = steps(:step_2)
    step_3 = steps(:step_3)

    toimen_player.stub(:seat_order, 2) do
      kamicha_player.stub(:seat_order, 3) do
        @user_player.stub(:seat_order, 0) do
          @user_player.stub(:current_step_number, step_2.number) do
            @user_player.steal(toimen_player, :pon, [ ton_1.tile, ton_2.tile ], @ton_3, step_2)
            assert_equal [ ton_1.tile, @ton_3, ton_2.tile ], @user_player.melds.map(&:tile)
            assert_equal [ nil, 'toimen', nil ], @user_player.melds.map(&:from)
            assert_equal [ 'pon', 'pon', 'pon' ], @user_player.melds.map(&:kind)
            assert_equal [ manzu_1.tile, manzu_2.tile, haku.tile ], @user_player.hands.map(&:tile)
          end

          @user_player.stub(:current_step_number, step_3.number) do
            @user_player.steal(kamicha_player, :chi, [ manzu_1.tile, manzu_2.tile ], @manzu_3, step_3)
            assert_equal [ @manzu_3, manzu_1.tile, manzu_2.tile, ton_1.tile, @ton_3, ton_2.tile ], @user_player.melds.map(&:tile)
            assert_equal [ 'kamicha', nil, nil, nil, 'toimen', nil ], @user_player.melds.map(&:from)
            assert_equal [ 'chi', 'chi', 'chi', 'pon', 'pon', 'pon' ], @user_player.melds.map(&:kind)
            assert_equal [ haku.tile ], @user_player.hands.map(&:tile)
          end
        end
      end
    end
  end

  test '#steal creates player_state' do
    manzu_1, manzu_2, ton = set_hands('m12 z1', @user_player)
    kamicha_player = @ai_player
    before_state_count = @user_player.player_states.count
    step_2 = steps(:step_2)

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        @user_player.stub(:current_step_number, step_2.number) do
          @user_player.steal(kamicha_player, :chi, [ manzu_1.tile, manzu_2.tile ], @manzu_3, step_2)
          assert_equal before_state_count + 1, @user_player.player_states.count
        end
      end
    end
  end

  test '#stolen marks only the targeted river as stolen' do
    manzu_1, manzu_2 = set_rivers('m12', @ai_player)
    before_state_count = @ai_player.player_states.count
    assert_not manzu_1.stolen?

    step_2 = steps(:step_2)
    @ai_player.stub(:current_step_number, step_2.number) do
      @ai_player.stolen(manzu_1.tile, step_2)
      river_manzu_1 = @ai_player.current_state.rivers.first
      assert river_manzu_1.stolen?
    end
  end

  test '#stolen creates player_state' do
    manzu_1, _ = set_rivers('m12', @ai_player)
    before_state_count = @ai_player.player_states.count

    step_2 = steps(:step_2)
    @ai_player.stub(:current_step_number, step_2.number) do
      @ai_player.stolen(manzu_1.tile, step_2)
      assert_equal before_state_count + 1, @ai_player.player_states.count
    end
  end

  test '#choose returns riichi_candidates when ai riichi' do
    set_hands('m123456789 p23 s9 z11', @ai_player)
    @ai_player.current_state.update!(riichi: true)
    result = @ai_player.choose
    expected = @ai_player.hands.find { |hand| hand.name == '9索' }.id
    assert_equal expected, result
  end

  test '#ai?' do
    assert_not @user_player.ai?
    assert @ai_player.ai?
  end

  test '#user?' do
    assert_not @ai_player.user?
    assert @user_player.user?
  end

  test '#host?' do
    @game.stub(:host, @user_player) do
      assert @user_player.host?
      assert_not @ai_player.host?
    end
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

  test '#riichi? returns true when player called riichi' do
    assert_not @user_player.riichi?

    step_2 = steps(:step_2)
    @user_player.stub(:current_step_number, step_2.number) do
      @user_player.player_states.create!(step: step_2, riichi: true)
      assert @user_player.riichi?
    end

    step_3 = steps(:step_3)
    @user_player.stub(:current_step_number, step_3.number) do
      @user_player.player_states.create!(step: step_3, riichi: false)
      assert @user_player.riichi?
    end
  end

  test '#can_riichi? returns true when player is tenpai' do
    set_hands('m123456789 p12 s22', @user_player)
    assert @user_player.can_riichi?
  end

  test '#can_riichi? returns false when player called riichi' do
    set_hands('m123456789 p12 s22', @user_player)

    step_2 = steps(:step_2)
    @user_player.stub(:current_step_number, step_2.number) do
      @user_player.player_states.create!(step: step_2, riichi: true)
      assert_not @user_player.can_riichi?
    end

    step_3 = steps(:step_3)
    @user_player.stub(:current_step_number, step_3.number) do
      @user_player.player_states.create!(step: step_3, riichi: false)
      assert_not @user_player.can_riichi?
    end
  end

  test '#can_riichi? returns false when player called furo' do
    set_hands('m456789 p12 s22', @user_player)
    set_melds('m123', @user_player)
    assert_not @user_player.can_riichi?
  end

  test '#can_riichi? returns true when player called ankan' do
    set_hands('m456789 p12 s22', @user_player)
    set_melds('m1111', @user_player)
    assert @user_player.can_riichi?
  end

  test '#find_riichi_candidates returns possible riichi hand when tenpai and non-melds' do
    set_hands('m123456789 p12 s225', @user_player) # s5（5索）切りでリーチ可能な手牌
    candidates = @user_player.find_riichi_candidates
    assert_equal '5索', candidates.first.name
  end

  test '#find_riichi_candidates returns [] when player have melds' do
    set_hands('m456789 p12 s225', @user_player)
    set_melds('m111=', @user_player)
    candidates = @user_player.find_riichi_candidates
    assert_equal [], candidates
  end

  test '#find_riichi_candidates returns possible riichi hand when player have only ankan' do
    set_hands('m456789 p12 s225', @user_player)
    set_melds('m1111', @user_player)
    candidates = @user_player.find_riichi_candidates
    assert_equal '5索', candidates.first.name
  end

  test '#point returns latest_game_record point' do
    ton_1 = Round.create!(game: @game, number: 0)
    ton_1_honba_0 = Honba.create!(round: ton_1, number: 0)
    @user_player.game_records.create!(honba: ton_1_honba_0, point: 1000)
    assert_equal 1000, @user_player.point

    ton_1_honba_1 = Honba.create!(round: ton_1, number: 1)
    @user_player.game_records.create!(honba: ton_1_honba_1, point: 2000)
    assert_equal 2000, @user_player.point

    ton_2 = Round.create!(game: @game, number: 1)
    ton_2_honba_0 = Honba.create!(round: ton_2, number: 0)
    @user_player.game_records.create!(honba: ton_2_honba_0, point: 3000)
    assert_equal 3000, @user_player.point
  end

  test '#add_point adds latest_game_record point' do
    assert_equal 0, @user_player.point

    @user_player.add_point(8000)
    assert_equal 8000, @user_player.point

    @user_player.add_point(1300)
    assert_equal 9300, @user_player.point
  end

  test '#score returns latest_game_record score' do
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

  test '#wind_number and wind_name and #wind_code' do
    @user_player.stub(:host_seat_number, 0) do
      @user_player.seat_order = 0
      assert_equal 0, @user_player.wind_number
      assert_equal '東', @user_player.wind_name
      assert_equal base_tiles(:ton).code, @user_player.wind_code

      @user_player.seat_order = 1
      assert_equal 1, @user_player.wind_number
      assert_equal '南', @user_player.wind_name
      assert_equal base_tiles(:nan).code, @user_player.wind_code

      @user_player.seat_order = 2
      assert_equal 2, @user_player.wind_number
      assert_equal '西', @user_player.wind_name
      assert_equal base_tiles(:sha).code, @user_player.wind_code

      @user_player.seat_order = 3
      assert_equal 3, @user_player.wind_number
      assert_equal '北', @user_player.wind_name
      assert_equal base_tiles(:pei).code, @user_player.wind_code
    end

    @user_player.stub(:host_seat_number, 1) do
      @user_player.seat_order = 0
      assert_equal 3, @user_player.wind_number
      assert_equal '北', @user_player.wind_name
      assert_equal base_tiles(:pei).code, @user_player.wind_code

      @user_player.seat_order = 1
      assert_equal 0, @user_player.wind_number
      assert_equal '東', @user_player.wind_name
      assert_equal base_tiles(:ton).code, @user_player.wind_code

      @user_player.seat_order = 2
      assert_equal 1, @user_player.wind_number
      assert_equal '南', @user_player.wind_name
      assert_equal base_tiles(:nan).code, @user_player.wind_code

      @user_player.seat_order = 3
      assert_equal 2, @user_player.wind_number
      assert_equal '西', @user_player.wind_name
      assert_equal base_tiles(:sha).code, @user_player.wind_code
    end

    @user_player.stub(:host_seat_number, 2) do
      @user_player.seat_order = 0
      assert_equal 2, @user_player.wind_number
      assert_equal '西', @user_player.wind_name
      assert_equal base_tiles(:sha).code, @user_player.wind_code

      @user_player.seat_order = 1
      assert_equal 3, @user_player.wind_number
      assert_equal '北', @user_player.wind_name
      assert_equal base_tiles(:pei).code, @user_player.wind_code

      @user_player.seat_order = 2
      assert_equal 0, @user_player.wind_number
      assert_equal '東', @user_player.wind_name
      assert_equal base_tiles(:ton).code, @user_player.wind_code

      @user_player.seat_order = 3
      assert_equal 1, @user_player.wind_number
      assert_equal '南', @user_player.wind_name
      assert_equal base_tiles(:nan).code, @user_player.wind_code
    end

    @user_player.stub(:host_seat_number, 3) do
      @user_player.seat_order = 0
      assert_equal 1, @user_player.wind_number
      assert_equal '南', @user_player.wind_name
      assert_equal base_tiles(:nan).code, @user_player.wind_code

      @user_player.seat_order = 1
      assert_equal 2, @user_player.wind_number
      assert_equal '西', @user_player.wind_name
      assert_equal base_tiles(:sha).code, @user_player.wind_code

      @user_player.seat_order = 2
      assert_equal 3, @user_player.wind_number
      assert_equal '北', @user_player.wind_name
      assert_equal base_tiles(:pei).code, @user_player.wind_code

      @user_player.seat_order = 3
      assert_equal 0, @user_player.wind_number
      assert_equal '東', @user_player.wind_name
      assert_equal base_tiles(:ton).code, @user_player.wind_code
    end
  end

  test '#can_furo? returns false when target_player is current_player' do
    set_hands('m12', @user_player)
    result = @user_player.can_furo?(@manzu_3, @user_player)
    assert_not result
  end

  test '#can_furo? returns true when user can pon' do
    set_hands('m11', @user_player)
    result = @user_player.can_furo?(tiles(:third_manzu_1), @ai_player)
    assert result
  end

  test '#can_furo? returns true when target_player is kamicha' do
    set_hands('m12', @user_player)
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        result = @user_player.can_furo?(@manzu_3, kamicha_player)
        assert result
      end
    end
  end

  test '#can_furo? returns false when target_player is shimocha' do
    set_hands('m12', @user_player)
    shimocha_player = @ai_player

    shimocha_player.stub(:seat_order, 1) do
      @user_player.stub(:seat_order, 0) do
        result = @user_player.can_furo?(@manzu_3, shimocha_player)
        assert_not result
      end
    end
  end

  test '#can_furo? returns false when target_player is toimen' do
    set_hands('m12', @user_player)
    toimen_player = @ai_player

    toimen_player.stub(:seat_order, 2) do
      @user_player.stub(:seat_order, 0) do
        result = @user_player.can_furo?(@manzu_3, toimen_player)
        assert_not result
      end
    end
  end

  test '#can_furo? returns false when user can not pon and chi' do
    set_hands('m15', @user_player)
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        result = @user_player.can_furo?(@manzu_3, kamicha_player)
        assert_not result
      end
    end
  end

  test '#can_furo? returns false when player called riichi' do
    set_hands('m11', @user_player)
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        is_furo = @user_player.can_furo?(tiles(:first_manzu_1), kamicha_player)
        assert is_furo

        @user_player.current_state.update!(riichi: true)
        is_furo = @user_player.can_furo?(tiles(:first_manzu_1), kamicha_player)
        assert_not is_furo
      end
    end
  end

  test 'player can not chi zihai' do
    set_hands('z1256', @user_player)
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        result_1 = @user_player.can_furo?(tiles(:first_sha), kamicha_player)
        assert_not result_1

        result_2 = @user_player.can_furo?(tiles(:first_chun), kamicha_player)
        assert_not result_2
      end
    end
  end

  test '#find_furo_candidates only pon' do
    manzu_1_a, manzu_1_b = set_hands('m11', @user_player)
    furo_candidates = @user_player.find_furo_candidates(tiles(:third_manzu_1), @ai_player)
    assert_equal [ manzu_1_a, manzu_1_b ], furo_candidates[:pon]
    assert_nil furo_candidates[:chi]
    assert_nil furo_candidates[:kan]
  end

  test '#find_furo_candidates only kan' do
    manzu_1_a, manzu_1_b, manzu_1_c = set_hands('m111', @user_player)
    furo_candidates = @user_player.find_furo_candidates(@manzu_1, @ai_player)
    assert_equal [ manzu_1_a, manzu_1_b ], furo_candidates[:pon]
    assert_nil furo_candidates[:chi]
    assert_equal [ manzu_1_a, manzu_1_b, manzu_1_c ], furo_candidates[:kan]
  end

  test '#find_furo_candidates only chi' do
    manzu_1, manzu_2, manzu_4, manzu_5, manzu_6, manzu_8, manzu_9 = set_hands('m1245689', @user_player)
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        furo_candidates = @user_player.find_furo_candidates(@manzu_3, kamicha_player)
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

  test '#find_furo_candidates pon_and_chi_candidates' do
    manzu_1_a, _, manzu_2_a, _, manzu_3_a, manzu_3_b, manzu_4_a, _, manzu_5_a, _ = set_hands('m1122334455', @user_player)
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        furo_candidates = @user_player.find_furo_candidates(tiles(:third_manzu_3), kamicha_player)
        assert_equal [ manzu_3_a, manzu_3_b ], furo_candidates[:pon]
        assert_equal [ [ manzu_1_a, manzu_2_a ], [ manzu_2_a, manzu_4_a ], [ manzu_4_a, manzu_5_a ] ], furo_candidates[:chi]
        assert_nil furo_candidates[:kan]
      end
    end
  end

  test '#find_furo_candidates nothing' do
    manzu_1, manzu_5, manzu_9 = set_hands('m159', @user_player)
    furo_candidates = @user_player.find_furo_candidates(tiles(:second_manzu_1), @ai_player)
    assert_equal({}, furo_candidates)
  end

  test '#can_tsumo? returns true：メンゼン聴牌の場合' do
    hands = set_hands('m111 p222 s333 z444 m99', players(:ryo))

    @user_player.stub(:hands, hands) do
      result = @user_player.can_tsumo?
      assert result
    end
  end

  test '#can_tsumo? returns false：ノーテンの場合' do
    hands = set_hands('m123456789 p19 s19', players(:ryo))

    @user_player.stub(:hands, hands) do
      result = @user_player.can_tsumo?
      assert_not result
    end
  end

  test '#can_tsumo? returns false：役無しの形式聴牌 + 状況役が鳴い場合' do
    hands = set_hands('m123 p222 s333 m99', players(:ryo))
    melds = set_melds('m888-', players(:ryo))

    @user_player.stub(:hands, hands) do
      @user_player.stub(:melds, melds) do
        result = @user_player.can_tsumo?
        assert_not result
      end
    end
  end

  test '#can_tsumo? returns true：役無し聴牌 + 状況役（立直）がある場合' do
    hands = set_hands('m123 p222 s333 m99', players(:ryo))
    melds = set_melds('m888-', players(:ryo))

    @user_player.stub(:hands, hands) do
      @user_player.stub(:melds, melds) do
        @user_player.stub(:riichi?, true) do
          result = @user_player.can_tsumo?
          assert result
        end
      end
    end
  end

  test '#can_tsumo? returns true：役無し聴牌 + 状況役（海底摸月）がある場合' do
    hands = set_hands('m123 p222 s333 m99', players(:ryo))
    melds = set_melds('m888-', players(:ryo))

    @user_player.stub(:hands, hands) do
      @user_player.stub(:melds, melds) do
        @user_player.stub(:haitei_tsumo?, true) do
          result = @user_player.can_tsumo?
          assert result
        end
      end
    end
  end

  test '#can_tsumo? returns true：役無し聴牌 + 状況役（嶺上開花）がある場合' do
    hands = set_hands('m123 p222 s333 m99', players(:ryo))
    melds = set_melds('m888-', players(:ryo))

    @user_player.stub(:hands, hands) do
      @user_player.stub(:melds, melds) do
        @user_player.stub(:rinshan_tsumo?, true) do
          result = @user_player.can_tsumo?
          assert result
        end
      end
    end
  end

  test '#can_ron? returns true：役ありメンゼン聴牌の場合' do
    hands = set_hands('m123456789 p23 z33', players(:ryo))

    @user_player.stub(:hands, hands) do
      result = @user_player.can_ron?(tiles(:first_pinzu_1))
      assert result
    end
  end

  test '#can_ron? returns false：役無しメンゼン形式聴牌の場合' do
    hands = set_hands('m111456789 p23 z33', players(:ryo))

    @user_player.stub(:hands, hands) do
      @user_player.stub(:relation_from_current_player, :toimen) do
        result = @user_player.can_ron?(tiles(:first_pinzu_1))
        assert_not result
      end
    end
  end

  test '#can_ron? returns true：副露役あり聴牌の場合' do
    hands = set_hands('p23 z33', players(:ryo))
    melds = set_melds('m123+ m456+ m789+', players(:ryo))

    @user_player.stub(:hands, hands) do
      @user_player.stub(:melds, melds) do
        result = @user_player.can_ron?(tiles(:first_pinzu_1))
        assert result
      end
    end
  end

  test '#can_ron? returns false：副露役無し聴牌の場合' do
    hands = set_hands('p23 z33', players(:ryo))
    melds = set_melds('m111+ m456+ m789+', players(:ryo))

    @user_player.stub(:hands, hands) do
      @user_player.stub(:melds, melds) do
        result = @user_player.can_ron?(tiles(:first_pinzu_1))
        assert_not result
      end
    end
  end

  test '#can_ron? returns true：役無し聴牌 + 状況役（河底撈魚）がある場合' do
    hands = set_hands('p23 z33', players(:ryo))
    melds = set_melds('m111+ m456+ m789+', players(:ryo))

    @user_player.stub(:hands, hands) do
      @user_player.stub(:melds, melds) do
        @user_player.stub(:houtei_ron?, true) do
          result = @user_player.can_ron?(tiles(:first_pinzu_1))
          assert result
        end
      end
    end
  end

  test '#can_ron? returns true：役無し聴牌 + 状況役（搶槓）がある場合' do
    hands = set_hands('p23 z33', players(:ryo))
    melds = set_melds('m111+ m456+ m789+', players(:ryo))

    @user_player.stub(:hands, hands) do
      @user_player.stub(:melds, melds) do
        @user_player.stub(:chankan?, true) do
          result = @user_player.can_ron?(tiles(:first_pinzu_1))
          assert result
        end
      end
    end
  end

  test '#score_statements：4飜40符（ダブル立直、一発、門前清自摸和）' do
    player = @game.current_player
    set_hands('m123789 p111456 s1', player)
    set_rivers('z1', player)
    player.current_state.update!(riichi: true)

    assign_draw_tile('s1', @game)
    @game.draw_for_current_player

    score_statements = player.score_statements
    assert_equal 40, score_statements[:fu_total]
    assert_equal 4,  score_statements[:han_total]
    assert_equal [
      { name: 'ダブル立直',  han: 2 },
      { name: '一発',       han: 1 },
      { name: '門前清自摸和', han: 1 }
    ], score_statements[:yaku_list]
  end

  test '#score_statements：13飜20符（天和）' do
    host = @game.host
    set_hands('m123456789 p55 s234', host)

    score_statements = host.score_statements
    assert_equal 20, score_statements[:fu_total]
    assert_equal 13,  score_statements[:han_total]
    assert_equal [
      { name: '天和', han: 13 }
    ], score_statements[:yaku_list]
  end

  test '#score_statements：13飜20符（地和）' do
    child = @game.players.find_by!(seat_order: 1)
    set_hands('m123456789 p55 s234', child)
    set_rivers('z1', @game.host)

    @game.stub(:current_player, child) do
      score_statements = child.score_statements
      assert_equal 20, score_statements[:fu_total]
      assert_equal 13,  score_statements[:han_total]
      assert_equal [
        { name: '地和', han: 13 }
      ], score_statements[:yaku_list]
    end
  end

  test '#score_statements：2飜30符（海底摸月、門前清自摸和）' do
    set_hands('m123789 p222 s234 z11', @user_player)
    set_rivers('z1', @user_player)
    @game.latest_honba.update!(draw_count: 122)

    score_statements = @user_player.score_statements
    assert_equal 30, score_statements[:fu_total]
    assert_equal 2,  score_statements[:han_total]
    assert_equal [
      { name: '海底摸月',    han: 1 },
      { name: '門前清自摸和', han: 1 }
    ], score_statements[:yaku_list]
  end

  test '#score_statements：1飜40符（河底撈魚）' do
    set_hands('m123789 p222 s234 z1', @user_player)
    @game.latest_honba.update!(draw_count: 122)
    ton = tiles(:first_ton)

    @user_player.stub(:relation_from_current_player, :toimen) do
      score_statements = @user_player.score_statements(tile: ton)
      assert_equal 40, score_statements[:fu_total]
      assert_equal 1,  score_statements[:han_total]
      assert_equal [
        { name: '河底撈魚', han: 1 }
      ], score_statements[:yaku_list]
    end
  end

  test '#score_statements：1飜40符（嶺上開花）' do
    set_hands('m123789 s234 z11', @user_player, rinshan: true)
    set_melds('p2222=', @user_player)
    set_rivers('z1', @user_player)

    score_statements = @user_player.score_statements
    assert_equal 40, score_statements[:fu_total]
    assert_equal 1,  score_statements[:han_total]
    assert_equal [
      { name: '嶺上開花', han: 1 }
    ], score_statements[:yaku_list]
  end

  test '#score_statements：1飜40符（槍槓）' do
    set_hands('m123789 p222 s23 z11', @user_player, drawn: false)
    meld = Meld.create!(tile: tiles(:fourth_souzu_1), kind: 'kakan', player_state: @ai_player.current_state, from: :self, position: 3)

    @user_player.stub(:relation_from_current_player, :toimen) do
      score_statements = @user_player.score_statements(tile: meld)
      assert_equal 40, score_statements[:fu_total]
      assert_equal 1,  score_statements[:han_total]
      assert_equal [
        { name: '槍槓', han: 1 }
      ], score_statements[:yaku_list]
    end
  end
end
