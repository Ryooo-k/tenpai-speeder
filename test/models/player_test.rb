# frozen_string_literal: true

require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  include GameTestHelper

  def setup
    @user_player = players(:ryo)
    @ai_player = players(:ai_1)
    @user = users(:ryo)
    @game = games(:tonnan)
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
    player = Player.new(ai: ais('v0.1'), game: @game, seat_order: 0)
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

    player = Player.new(user: @user, ai: ais('v0.1'), game: @game, seat_order: 0)
    assert player.invalid?
    assert_includes player.errors[:base], 'UserとAIの両方を同時に指定することはできません'
  end

  test 'players sort by seat_order' do
    player_1 = @game.players.find_by(seat_order: 0)
    player_2 = @game.players.find_by(seat_order: 1)
    player_3 = @game.players.find_by(seat_order: 2)
    player_4 = @game.players.find_by(seat_order: 3)
    assert_equal [ player_1, player_2, player_3, player_4 ], @game.players
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

  test '#rivers_with_rotation rotates riichi tile and first non-stolen tile after stolen riichi' do
    player = @user_player
    player.current_state.rivers.delete_all
    set_hands('m12345', player)

    # リーチ宣言打牌
    step = @game.latest_honba.steps.create!(number: @game.current_step_number + 1)
    player.game.update!(current_step_number: step.number)
    player.current_state.update!(riichi: true)
    riichi_and_stolen_hand = player.hands.first
    player.discard(riichi_and_stolen_hand.id, step)

    # リーチ宣言牌が鳴かれる
    steal_step = @game.latest_honba.steps.create!(number: step.number + 1)
    player.game.update!(current_step_number: steal_step.number)
    player.stolen(riichi_and_stolen_hand.tile.id, steal_step)

    # その後の非stolen捨て牌（横向き）
    next_step = @game.latest_honba.steps.create!(number: steal_step.number + 1)
    player.game.update!(current_step_number: next_step.number)
    rotated_hand = player.hands.first
    player.discard(rotated_hand.id, next_step)

    # ２つ目の非stolen捨て牌（縦向き）
    next_next_step = @game.latest_honba.steps.create!(number: steal_step.number + 1)
    player.game.update!(current_step_number: next_next_step.number)
    discard_hand = player.hands.first
    player.discard(discard_hand.id, next_next_step)

    riichi_entry = player.rivers_with_rotation.find { |river, _| river.tile.id == riichi_and_stolen_hand.tile.id }
    assert_not riichi_entry, 'リーチ宣言牌は鳴かれているため、河に存在しないこと'

    rotated_entry = player.rivers_with_rotation.find { |river, _| river.tile.id == rotated_hand.tile.id && !river.stolen }
    assert rotated_entry, 'リーチ宣言後の最初の非stolen捨て牌が河に存在すること'
    assert rotated_entry[1], 'リーチ宣言牌が鳴かれた場合、その次の非stolen捨て牌が横向きであること'

    normal_entry = player.rivers_with_rotation.find { |river, _| river.tile.id == discard_hand.tile.id && !river.stolen }
    assert normal_entry, 'リーチ宣言後の2つ目の非stolen捨て牌が河に存在すること'
    assert_not normal_entry[1], 'リーチ宣言後の2つ目の非stolen捨て牌が横向きでないこと'
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

  test '#current_state returns state of current_step_number' do
    @user_player.player_states.delete_all

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
    current_hand_tiles = @user_player.player_states.last.hands.all.map(&:tile)
    assert_equal [ @manzu_2 ], current_hand_tiles
    assert_equal state_count, @user_player.player_states.count

    @user_player.receive(@manzu_1)
    current_hand_tiles = @user_player.player_states.last.hands.all.map(&:tile)
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
          furo_tiles = [ manzu_1.id, manzu_2.id ]
          @user_player.steal(kamicha_player, :chi, furo_tiles, discarded_tile.id, step_2)

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
          furo_ids = [ ton_1.id, ton_2.id ]
          @user_player.steal(shimocha_player, :pon, furo_ids, discarded_tile.id, step_2)
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
          furo_ids = [ ton_1.id, ton_2.id, ton_3.id ]
          @user_player.steal(toimen_player, :daiminkan, furo_ids, discarded_tile.id, steps(:step_2))

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
    toimen_player = players(:ai_1)
    kamicha_player = players(:ai_2)
    step_2 = steps(:step_2)
    step_3 = steps(:step_3)

    toimen_player.stub(:seat_order, 2) do
      kamicha_player.stub(:seat_order, 3) do
        @user_player.stub(:seat_order, 0) do
          @user_player.stub(:current_step_number, step_2.number) do
            furo_ids = [ ton_1.id, ton_2.id ]
            @user_player.steal(toimen_player, :pon, furo_ids, @ton_3.id, step_2)

            assert_equal [ ton_1.tile, @ton_3, ton_2.tile ], @user_player.melds.map(&:tile)
            assert_equal [ nil, 'toimen', nil ], @user_player.melds.map(&:from)
            assert_equal [ 'pon', 'pon', 'pon' ], @user_player.melds.map(&:kind)
            assert_equal [ manzu_1.tile, manzu_2.tile, haku.tile ], @user_player.hands.map(&:tile)
          end

          @user_player.stub(:current_step_number, step_3.number) do
            manzu_1 = @user_player.hands.first
            manzu_2 = @user_player.hands.second
            furo_ids = [ manzu_1.id, manzu_2.id ]
            @user_player.steal(kamicha_player, :chi, furo_ids, @manzu_3.id, step_3)

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
          @user_player.steal(kamicha_player, :chi, [ manzu_1.id, manzu_2.id ], @manzu_3.id, step_2)
          assert_equal before_state_count + 1, @user_player.player_states.count
        end
      end
    end
  end

  test '#stolen marks only the targeted river as stolen' do
    manzu_1, manzu_2 = set_rivers('m12', @ai_player)
    assert_not manzu_1.stolen?

    step_2 = steps(:step_2)
    @ai_player.stub(:current_step_number, step_2.number) do
      @ai_player.stolen(manzu_1.tile.id, step_2)
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

  test '#kan creates new state and ankan meld with given hands' do
    player = @game.current_player
    kan_hands = set_hands('m1111 p234 s789 z1234', player)
    kan_ids = kan_hands.select { |h| h.name == '1萬' }.map(&:id)

    before_state_count = player.player_states.count
    before_hand_count = player.hands.count

    player.kan(:ankan, kan_ids, steps(:step_2))

    assert_equal before_state_count + 1, player.player_states.count
    assert_equal before_hand_count - 4, player.hands.count
    assert_equal 4, player.melds.size
    assert player.melds.all? { |meld| meld.kind == 'ankan' }
    assert player.melds.all? { |meld| meld.name == '1萬' }
  end

  test '#kan converts pon to kakan and consumes one hand tile' do
    player = @game.current_player
    player.current_state.melds.delete_all
    set_melds('m111=', player)
    set_hands('m1 p234 s789 z1234', player)
    kakan_candidate = player.ankan_and_kakan_candidates[:kakan].first
    kan_ids = kakan_candidate.grep(Hand).map(&:id)

    before_state_count = player.player_states.count
    before_hand_count = player.hands.count

    player.kan(:kakan, kan_ids, steps(:step_2))

    assert_equal before_state_count + 1, player.player_states.count
    assert_equal before_hand_count - 1, player.hands.count
    assert_equal 4, player.melds.size
    assert player.melds.select { |meld| meld.position != Player::KAKAN_POSITION }.all? { |meld| meld.kind == 'pon' }
    assert player.melds.select { |meld| meld.position == Player::KAKAN_POSITION }.all? { |meld| meld.kind == 'kakan' }
    assert_equal 1, player.melds.count { |meld| meld.position == Player::KAKAN_POSITION }
    assert player.melds.all? { |meld| meld.name == '1萬' }
  end

  test '#ai_version' do
    version_number = @ai_player.ai.version
    assert_equal "v#{version_number}", @ai_player.ai_version
  end

  test '#choose returns inferred tile' do
    hands = set_hands('m123456789 z12345', @ai_player)
    result = @ai_player.choose
    hand_index = MahjongAi.infer(@game, @ai_player)

    assert_equal hands.sort_by(&:code)[hand_index], result
  end

  test '#choose returns riichi_candidates when ai is riichi' do
    set_hands('m123456789 p23 s9 z11', @ai_player)
    @ai_player.current_state.update!(riichi: true)
    result = @ai_player.choose
    expected = @ai_player.hands.find { |hand| hand.name == '9索' }

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

  test '#can_riichi? returns true when melds is only ankan' do
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

  test '#latest_game_record returns newest game_record' do
    initial_record = @user_player.latest_game_record
    assert_equal initial_record, @user_player.game_records.first

    ton_1 = Round.create!(game: @game, number: 0)
    ton_1_honba_1 = Honba.create!(round: ton_1, number: 1)
    @user_player.game_records.create!(honba: ton_1_honba_1, point: 900)

    assert_equal ton_1_honba_1, @user_player.latest_game_record.honba
    assert_equal 900, @user_player.latest_game_record.point
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

  test '#can_ankan_or_kakan? returns true when hand has four identical tiles' do
    set_melds([], @user_player)
    set_hands('m1111 p234 s78 z1234', @user_player)
    assert @user_player.can_ankan_or_kakan?
  end

  test '#can_ankan_or_kakan? returns true when pon plus same tile in hand' do
    set_melds('m111=', @user_player)
    set_hands('m1 p234 s78 z1234', @user_player)
    assert @user_player.can_ankan_or_kakan?
  end

  test '#can_ankan_or_kakan? returns false without any four-of-a-kind' do
    set_melds([], @user_player)
    set_hands('m123 p456 s789 z1234', @user_player)
    assert_not @user_player.can_ankan_or_kakan?
  end

  test '#can_ankan_or_kakan? returns false when no four-of-a-kind in hand or melds' do
    set_melds('m123+ m123+ m123+', @user_player)
    set_hands('m123 p12345', @user_player)
    assert_not @user_player.can_ankan_or_kakan?
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

  test '#ankan_and_kakan_candidates returns both when hand has quad and pon+' do
    set_melds('p555=', @user_player) # pon for kakan
    quad = set_hands('m1111 p5 s2345 z1111', @user_player)

    candidates = @user_player.ankan_and_kakan_candidates
    assert_equal 2, candidates[:ankan].size
    assert %w[1萬 1萬 1萬 1萬], candidates[:ankan].first.map(&:name)
    assert %w[東 東 東 東], candidates[:ankan].second.map(&:name)
    assert_equal 1, candidates[:kakan].size
    assert %w[5筒 5筒 5筒 5筒], candidates[:kakan].first.map(&:name)
  end

  test '#ankan_and_kakan_candidates returns only ankan when no pon' do
    set_melds([], @user_player)
    candidates = @user_player.ankan_and_kakan_candidates
    assert_equal [], candidates[:kakan]

    set_hands('m2222 p123 s789 z1234', @user_player)
    candidates = @user_player.ankan_and_kakan_candidates
    assert_equal 1, candidates[:ankan].size
    assert %w[2萬 2萬 2萬 2萬], candidates[:ankan].first.map(&:name)
    assert_equal [], candidates[:kakan]
  end

  test '#ankan_and_kakan_candidates returns only kakan when no quad in hand' do
    set_melds('m333=', @user_player)
    set_hands('m3 p123 s789 z12345', @user_player)
    candidates = @user_player.ankan_and_kakan_candidates

    assert_equal [], candidates[:ankan]
    assert_equal 1, candidates[:kakan].size
    assert %w[3萬 3萬 3萬 3萬], candidates[:kakan].first.map(&:name)
  end

  test '#furo_candidates return {} when current_player is user' do
    set_player_turn(@user_player.game, @user_player)
    assert_equal({}, @user_player.furo_candidates)
  end

  test '#furo_candidates defaults to current player and latest river when args omitted' do
    set_player_turn(@ai_player.game, @ai_player)
    set_rivers('z1', @ai_player)
    ton_a, ton_b = set_hands('z11', @user_player)

    furo_candidates = @user_player.furo_candidates
    assert_equal [ :pon ], furo_candidates.keys
    assert_equal [ ton_a, ton_b ], furo_candidates[:pon]
  end

  test '#furo_candidates only pon' do
    manzu_1_a, manzu_1_b = set_hands('m11', @user_player)
    target_tile = tiles(:third_manzu_1)
    furo_candidates = @user_player.furo_candidates(target_player: @ai_player, target_tile:)

    assert_equal [ manzu_1_a, manzu_1_b ], furo_candidates[:pon]
    assert_nil furo_candidates[:chi]
    assert_nil furo_candidates[:daiminkan]
  end

  test '#furo_candidates only daiminkan' do
    manzu_1_a, manzu_1_b, manzu_1_c = set_hands('m111', @user_player)
    furo_candidates = @user_player.furo_candidates(target_player: @ai_player, target_tile: @manzu_1)

    assert_equal [ manzu_1_a, manzu_1_b ], furo_candidates[:pon]
    assert_nil furo_candidates[:chi]
    assert_equal [ manzu_1_a, manzu_1_b, manzu_1_c ], furo_candidates[:daiminkan]
  end

  test '#furo_candidates only chi' do
    manzu_1, manzu_2, manzu_4, manzu_5, manzu_6, manzu_8, manzu_9 = set_hands('m1245689', @user_player)
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        furo_candidates = @user_player.furo_candidates(target_tile: @manzu_3, target_player: kamicha_player)
        assert_nil furo_candidates[:pon]
        assert_equal [ [ manzu_1, manzu_2 ], [ manzu_2, manzu_4 ], [ manzu_4, manzu_5 ] ], furo_candidates[:chi]
        assert_nil furo_candidates[:daiminkan]

        furo_candidates = @user_player.furo_candidates(target_tile: tiles(:first_manzu_7), target_player: kamicha_player)
        assert_nil furo_candidates[:pon]
        assert_equal [ [ manzu_5, manzu_6 ], [ manzu_6, manzu_8 ], [ manzu_8, manzu_9 ] ], furo_candidates[:chi]
        assert_nil furo_candidates[:daiminkan]
      end
    end
  end

  test '#furo_candidates pon_and_chi_candidates' do
    manzu_1_a, _, manzu_2_a, _, manzu_3_a, manzu_3_b, manzu_4_a, _, manzu_5_a, _ = set_hands('m1122334455', @user_player)
    kamicha_player = @ai_player

    kamicha_player.stub(:seat_order, 3) do
      @user_player.stub(:seat_order, 0) do
        furo_candidates = @user_player.furo_candidates(target_tile: tiles(:third_manzu_3), target_player: kamicha_player)
        assert_equal [ manzu_3_a, manzu_3_b ], furo_candidates[:pon]
        assert_equal [ [ manzu_1_a, manzu_2_a ], [ manzu_2_a, manzu_4_a ], [ manzu_4_a, manzu_5_a ] ], furo_candidates[:chi]
        assert_nil furo_candidates[:daiminkan]
      end
    end
  end

  test '#furo_candidates nothing' do
    manzu_1, manzu_5, manzu_9 = set_hands('m159', @user_player)
    furo_candidates = @user_player.furo_candidates(target_tile: tiles(:second_manzu_1), target_player: @ai_player)
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

    set_draw_tile('s1', @game)
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

  test '#final_score returns combined score and point' do
    assert_equal @user_player.score + @user_player.point, @user_player.final_score

    @user_player.game_records.last.update!(score: 30_000, point: 1_200)
    assert_equal 31_200, @user_player.final_score
  end

  test '#tenpai? returns true when shanten == 0' do
    set_hands('m123456789 p123 s1', @user_player)
    assert @user_player.tenpai?
  end

  test '#tenpai? returns false when shanten > 0' do
    set_hands('m123456789 p159 s1', @user_player)
    assert_not @user_player.tenpai?
  end

  test '#shanten returns shanten count' do
    set_hands('m123456789 p19 s5 z1', @user_player)
    assert_equal 2, @user_player.shanten
  end

  test '#shanten returns -1 when player is complete' do
    set_hands('m123456789 p123 s55', @user_player)
    assert_equal -1, @user_player.shanten
  end

  test '#shanten_without_drawn calls HandEvaluator with hands excluding drawn tile' do
    # 5索（s5）を引いて聴牌、
    # 5索を引く前は１向聴の状態
    set_hands('m123456789 p11 s145', @user_player) # 最後の牌がdrawn

    assert_equal 0, @user_player.shanten
    assert_equal 1, @user_player.shanten_without_drawn
  end

  test '#shanten_decreased? returns true when shanten goes down after draw' do
    set_hands('m123456789 p11 s145', @user_player)
    assert @user_player.shanten_decreased?
  end

  test '#shanten_decreased? returns false when shanten stays or increases' do
    set_hands('m123456789 p11 s149', @user_player)
    assert_not @user_player.shanten_decreased?
  end

  test '#outs(normal)' do
    set_hands('m223344 p55667 s22', @user_player)
    outs = @user_player.outs
    assert_equal [
      '4筒', '4筒', '4筒', '4筒',
      '7筒', '7筒', '7筒'
    ], outs[:normal].map(&:name)
  end

  test '#outs(chiitoitsu)' do
    set_hands('m223344 p55667 s22', @user_player)
    outs = @user_player.outs
    assert_equal [ '7筒', '7筒', '7筒' ], outs[:chiitoitsu].map(&:name)
  end

  test '#outs(kokushi)' do
    set_hands('m223344 p55667 s22', @user_player)
    outs = @user_player.outs

    assert_equal [
      '1萬', '1萬', '1萬', '1萬',
      '9萬', '9萬', '9萬', '9萬',
      '1筒', '1筒', '1筒', '1筒',
      '9筒', '9筒', '9筒', '9筒',
      '1索', '1索', '1索', '1索',
      '9索', '9索', '9索', '9索',
      '東', '東', '東', '東',
      '南', '南', '南', '南',
      '西', '西', '西', '西',
      '北', '北', '北', '北',
      '白', '白', '白', '白',
      '發', '發', '發', '發',
      '中', '中', '中', '中' ], outs[:kokushi].map(&:name)
  end

  test '#hands_to_lower_shanten_and_normal_outs' do
    set_hands('m123456789 p159 s11', @user_player)
    hands_to_lower_shanten_and_normal_outs = @user_player.hands_to_lower_shanten_and_normal_outs

    # 1筒、5筒、9筒を捨てれば向聴数が減る
    assert_equal [ '1筒', '5筒', '9筒' ], hands_to_lower_shanten_and_normal_outs.keys.map(&:name)

    # 1筒を捨てた時の有効牌
    pinzu_1 = hands_to_lower_shanten_and_normal_outs.keys[0]
    assert_equal [
      '3筒', '3筒', '3筒', '3筒',
      '4筒', '4筒', '4筒', '4筒',
      '5筒', '5筒', '5筒',
      '6筒', '6筒', '6筒', '6筒',
      '7筒', '7筒', '7筒', '7筒',
      '8筒', '8筒', '8筒', '8筒',
      '9筒', '9筒', '9筒',
      '1索', '1索', '1索'
    ], hands_to_lower_shanten_and_normal_outs[pinzu_1].map(&:name)

    # 5筒を捨てた時の有効牌
    pinzu_5 = hands_to_lower_shanten_and_normal_outs.keys[1]
    assert_equal [
      '1筒', '1筒', '1筒',
      '2筒', '2筒', '2筒', '2筒',
      '3筒', '3筒', '3筒', '3筒',
      '7筒', '7筒', '7筒', '7筒',
      '8筒', '8筒', '8筒', '8筒',
      '9筒', '9筒', '9筒',
      '1索', '1索', '1索'
    ], hands_to_lower_shanten_and_normal_outs[pinzu_5].map(&:name)

    # 9筒を捨てた時の有効牌
    pinzu_9 = hands_to_lower_shanten_and_normal_outs.keys[2]
    assert_equal [
      '1筒', '1筒', '1筒',
      '2筒', '2筒', '2筒', '2筒',
      '3筒', '3筒', '3筒', '3筒',
      '4筒', '4筒', '4筒', '4筒',
      '5筒', '5筒', '5筒',
      '6筒', '6筒', '6筒', '6筒',
      '7筒', '7筒', '7筒', '7筒',
      '1索', '1索', '1索'
    ], hands_to_lower_shanten_and_normal_outs[pinzu_9].map(&:name)
  end

  test '#hands_to_same_shanten_outs returns outs for each unique hand without the discard tile' do
    set_hands('m19 z111222333444', @user_player,)
    hands_to_same_shanten_outs = @user_player.hands_to_same_shanten_outs

    # 向聴数が変わらない打牌候補
    assert_equal [ '東', '南', '西', '北' ], hands_to_same_shanten_outs.keys.map(&:name)

    # 東を捨てた時の有効牌
    ton = hands_to_same_shanten_outs.keys[0]
    assert_equal [
      '1萬', '1萬', '1萬',
      '2萬', '2萬', '2萬', '2萬',
      '3萬', '3萬', '3萬', '3萬',
      '7萬', '7萬', '7萬', '7萬',
      '8萬', '8萬', '8萬', '8萬',
      '9萬', '9萬', '9萬',
      '東', '東', '東'
    ], hands_to_same_shanten_outs[ton].map(&:name)

    # 南を捨てた時の有効牌
    nan = hands_to_same_shanten_outs.keys[1]
    assert_equal [
      '1萬', '1萬', '1萬',
      '2萬', '2萬', '2萬', '2萬',
      '3萬', '3萬', '3萬', '3萬',
      '7萬', '7萬', '7萬', '7萬',
      '8萬', '8萬', '8萬', '8萬',
      '9萬', '9萬', '9萬',
      '南', '南', '南'
    ], hands_to_same_shanten_outs[nan].map(&:name)

    # 西を捨てた時の有効牌
    sha = hands_to_same_shanten_outs.keys[2]
    assert_equal [
      '1萬', '1萬', '1萬',
      '2萬', '2萬', '2萬', '2萬',
      '3萬', '3萬', '3萬', '3萬',
      '7萬', '7萬', '7萬', '7萬',
      '8萬', '8萬', '8萬', '8萬',
      '9萬', '9萬', '9萬',
      '西', '西', '西'
    ], hands_to_same_shanten_outs[sha].map(&:name)

    # 北を捨てた時の有効牌
    pei = hands_to_same_shanten_outs.keys[3]
    assert_equal [
      '1萬', '1萬', '1萬',
      '2萬', '2萬', '2萬', '2萬',
      '3萬', '3萬', '3萬', '3萬',
      '7萬', '7萬', '7萬', '7萬',
      '8萬', '8萬', '8萬', '8萬',
      '9萬', '9萬', '9萬',
      '北', '北', '北'
    ], hands_to_same_shanten_outs[pei].map(&:name)
  end

  test '#yaku_map_by_waiting_wining_tile returns score statements for each waiting tile when waiting_wining_tile' do
    set_player_turn(@game, @ai_player)
    set_hands('m123456 p23 s12355', @user_player, drawn: false)
    wining_tile_a = tiles(:first_pinzu_1).base_tile
    wining_tile_b = tiles(:first_pinzu_4).base_tile
    yaku_map_a = [ { name: '平和', han: 1 }, { name: '三色同順', han: 2 } ]
    yaku_map_b = [ { name: '平和', han: 1 } ]

    result = @user_player.yaku_map_by_waiting_wining_tile

    assert_equal yaku_map_a, result[wining_tile_a]
    assert_equal yaku_map_b, result[wining_tile_b]
  end

  test '#yaku_map_by_waiting_wining_tile returns empty hash when not tenpai' do
    @user_player.stub(:tenpai?, false) do
      assert_equal({}, @user_player.yaku_map_by_waiting_wining_tile)
    end
  end

  test '#waiting_wining_tile? returns true when shanten 0 on waiting turn' do
    hands = set_hands('m123456789 p123 s1', @user_player, drawn: false) # 13枚で自摸前の手番

    assert @user_player.waiting_wining_tile?
    assert_equal 13, hands.count
  end

  test '#waiting_wining_tile? returns false when not waiting turn even if shanten 0' do
    set_hands('m123456789 p123 s11', @user_player) # 14枚で自摸後などの手番外

    assert_not @user_player.waiting_wining_tile?
  end

  test '#waiting_wining_tile? returns false when shanten not 0' do
    set_hands('m123456789 p19 s19', @user_player)

    assert_not @user_player.waiting_wining_tile?
  end

  test 'riichi river stays sideways even after being stolen' do
    discarder = @game.user_player
    set_hands('m12345', discarder)
    discarder.current_state.update!(riichi: true)

    step_after_discard = @game.latest_honba.steps.create!(number: @game.current_step_number + 1)
    @game.update!(current_step_number: step_after_discard.number)
    riichi_hand = discarder.hands.first
    discarder.discard(riichi_hand.id, step_after_discard)

    riichi_river = discarder.current_state.rivers.first
    assert riichi_river.riichi?

    steal_step = @game.latest_honba.steps.create!(number: step_after_discard.number + 1)
    @game.update!(current_step_number: steal_step.number)
    discarder.stolen(riichi_hand.tile.id, steal_step)

    riichi_and_stolen_river = discarder.current_state.rivers.first
    assert riichi_and_stolen_river.riichi?
    assert riichi_and_stolen_river.stolen?
  end
end
