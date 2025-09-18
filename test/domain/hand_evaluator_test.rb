# frozen_string_literal: true

require 'test_helper'
require 'helpers/game_test_helper'
require 'debug'
class HandEvaluatorTest < ActiveSupport::TestCase
  include GameTestHelper

  def setup
    @privates = HandEvaluator.private_methods(false)
    HandEvaluator.public_class_method(*@privates)

    @empty_melds = []
    @round_wind = 0  # 東場
    @player_wind = 0 # 東
  end

  def teardown
    HandEvaluator.private_class_method(*@privates)
  end

  def build_situational_yaku_list(tenhou: false, chiihou: false, riichi: 0, ippatsu: false, haitei: 0, rinshan: false, chankan: false)
    { tenhou:, chiihou:, riichi:, ippatsu:, haitei:, rinshan:, chankan: }
  end

  test '#can_tsumo? returns true：メンゼン4面子1雀頭の場合' do
    hands = create_hands('m111 p234567 s23455', player: player_states(:ryo))
    situational_yaku_list = build_situational_yaku_list
    result = HandEvaluator.can_tsumo?(hands, @empty_melds, @round_wind, @player_wind, situational_yaku_list)
    assert result
  end

  test '#can_tsumo? returns true：役あり1副露の4面子1雀頭の場合' do
    hands = create_hands('z22 m123 p456 s999', player: player_states(:ryo))
    melds = create_melds('z111=', player: player_states(:ryo))
    situational_yaku_list = build_situational_yaku_list
    result = HandEvaluator.can_tsumo?(hands, melds, @round_wind, @player_wind, situational_yaku_list)
    assert result
  end

  test '#can_tsumo? returns false：メンゼン4面子 雀頭無しの場合' do
    hands = create_hands('m123 p456 s999 z12345', player: player_states(:ryo))
    situational_yaku_list = build_situational_yaku_list
    result = HandEvaluator.can_tsumo?(hands, @empty_melds, @round_wind, @player_wind, situational_yaku_list)
    assert_not result
  end

  test '#get_score_summaries：天和 → 13飜' do
    hands = create_hands('m111 p234567 s23455', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_1)
    situational_yaku_list = build_situational_yaku_list(tenhou: true)
    relation = :self

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '天和', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#get_score_summaries：地和 → 13飜' do
    hands = create_hands('m111 p234567 s23455', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_1)
    situational_yaku_list = build_situational_yaku_list(chiihou: true)
    relation = :shimocha

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '地和', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#get_score_summaries：立直(1) 一発 海底摸月 門前清自摸和 → 合計4飜' do
    hands = create_hands('m111 p234567 s23455', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_1)
    situational_yaku_list = build_situational_yaku_list(ippatsu: true, riichi: 1, haitei: 1)
    relation = :self

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '立直', han: 1 }, { name: '一発', han: 1 }, { name: '海底摸月', han: 1 }, { name: '門前清自摸和', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 4, result[:han_total]
  end

  test '#get_score_summaries：ダブル立直(2) 河底撈魚 槍槓 → 合計4飜' do
    hands = create_hands('m111 p234567 s23455', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_1)
    situational_yaku_list = build_situational_yaku_list(riichi: 2, haitei: 2, chankan: true)
    relation = :toimen

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: 'ダブル立直', han: 2 }, { name: '河底撈魚', han: 1 }, { name: '槍槓', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 4, result[:han_total]
  end

  test '#get_score_summaries：門前清自摸和 嶺上開花 → 合計2飜' do
    hands = create_hands('m111 p234567 s23455', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_1)
    situational_yaku_list = build_situational_yaku_list(rinshan: true)
    relation = :self

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '嶺上開花', han: 1 }, { name: '門前清自摸和', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 2, result[:han_total]
  end

  test '#get_score_summaries：場風 東 → 合計1飜' do
    # z1：東
    hands = create_hands('p234567 s23455', player: player_states(:ryo))
    melds = create_melds('z111=', player: player_states(:ryo))
    agari_tile = tiles(:first_pinzu_2)
    relation = :self
    situational_yaku_list = build_situational_yaku_list
    player_wind = 1 # 南

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, player_wind)
    expected = [ { name: '場風 東', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 1, result[:han_total]
  end

  test '#get_score_summaries：自風 南 → 合計1飜' do
    # z2:南
    hands = create_hands('p234567 s23455', player: player_states(:ryo))
    melds = create_melds('z222=', player: player_states(:ryo))
    agari_tile = tiles(:first_pinzu_2)
    relation = :self
    situational_yaku_list = build_situational_yaku_list
    player_wind = 1 # 南

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, player_wind)
    expected = [ { name: '自風 南', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 1, result[:han_total]
  end

  test '#get_score_summaries：翻牌 白 → 合計1飜' do
    # z5:白
    hands = create_hands('p234567 s23455', player: player_states(:ryo))
    melds = create_melds('z555=', player: player_states(:ryo))
    agari_tile = tiles(:first_pinzu_2)
    relation = :self
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '翻牌 白', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 1, result[:han_total]
  end

  test '#get_score_summaries：平和 → 合計1飜' do
    hands = create_hands('m123 p123456 s789 z22', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_souzu_9)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '平和', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 1, result[:han_total]
  end

  test '#get_score_summaries：タンヤオ → 合計1飜' do
    hands = create_hands('m222 p234567 s23455', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_2)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '断幺九', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 1, result[:han_total]
  end

  test '#get_score_summaries：一盃口 → 合計1飜' do
    hands = create_hands('m112233 p234567 s55', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_2)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '一盃口', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 1, result[:han_total]
  end

  test '#get_score_summaries：三色同順(面前) → 合計2飜' do
    hands = create_hands('m123 p123 s123567 z22', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_2)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '三色同順', han: 2 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 2, result[:han_total]
  end

  test '#get_score_summaries：三色同順(鳴き) → 合計1飜' do
    hands = create_hands('m123 s123567 z22', player: player_states(:ryo), drawn: false)
    melds = create_melds('p123+', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_2)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '三色同順', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 1, result[:han_total]
  end

  test '#get_score_summaries：一気通貫(面前) → 合計2飜' do
    hands = create_hands('m123456789 p234 z22', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_2)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '一気通貫', han: 2 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 2, result[:han_total]
  end

  test '#get_score_summaries：一気通貫(鳴き) → 合計1飜' do
    hands = create_hands('m456789 p234 z22', player: player_states(:ryo), drawn: false)
    melds = create_melds('m123+', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_4)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '一気通貫', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 1, result[:han_total]
  end

  test '#get_score_summaries：混全帯幺九(面前) → 合計2飜' do
    hands = create_hands('m123789 p111999 z22', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_2)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '混全帯幺九', han: 2 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 2, result[:han_total]
  end

  test '#get_score_summaries：混全帯幺九(鳴き) → 合計1飜' do
    hands = create_hands('m789 p111999 z22', player: player_states(:ryo), drawn: false)
    melds = create_melds('m123+', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_9)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '混全帯幺九', han: 1 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 1, result[:han_total]
  end

  test '#get_score_summaries：七対子 → 合計2飜' do
    hands = create_hands('m1133557799 p1199', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_1)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '七対子', han: 2 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 2, result[:han_total]
  end

  test '#get_score_summaries：七対子 混一色 → 合計5飜' do
    hands = create_hands('m1133557799 z1122', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_1)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '七対子', han: 2 }, { name: '混一色', han: 3 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 5, result[:han_total]
  end

  test '#get_score_summaries：七対子 清一色 → 合計8飜' do
    hands = create_hands('m11223355668899', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_2)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '七対子', han: 2 }, { name: '清一色', han: 6 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 8, result[:han_total]
  end


  test '#get_score_summaries：対々和 → 合計2飜' do
    hands = create_hands('m333 p111222 z22', player: player_states(:ryo), drawn: false)
    melds = create_melds('m111+', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_3)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '対々和', han: 2 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 2, result[:han_total]
  end

  test '#get_score_summaries：三暗刻 → 合計2飜' do
    hands = create_hands('m111333444 z22', player: player_states(:ryo))
    melds = create_melds('p123+', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_1)
    relation = :self
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '三暗刻', han: 2 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 2, result[:han_total]
  end

  test '#get_score_summaries：三槓子 → 合計2飜' do
    hands = create_hands('p123 z22', player: player_states(:ryo))
    melds = create_melds('m1111 m2222= m3333', player: player_states(:ryo))
    agari_tile = tiles(:first_pinzu_1)
    relation = :self
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '三槓子', han: 2 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 2, result[:han_total]
  end

  test '#get_score_summaries：三色同刻 → 合計2飜' do
    hands = create_hands('p123 z22', player: player_states(:ryo))
    melds = create_melds('m222- p222= s222+', player: player_states(:ryo))
    agari_tile = tiles(:first_pinzu_1)
    relation = :self
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '三色同刻', han: 2 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 2, result[:han_total]
  end

  test '#get_score_summaries：混老頭 対々和 → 合計4飜' do
    hands = create_hands('m999 z22233', player: player_states(:ryo))
    melds = create_melds('m111= p111=', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_9)
    relation = :self
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '対々和', han: 2 }, { name: '混老頭', han: 2 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 4, result[:han_total]
  end

  test '#get_score_summaries：混老頭 七対子 → 合計4飜' do
    hands = create_hands('m1199 p1199 s1199 z11', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_1)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '七対子', han: 2 }, { name: '混老頭', han: 2 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 4, result[:han_total]
  end

  test '#get_score_summaries：小三元 → 合計4飜' do
    hands = create_hands('p234 z55566677', player: player_states(:ryo), drawn: false)
    melds = create_melds('m234+', player: player_states(:ryo))
    agari_tile = tiles(:first_chun)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '翻牌 白', han: 1 }, { name: '翻牌 發', han: 1 }, { name: '小三元', han: 2 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 4, result[:han_total]
  end

  test '#get_score_summaries：純全帯幺九 → 合計3飜' do
    hands = create_hands('m111789 p123789 s11', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_1)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '純全帯幺九', han: 3 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 3, result[:han_total]
  end

  test '#get_score_summaries：二盃口' do
    hands = create_hands('m112233 p445566 s11', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_2)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '二盃口', han: 3 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 3, result[:han_total]
  end

  test '#get_score_summaries：清一色 → 合計6飜' do
    hands = create_hands('m11122245678999', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_2)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '清一色', han: 6 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 6, result[:han_total]
  end

  test '#get_score_summaries：国士無双 → 合計13飜' do
    hands = create_hands('m19 p19 s19 z12345677', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_1)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '国士無双', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#get_score_summaries：国士無双十三面 → 合計13飜' do
    hands = create_hands('m119 p19 s19 z1234567', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_1)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '国士無双十三面', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#get_score_summaries：四暗刻単騎 → 合計13飜' do
    hands = create_hands('m111222 p333444 s55', player: player_states(:ryo))
    agari_tile = tiles(:first_souzu_5)
    relation = :self
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '四暗刻単騎', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#get_score_summaries：四暗刻 → 合計13飜' do
    hands = create_hands('m111222 p333444 s55', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_1)
    relation = :self
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '四暗刻', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#get_score_summaries：大三元 → 合計13飜' do
    hands = create_hands('m234 p22 z555666777', player: player_states(:ryo), drawn: false)
    agari_tile = tiles(:first_manzu_2)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '大三元', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#get_score_summaries：大四喜 → 合計13飜' do
    hands = create_hands('m11', player: player_states(:ryo))
    melds = create_melds('z111= z222= z333= z444=', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_1)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '大四喜', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#get_score_summaries：小四喜 → 合計13飜' do
    hands = create_hands('z11', player: player_states(:ryo))
    melds = create_melds('m111= z222= z333= z444=', player: player_states(:ryo))
    agari_tile = tiles(:first_ton)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '小四喜', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#get_score_summaries：字一色 → 合計13飜' do
    hands = create_hands('z66', player: player_states(:ryo))
    melds = create_melds('z222= z333= z444= z555=', player: player_states(:ryo))
    agari_tile = tiles(:first_hatsu)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '小四喜', han: 13 }, { name: '字一色', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 26, result[:han_total]
  end

  test '#get_score_summaries：緑一色 → 合計13飜' do
    hands = create_hands('s223344666888 z66', player: player_states(:ryo))
    agari_tile = tiles(:first_hatsu)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '緑一色', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#get_score_summaries：清老頭 → 合計13飜' do
    hands = create_hands('m111999 p111 s11', player: player_states(:ryo))
    melds = create_melds('p999=', player: player_states(:ryo))
    agari_tile = tiles(:first_souzu_1)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '清老頭', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#get_score_summaries：四槓子 → 合計13飜' do
    hands = create_hands('s11', player: player_states(:ryo))
    melds = create_melds('m1111 p2222= s3333 z4444=', player: player_states(:ryo))
    agari_tile = tiles(:first_souzu_1)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '四槓子', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  test '#calculate_shanten：m111222333 p259 z1（メンゼン通常手ノーテン） の向聴数 → 2' do
    hands = create_hands('m111222333 p259 z1', player: player_states(:ryo))
    result = HandEvaluator.calculate_shanten(hands, @empty_melds)
    assert_equal 2, result
  end

  test '#calculate_shanten：m111222333 p45 z11（メンゼン通常手 聴牌） の向聴数 → 0' do
    hands = create_hands('m111222333 p45 z11', player: player_states(:ryo))
    result = HandEvaluator.calculate_shanten(hands, @empty_melds)
    assert_equal 0, result
  end

  test '#calculate_shanten：m111222333 p259 z1（鳴き通常手ノーテン） の向聴数 → 2' do
    hands = create_hands('m333 p259 z1', player: player_states(:ryo))
    melds = create_melds('m111- m2222-', player: player_states(:ryo))
    result = HandEvaluator.calculate_shanten(hands, melds)
    assert_equal 2, result
  end

  test '#calculate_shanten：m111222333 p45 z11（鳴き通常手 聴牌） の向聴数 → 0' do
    hands = create_hands('m333 p45 z11', player: player_states(:ryo))
    melds = create_melds('m111- m2222-', player: player_states(:ryo))
    result = HandEvaluator.calculate_shanten(hands, melds)
    assert_equal 0, result
  end

  test '#calculate_shanten：m159 p159 s159 z1234（国士無双ノーテン）の向聴数 → 3' do
    hands = create_hands('m159 p159 s159 z1234', player: player_states(:ryo))
    result = HandEvaluator.calculate_shanten(hands, @empty_melds)
    assert_equal 3, result
  end

  test '#calculate_shanten：m19 p19 s19 z1234567（国士無双 聴牌）の向聴数 → 0' do
    hands = create_hands('m19 p19 s19 z1234567', player: player_states(:ryo))
    result = HandEvaluator.calculate_shanten(hands, @empty_melds)
    assert_equal 0, result
  end

  test '#calculate_shanten：m11335577 p19 s19 z1（七対子ノーテン）の向聴数 → 4' do
    hands = create_hands('m1133579 p159 s19 z1', player: player_states(:ryo))
    result = HandEvaluator.calculate_shanten(hands, @empty_melds)
    assert_equal 4, result
  end

  test '#calculate_shanten：m1133577 p1199 s11 z1（七対子 聴牌）の向聴数 → 0' do
    hands = create_hands('m1133577 p1199 s11 z1', player: player_states(:ryo))
    result = HandEvaluator.calculate_shanten(hands, @empty_melds)
    assert_equal 0, result
  end

  test '#get_score_summaries：九蓮宝燈 → 合計13飜' do
    # m11112345678999
    hands = create_hands('m11112345678999', player: player_states(:ryo))
    agari_tile = tiles(:first_manzu_1)
    relation = :toimen
    situational_yaku_list = build_situational_yaku_list

    result = HandEvaluator.get_score_summaries(hands, @empty_melds, agari_tile, relation, situational_yaku_list, @round_wind, @player_wind)
    expected = [ { name: '九蓮宝燈', han: 13 } ]
    assert_equal expected, result[:yaku_list]
    assert_equal 13, result[:han_total]
  end

  # コアとなるprivateメソッドを個別にテストを行う。
  # build_agari_mentsu
  test 'empty counts returns one empty meld list' do
    counts = [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
    result = HandEvaluator.build_agari_mentsu('m', counts, 0)
    assert_equal [ [] ], result
    assert_equal [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], counts
  end

  test 'sequence only: 123' do
    counts = [ 1, 1, 1, 0, 0, 0, 0, 0, 0 ]
    result = HandEvaluator.build_agari_mentsu('m', counts, 0)
    assert_equal [ [ 'm123' ] ], result
  end

  test 'triplet only: 111' do
    counts = [ 3, 0, 0, 0, 0, 0, 0, 0, 0 ]
    result = HandEvaluator.build_agari_mentsu('m', counts, 0)
    assert_equal [ [ 'm111' ] ], result
  end

  test 'returns empty when sum is not a multiple of 3' do
    counts = [ 3, 2, 2, 0, 0, 0, 0, 0, 0 ]
    result = HandEvaluator.build_agari_mentsu('m', counts, 0)
    assert_equal [], result
  end

  test 'i=3: either sequences 456*3 or triplets 444/555/666' do
    counts = [ 0, 0, 0, 3, 3, 3, 0, 0, 0 ]
    result = HandEvaluator.build_agari_mentsu('m', counts, 0)
    assert_equal [ [ 'm456', 'm456', 'm456' ], [ 'm444', 'm555', 'm666' ] ], result
  end

  test 'no sequence on honors (z): 1-2-3 is invalid' do
    counts = [ 1, 1, 1, 0, 0, 0, 0 ]
    result = HandEvaluator.build_agari_mentsu('z', counts, 0)
    assert_equal [], result
  end

  test 'boundary sequence 789' do
    counts = [ 0, 0, 0, 0, 0, 0, 1, 1, 1 ]
    result = HandEvaluator.build_agari_mentsu('s', counts, 0)
    assert_equal [ [ 's789' ] ], result
  end

  # build_agari_mentsu_all
  def zero9 = [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
  def zero7 = [ 0, 0, 0, 0, 0, 0, 0 ]

  test 'empty hand returns one empty meld set' do
    hands = {
      m: zero9.dup,
      p: zero9.dup,
      s: zero9.dup,
      z: zero7.dup
    }
    melds = []

    result = HandEvaluator.build_agari_mentsu_all(hands, melds)
    assert_equal [ [] ], result
  end

  test 'single suit sequence only (m123)' do
    hands = {
      m: [ 1, 1, 1, 0, 0, 0, 0, 0, 0 ],
      p: zero9.dup,
      s: zero9.dup,
      z: zero7.dup
    }
    melds = []

    result = HandEvaluator.build_agari_mentsu_all(hands, melds)
    assert_equal [ [ 'm123' ] ], result
  end

  test 'combine suits: m123 + p123' do
    hands = {
      m: [ 1, 1, 1, 0, 0, 0, 0, 0, 0 ],
      p: [ 1, 1, 1, 0, 0, 0, 0, 0, 0 ],
      s: zero9.dup,
      z: zero7.dup
    }
    melds = []

    result = HandEvaluator.build_agari_mentsu_all(hands, melds)
    assert_equal [ [ 'm123', 'p123' ] ], result
  end

  test 'honors: z111 only' do
    hands = {
      m: zero9.dup,
      p: zero9.dup,
      s: zero9.dup,
      z: [ 3, 0, 0, 0, 0, 0, 0 ]
    }
    melds = []

    result = HandEvaluator.build_agari_mentsu_all(hands, melds)
    assert_equal [ [ 'z111' ] ], result
  end

  test 'honors invalid (count 1 or 2) returns []' do
    hands = {
      m: zero9.dup,
      p: zero9.dup,
      s: zero9.dup,
      z: [ 0, 2, 0, 0, 0, 0, 0 ]
    }
    melds = []

    result = HandEvaluator.build_agari_mentsu_all(hands, melds)
    assert_equal [], result
  end

  test 'existing meld list is appended to every result' do
    hands = {
      m: [ 1, 1, 1, 0, 0, 0, 0, 0, 0 ],
      p: zero9.dup,
      s: zero9.dup,
      z: zero7.dup
    }
    melds = [ 'p789-' ]

    result = HandEvaluator.build_agari_mentsu_all(hands, melds)
    assert_equal [ [ 'm123', 'p789-' ] ], result
  end

  test 'both branches in one suit: m(333,222,111) -> either sequences x3 or triplets x3' do
    hands = {
      m: [ 3, 3, 3, 0, 0, 0, 0, 0, 0 ],
      p: zero9.dup,
      s: zero9.dup,
      z: zero7.dup
    }
    melds = []

    result = HandEvaluator.build_agari_mentsu_all(hands, melds)
    expected = [
      [ 'm123', 'm123', 'm123' ],
      [ 'm111', 'm222', 'm333' ]
    ]
    assert_equal expected, result
  end

  test 'non-destructive: counts and meld arrays unchanged' do
    m = [ 1, 1, 1, 0, 0, 0, 0, 0, 0 ]; p = zero9.dup; s = zero9.dup; z = zero7.dup
    melds = [ 'm777' ]
    hands = { m: m, p: p, s: s, z: z }

    _ = HandEvaluator.build_agari_mentsu_all(hands, melds)

    assert_equal [ 1, 1, 1, 0, 0, 0, 0, 0, 0 ], m
    assert_equal zero9, p
    assert_equal zero9, s
    assert_equal zero7, z
    assert_equal [ 'm777' ], melds
  end

  test 'sum not multiple of 3 in a suit leads to [] overall' do
    hands = {
      m: [ 3, 2, 2, 0, 0, 0, 0, 0, 0 ],
      p: zero9.dup,
      s: zero9.dup,
      z: zero7.dup
    }
    melds = []

    result = HandEvaluator.build_agari_mentsu_all(hands, melds)
    assert_equal [], result
  end

  # add_agari_mark
  # agari_tile：1萬のツモ和了は 'm1_', 下家からの出和了は 'm1+', 対面からの出上がり 'm1=', 上家からの出和了は 'm1-'
  test 'marks matching meld with ! (sequence)' do
    mentsu_list = [ 'm123', 'p123' ]
    result  = HandEvaluator.add_agari_mark(mentsu_list, 'm2_')
    assert_equal [ [ 'm12_!3', 'p123' ] ], result
  end

  test 'marks matching meld with ! (triplet)' do
    mentsu_list = [ 'm111', 'p123' ]
    result  = HandEvaluator.add_agari_mark(mentsu_list, 'm1_')
    assert_equal [ [ 'm111_!', 'p123' ] ], result
    assert_equal [ 'm111', 'p123' ], mentsu_list
  end

  test 'skips open-meld strings containing -, +, =' do
    mentsu_list = [ 'm123-', 'm123', 'p1+23', 's555=' ]
    result  = HandEvaluator.add_agari_mark(mentsu_list, 'm2=')
    # マッチするのは "m123" のみ → "m12_3"
    assert_equal [ [ 'm123-', 'm12=!3', 'p1+23', 's555=' ] ], result
  end

  test 'skips consecutive duplicates to avoid duplicate results' do
    mentsu_list = [ 'm123', 'm123', 's789' ]
    result  = HandEvaluator.add_agari_mark(mentsu_list, 'm2_')
    # 先頭だけ置換し、2つめの同一要素はスキップ
    assert_equal [ [ 'm12_!3', 'm123', 's789' ] ], result
  end

  test "returns [] when regex doesn't match any meld (wrong suit/number)" do
    mentsu_list = [ 'p111', 's789' ]
    result  = HandEvaluator.add_agari_mark(mentsu_list, 'm2_')
    assert_equal [],  result
  end

  test 'produces one result per different matching position (no duplicates)' do
    mentsu_list = [ 'm123', 'm111', 'p777' ]
    result = HandEvaluator.add_agari_mark(mentsu_list, 'm1_')
    # i=0 を置換した配列 と i=1 を置換した配列 の2通り
    expected = [
      [ 'm1_!23', 'm111', 'p777' ],
      [ 'm123',  'm111_!', 'p777' ]
    ]
    assert_equal expected,  result
  end

  test 'does not mutate strings or the input array (non-destructive)' do
    mentsu_list = [ 'm123', 'm456' ]
    clones = mentsu_list.map(&:dup)
    _ = HandEvaluator.add_agari_mark(mentsu_list, 'm2_')
    assert_equal clones,  mentsu_list
  end

  test 'chiitoitsu and mentsu with s8 from opponent' do
    nested_mentsu_list = [
      [ 'm22', 'm33', 'm44', 'p55', 'p66', 'p77', 's88' ],
      [ 'm234', 'm234', 'p567', 'p567', 's88' ]
    ]
    result = nested_mentsu_list.flat_map { |mentsu_list| HandEvaluator.add_agari_mark(mentsu_list, 's8=') }

    expected = [
      [ 'm22', 'm33', 'm44', 'p55', 'p66', 'p77', 's88=!' ],
      [ 'm234', 'm234', 'p567', 'p567', 's88=!' ]
    ]
    assert_equal expected, result
  end


  test 'two decompositions, mark goes to pair or sequence (p9 from opponent)' do
    nested_mentsu_list = [
      [ 'p99', 'm123', 'm123', 'm123', 'p789' ],
      [ 'p99', 'm111', 'm222', 'm333', 'p789' ]
    ]
    result = nested_mentsu_list.flat_map { |mentsu_list| HandEvaluator.add_agari_mark(mentsu_list, 'p9=') }

    expected = [
      [ 'p99=!', 'm123', 'm123', 'm123', 'p789' ],
      [ 'p99', 'm123', 'm123', 'm123', 'p789=!' ],
      [ 'p99=!', 'm111', 'm222', 'm333', 'p789' ],
      [ 'p99', 'm111', 'm222', 'm333', 'p789=!' ]
    ]
    assert_equal expected, result
  end

  test 'which m3 gets the mark (opponent ron), different head choices' do
    nested_mentsu_list = [
      [ 'm22', 'm345', 'm345', 'p234', 's234' ],  # 片方の m345 にだけマーク（同一要素の2つ目はスキップ）
      [ 'm55', 'm234', 'm234', 'p234', 's234' ]   # 片方の m234 にだけマーク
    ]
    result = nested_mentsu_list.flat_map { |mentsu_list| HandEvaluator.add_agari_mark(mentsu_list, 'm3=') }

    expected = [
      [ 'm22', 'm3=!45', 'm345', 'p234', 's234' ],
      [ 'm55', 'm23=!4', 'm234', 'p234', 's234' ]
    ]
    assert_equal expected, result
  end

  test 'm2 from opponent, can belong to either m123 or m234' do
    mentsu_list = [ 's88', 'm123', 'm234', 'p567', 'z777' ]
    result  = HandEvaluator.add_agari_mark(mentsu_list, 'm2=')

    expected = [
      [ 's88', 'm12=!3', 'm234', 'p567', 'z777' ],
      [ 's88', 'm123', 'm2=!34', 'p567', 'z777' ]
    ]
    assert_equal expected, result
  end

  # build_normal_agari_patter
  test 'returns [] when no jantou exists anywhere' do
    # m123456789, p12345
    hands = {
      m: [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
      p: [ 1, 1, 1, 1, 1, 0, 0, 0, 0 ],
      s: zero9.dup,
      z: zero7.dup
    }
    melds = []

    result = HandEvaluator.build_normal_agari_patterns(hands, melds, 'm2')
    assert_equal [], result
  end

  test 'one simple pattern: jantou p99 and agari on m123' do
    # m123456789, p12344
    hands = {
      m: [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
      p: [ 1, 1, 1, 2, 0, 0, 0, 0, 0 ],
      s: zero9.dup,
      z: zero7.dup
    }
    melds = []

    result = HandEvaluator.build_normal_agari_patterns(hands, melds, 'm2_')
    expected = [ [ 'p44', 'm12_!3', 'm456', 'm789', 'p123' ] ]
    assert_equal expected, result
  end

  test 'pattern 1 (normal-hand row): s8 from opponent goes to the pair' do
    # m223344, p556677, s88
    hands = {
      m: [ 0, 2, 2, 2, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 0, 0, 2, 2, 2, 0, 0 ],
      s: [ 0, 0, 0, 0, 0, 0, 0, 2, 0 ],
      z: zero7.dup
    }
    melds = []
    result = HandEvaluator.build_normal_agari_patterns(hands, melds, 's8=')
    expected = [ [ 's88=!', 'm234', 'm234', 'p567', 'p567' ] ]
    assert_equal expected, result
  end

  test 'pattern 2: two decompositions x two placements (p9 from opponent)' do
    # m111222333, p78999
    hands = {
      m: [ 3, 3, 3, 0, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 0, 0, 0, 0, 1, 1, 3 ],
      s: zero9.dup,
      z: zero7.dup
    }
    melds = []
    result = HandEvaluator.build_normal_agari_patterns(hands, melds, 'p9+')

    expected = [
      [ 'p99+!', 'm123', 'm123', 'm123', 'p789' ],
      [ 'p99',   'm123', 'm123', 'm123', 'p789+!' ],
      [ 'p99+!', 'm111', 'm222', 'm333', 'p789' ],
      [ 'p99',   'm111', 'm222', 'm333', 'p789+!' ]
    ]
    assert_equal expected, result
  end

  test 'pattern 4: m2 from opponent can belong to either m123 or m234' do
    # m122334, p567, s88, z777
    hands = {
      m: [ 1, 2, 2, 1, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 0, 0, 1, 1, 1, 0, 0 ],
      s: [ 0, 0, 0, 0, 0, 0, 0, 2, 0 ],
      z: [ 0, 0, 0, 0, 0, 0, 3 ]
    }
    melds = []
    result = HandEvaluator.build_normal_agari_patterns(hands, melds, 'm2-')

    expected = [
      [ 's88', 'm12-!3', 'm234', 'p567', 'z777' ],
      [ 's88', 'm123',   'm2-!34', 'p567', 'z777' ]
    ]
    assert_equal expected, result
  end

  test 'open melds are not marked (skip strings containing -/=/+)' do
    # m123456789, p99, meld:m123
    hands = {
      m: [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
      p: [ 0, 0, 0, 0, 0, 0, 0, 0, 2 ],
      s: zero9.dup,
      z: zero7.dup
    }
    melds = [ 'm1-23' ] # 下家から1萬チー
    result = HandEvaluator.build_normal_agari_patterns(hands, melds, 'm1-')

    # 和了マークはhands内の面子 "m123" 側につく
    expected = [ [ 'p99', 'm1-!23', 'm456', 'm789', 'm1-23' ] ]
    assert_equal expected, result
  end

  test 'greedy marking for duplicates: m1 on m111 becomes m111_' do
    # m111333555999, z77
    hands = {
      m: [ 3, 0, 3, 0, 3, 0, 0, 0, 3 ],
      p: zero9.dup,
      s: zero9.dup,
      z: [ 0, 0, 0, 0, 0, 0, 2 ]
    }
    melds = []
    result = HandEvaluator.build_normal_agari_patterns(hands, melds, 'm1=')

    # m111 に対して貪欲一致
    expected = [ [ 'z77', 'm111=!', 'm333', 'm555', 'm999' ] ]
    assert_equal expected, result
  end

  test 'does not mutate inputs (hands and melds remain unchanged)' do
    # m111333555999, z77
    hands = {
      m: [ 3, 0, 3, 0, 3, 0, 0, 0, 3 ],
      p: zero9.dup,
      s: zero9.dup,
      z: [ 0, 0, 0, 0, 0, 0, 2 ]
    }
    hands_clone = hands.dup
    melds = [ 'p789' ]
    melds_clone = melds.dup

    _ = HandEvaluator.build_normal_agari_patterns(hands, melds, 'm2_')
    assert_equal hands_clone, hands
    assert_equal melds_clone, melds
  end

  # build_chiitoitsu_agari_patterns
  test 'tsumo: marks the winning pair with underscore only' do
    # m1122, p3344, s5566, z77
    hands = {
      m: [ 2, 2, 0, 0, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 2, 2, 0, 0, 0, 0, 0 ],
      s: [ 0, 0, 0, 0, 2, 2, 0, 0, 0 ],
      z: [ 0, 0, 0, 0, 0, 0, 2 ]
    }

    result = HandEvaluator.build_chiitoitsu_agari_patterns(hands, 's6_')
    expected = [ [ 'm11', 'm22', 'p33', 'p44', 's55', 's66_!', 'z77' ] ]
    assert_equal expected, result
  end

  test "ron from shimocha (+): marks pair with '+!'" do
    # m1122, p3344, s5566, z77
    hands = {
      m: [ 2, 2, 0, 0, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 2, 2, 0, 0, 0, 0, 0 ],
      s: [ 0, 0, 0, 0, 2, 2, 0, 0, 0 ],
      z: [ 0, 0, 0, 0, 0, 0, 2 ]
    }
    result = HandEvaluator.build_chiitoitsu_agari_patterns(hands, 'm2+')
    expected = [ [ 'm11', 'm22+!', 'p33', 'p44', 's55', 's66', 'z77' ] ]
    assert_equal expected, result
  end

  test "ron from toimen (=): marks pair with '=!'" do
    # m1122, p3344, s5566, z77
    hands = {
      m: [ 2, 2, 0, 0, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 2, 2, 0, 0, 0, 0, 0 ],
      s: [ 0, 0, 0, 0, 2, 2, 0, 0, 0 ],
      z: [ 0, 0, 0, 0, 0, 0, 2 ]
    }
    result = HandEvaluator.build_chiitoitsu_agari_patterns(hands, 'p3=')
    expected = [ [ 'm11', 'm22', 'p33=!', 'p44', 's55', 's66', 'z77' ] ]
    assert_equal expected, result
  end

  test 'invalid: contains a singleton tile' do
    # m1223, p3344, s5566, z77
    hands = {
      m: [ 1, 2, 1, 0, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 2, 2, 0, 0, 0, 0, 0 ],
      s: [ 0, 0, 0, 0, 2, 2, 0, 0, 0 ],
      z: [ 0, 0, 0, 0, 0, 0, 2 ]
    }
    result = HandEvaluator.build_chiitoitsu_agari_patterns(hands, 'm2')
    assert_equal [], result
  end

  test 'invalid: contains a non-pair count (count 4)' do
    # m1111, p3344, s5566, z77
    hands = {
      m: [ 4, 0, 0, 0, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 2, 2, 0, 0, 0, 0, 0 ],
      s: [ 0, 0, 0, 0, 2, 2, 0, 0, 0 ],
      z: [ 0, 0, 0, 0, 0, 0, 2 ]
    }
    result = HandEvaluator.build_chiitoitsu_agari_patterns(hands, 'm1')
    assert_equal [], result
  end

  test 'invalid: total tile count != 14' do
    # m1122, p3344, s55, z77
    hands = {
      m: [ 2, 2, 0, 0, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 2, 2, 0, 0, 0, 0, 0 ],
      s: [ 0, 0, 0, 0, 2, 0, 0, 0, 0 ],
      z: [ 0, 0, 0, 0, 0, 0, 2 ]
    }
    result = HandEvaluator.build_chiitoitsu_agari_patterns(hands, 'm2')
    assert_equal [], result
  end

  test 'no matching agari_tile: returns unmarked seven pairs in order m->p->s->z' do
    # m1122, p3344, s5566, z77
    hands = {
      m: [ 2, 2, 0, 0, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 2, 2, 0, 0, 0, 0, 0 ],
      s: [ 0, 0, 0, 0, 2, 2, 0, 0, 0 ],
      z: [ 0, 0, 0, 0, 0, 0, 2 ]
    }
    result = HandEvaluator.build_chiitoitsu_agari_patterns(hands, 'm9')
    expected = [ [ 'm11', 'm22', 'p33', 'p44', 's55', 's66', 'z77' ] ]
    assert_equal expected, result
  end

  test 'does not mutate input hands' do
    # m1122, p3344, s5566, z77
    hands = {
      m: [ 2, 2, 0, 0, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 2, 2, 0, 0, 0, 0, 0 ],
      s: [ 0, 0, 0, 0, 2, 2, 0, 0, 0 ],
      z: [ 0, 0, 0, 0, 0, 0, 2 ]
    }
    clone = hands.dup
    _ = HandEvaluator.build_chiitoitsu_agari_patterns(hands, 's6')
    assert_equal clone, hands
  end

  # build_kokushi_agari_patterns
  test 'tsumo on the pair: m1 as pair, returns pair first then all singles' do
    # m119, p19, s19, z1234567
    hands = {
      m: [ 2, 0, 0, 0, 0, 0, 0, 0, 1 ],
      p: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      s: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      z: [ 1, 1, 1, 1, 1, 1, 1 ]
    }
    result = HandEvaluator.build_kokushi_agari_patterns(hands, 'm1_')
    expected = [ [
      'm11_!',
      'm9', 'p1', 'p9', 's1', 's9',
      'z1', 'z2', 'z3', 'z4', 'z5', 'z6', 'z7'
    ] ]
    assert_equal expected, result
  end

  test 'ron from shimocha on a single: p9+' do
    # m119, p19, s19, z1234567
    hands = {
      m: [ 2, 0, 0, 0, 0, 0, 0, 0, 1 ],
      p: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      s: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      z: [ 1, 1, 1, 1, 1, 1, 1 ]
    }
    result = HandEvaluator.build_kokushi_agari_patterns(hands, 'p9+')
    expected = [ [
      'm11',
      'm9', 'p1', 'p9+!', 's1', 's9',
      'z1', 'z2', 'z3', 'z4', 'z5', 'z6', 'z7'
    ] ]
    assert_equal expected, result
  end

  test 'ron from toimen on the pair: z3= as pair' do
    # m19, p19, s19, z12334567
    hands = {
      m: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      p: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      s: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      z: [ 1, 1, 2, 1, 1, 1, 1 ]
    }
    result = HandEvaluator.build_kokushi_agari_patterns(hands, 'z3=')
    expected = [ [
      'z33=!',
      'm1', 'm9', 'p1', 'p9', 's1', 's9',
      'z1', 'z2', 'z4', 'z5', 'z6', 'z7'
    ] ]
    assert_equal expected, result
  end

  test 'invalid: a required tile is missing (z7=0) → returns []' do
    # m119, p19, s19, z123456
    hands = {
      m: [ 2, 0, 0, 0, 0, 0, 0, 0, 1 ],
      p: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      s: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      z: [ 1, 1, 1, 1, 1, 1, 0 ]
    }
    result = HandEvaluator.build_kokushi_agari_patterns(hands, 'm1')
    assert_equal [], result
  end

  test 'invalid: a required tile has count >=3 (s1=3) → returns []' do
    hands = {
      m: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      p: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      s: [ 3, 0, 0, 0, 0, 0, 0, 0, 1 ],
      z: [ 1, 1, 1, 1, 1, 1, 1 ]
    }
    result = HandEvaluator.build_kokushi_agari_patterns(hands, 's1')
    assert_equal [], result
  end

  test 'does not mutate input' do
    hands = {
      m: [ 2, 0, 0, 0, 0, 0, 0, 0, 1 ],
      p: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      s: [ 1, 0, 0, 0, 0, 0, 0, 0, 1 ],
      z: [ 1, 1, 1, 1, 1, 1, 1 ]
    }
    hands_clone = hands.dup
    _ = HandEvaluator.build_kokushi_agari_patterns(hands, 'm1')
    assert_equal hands_clone, hands
  end

  # build_chuurenpoutou_agari_patterns
  test 'returns chuurenpoutou pattern for a valid manzu hand (winning 1m)' do
    hands = {
      m: [ 4, 1, 1, 1, 1, 1, 1, 1, 3 ],
      p: zero9.dup,
      s: zero9.dup,
      z: zero9.dup
    }
    result = HandEvaluator.build_chuurenpoutou_agari_patterns(hands, 'm1=')
    assert_equal [ [ 'm11123456789991=!' ] ], result
  end

  test 'invalid: tiles are not all in one suit' do
    hands = {
      m: [ 2, 1, 1, 1, 1, 1, 1, 1, 3 ],
      p: zero9.dup,
      s: zero9.dup,
      z: [ 2, 0, 0, 0, 0, 0, 0, 0, 0 ]
    }
    result = HandEvaluator.build_chuurenpoutou_agari_patterns(hands, 'm1=')
    assert_equal [], result
  end

  test 'invalid: middle tile (2..8) is zero ' do
    hands = {
      m: [ 4, 1, 1, 0, 1, 1, 1, 1, 4 ],
      p: zero9.dup,
      s: zero9.dup,
      z: zero9.dup
    }
    result = HandEvaluator.build_chuurenpoutou_agari_patterns(hands, 'm1=')
    assert_equal [], result
  end

  # build_agari_all_patters
  test 'returns both normal and chiitoitsu patterns' do
    # m223344, p556677, s88
    hands = {
      m: [ 0, 2, 2, 2, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 0, 0, 2, 2, 2, 0, 0 ],
      s: [ 0, 0, 0, 0, 0, 0, 0, 2, 0 ],
      z: zero7
    }
    melds = []
    agari_tile = 'm3='

    normal_expected = [ 's88', 'm23=!4', 'm234', 'p567', 'p567' ]
    chiitoitsu_expected = [ 'm22', 'm33=!', 'm44', 'p55', 'p66', 'p77', 's88' ]

    result = HandEvaluator.build_agari_all_patters(hands, melds, agari_tile)
    assert_equal [ normal_expected, chiitoitsu_expected ], result
  end

  # build_bonus_yaku_list
  test 'tenhou overrides everything' do
    situational_yaku_list = { tenhou: true, chiihou: false, riichi: 2, ippatsu: true, haitei: 2, rinshan: true, chankan: true }
    result = HandEvaluator.build_bonus_yaku_list(situational_yaku_list)
    assert_equal [ { name: '天和', han: 13 } ], result
  end

  test 'chiihou overrides everything when no tenhou' do
    situational_yaku_list = { tenhou: false, chiihou: true, riichi: 1, ippatsu: true, haitei: 1, rinshan: true, chankan: true }
    result  = HandEvaluator.build_bonus_yaku_list(situational_yaku_list)
    assert_equal [ { name: '地和', han: 13 } ], result
  end

  test 'riichi single adds 立直(1) only' do
    situational_yaku_list = { tenhou: false, chiihou: false, riichi: 1 }
    result  = HandEvaluator.build_bonus_yaku_list(situational_yaku_list)
    assert_equal [ { name: '立直', han: 1 } ], result
  end

  test 'riichi double adds 立直(2) only' do
    situational_yaku_list = { tenhou: false, chiihou: false, riichi: 2 }
    result  = HandEvaluator.build_bonus_yaku_list(situational_yaku_list)
    assert_equal [ { name: 'ダブル立直', han: 2 } ], result
  end

  test 'ippatsu adds 一発(1)' do
    situational_yaku_list = { tenhou: false, chiihou: false, riichi: 1, ippatsu: true }
    result  = HandEvaluator.build_bonus_yaku_list(situational_yaku_list)
    assert_equal [ { name: '立直', han: 1 }, { name: '一発', han: 1 } ], result
  end

  test 'haitei=1 adds 海底摸月(1), haitei=2 adds 河底撈魚(1)' do
    situ1 = { tenhou: false, chiihou: false, riichi: 1, haitei: 1 }
    situ2 = { tenhou: false, chiihou: false, riichi: 1, haitei: 2 }

    result_1 = HandEvaluator.build_bonus_yaku_list(situ1)
    result_2 = HandEvaluator.build_bonus_yaku_list(situ2)

    assert_equal [ { name: '立直', han: 1 }, { name: '海底摸月', han: 1 } ], result_1
    assert_equal [ { name: '立直', han: 1 }, { name: '河底撈魚', han: 1 } ], result_2
  end

  test 'rinshan adds 嶺上開花(1), chankan adds 槍槓(1)' do
    situational_yaku_list = { tenhou: false, chiihou: false, rinshan: true, chankan: true }
    result  = HandEvaluator.build_bonus_yaku_list(situational_yaku_list)
    assert_equal [
      { name: '嶺上開花', han: 1 },
      { name: '槍槓',    han: 1 }
    ], result
  end

  test 'combined order: riichi -> ippatsu -> haitei/houtei -> rinshan -> chankan' do
    situational_yaku_list = {
      tenhou:  false,
      chiihou: false,
      riichi:  2,
      ippatsu: true,
      haitei:  2,
      rinshan: false,
      chankan: true
    }
    result = HandEvaluator.build_bonus_yaku_list(situational_yaku_list)
    assert_equal [
      { name: 'ダブル立直',   han: 2 },
      { name: '一発',        han: 1 },
      { name: '河底撈魚',     han: 1 },
      { name: '槍槓',        han: 1 }
    ], result
  end

  test 'no flags returns empty list' do
    situational_yaku_list = { tenhou: false, chiihou: false }
    result  = HandEvaluator.build_bonus_yaku_list(situational_yaku_list)
    assert_equal [], result
  end

  # build_dora_yaku_list
  test 'returns empty array when all counts are zero' do
    assert_equal [], HandEvaluator.build_dora_yaku_list(0, 0, 0)
  end

  test 'returns only Dora when dora > 0' do
    assert_equal [ { name: 'ドラ', han: 2 } ], HandEvaluator.build_dora_yaku_list(2, 0, 0)
  end

  test 'returns only Aka Dora when aka_dora > 0' do
    assert_equal [ { name: '赤ドラ', han: 3 } ], HandEvaluator.build_dora_yaku_list(0, 0, 3)
  end

  test 'returns only Ura Dora when ura_dora > 0' do
    assert_equal [ { name: '裏ドラ', han: 1 } ], HandEvaluator.build_dora_yaku_list(0, 1, 0)
  end

  test 'returns all three in fixed order: Dora, Aka Dora, Ura Dora' do
    result = HandEvaluator.build_dora_yaku_list(2, 1, 3)
    expected = [
      { name: 'ドラ',  han: 2 },
      { name: '赤ドラ', han: 3 },
      { name: '裏ドラ', han: 1 }
    ]
    assert_equal expected, result
  end

  test 'skips zero counts and preserves the order of remaining items' do
    result = HandEvaluator.build_dora_yaku_list(1, 0, 2)   # ドラ1、裏0、赤2
    expected = [
      { name: 'ドラ',  han: 1 },
      { name: '赤ドラ', han: 2 }
    ]
    assert_equal expected, result
  end

  # build_scoring_states
  test 'メンゼン平和ツモ：20府固定' do
    agari = [
      'p55',
      'm123',
      'm789_!',
      'p567',
      's345'
    ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 20,
        fu_raw: 20,
        fu_components: { standard: 20, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 0, menzen: 0, kotsu_or_kantsu: 0 },
        shuntsu: { m: { '123' => 1, '789' => 1 }, p: { '567' => 1 }, s: { '345' => 1 } },
        kotsu: { m: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'p55',
        mentsu_count: 5,
        shuntsu_count: 4,
        kotsu_or_kantsu_count: 0,
        anko_or_ankan_count: 0,
        kantsu_count: 0,
        zihai_count: 0,
        yaochu_count: 2,
        menzen: true,
        tsumo: true,
        tanki: false,
        pinfu: true,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'p55m123m789_!p567s345'
      }, result
    )
  end

  test '門前ロン：20 + 10(menzen) = 30' do
    agari = [
      'p55',
      'm123',
      'm123',
      'p567',
      's345=!'
    ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 30,
        fu_raw: 30,
        fu_components: { standard: 20, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 0, menzen: 10, kotsu_or_kantsu: 0 },
        shuntsu: { m: { '123' => 2 }, p: { '567' => 1 }, s: { '345' => 1 } },
        kotsu: { m: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'p55',
        mentsu_count: 5,
        shuntsu_count: 4,
        kotsu_or_kantsu_count: 0,
        anko_or_ankan_count: 0,
        kantsu_count: 0,
        zihai_count: 0,
        yaochu_count: 2,
        menzen: true,
        tsumo: false,
        tanki: false,
        pinfu: true,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'p55m123m123p567s345=!'
      }, result
    )
  end

  test '喰タンツモ：20 + 2(tsumo) = 22 → 30' do
    agari = [
      'p55',
      'm234-',
      'm456',
      'p567',
      's678_!'
    ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 30,
        fu_raw: 22,
        fu_components: { standard: 20, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 2, menzen: 0, kotsu_or_kantsu: 0 },
        shuntsu: { m: { '234' => 1, '456' => 1 }, p: { '567' => 1 }, s: { '678' => 1 } },
        kotsu: { m: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'p55',
        mentsu_count: 5,
        shuntsu_count: 4,
        kotsu_or_kantsu_count: 0,
        anko_or_ankan_count: 0,
        kantsu_count: 0,
        zihai_count: 0,
        yaochu_count: 0,
        menzen: false,
        tsumo: true,
        tanki: false,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'p55m234-m456p567s678_!'
      }, result
    )
  end

  test '喰タン平和系ロン：30府固定' do
    agari = [
      'p55',
      'm234-',
      'm456',
      'p567=!',
      's678'
    ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 30,
        fu_raw: 30,
        fu_components: { standard: 30, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 0, menzen: 0, kotsu_or_kantsu: 0 },
        shuntsu: { m: { '234' => 1, '456' => 1 }, p: { '567' => 1 }, s: { '678' => 1 } },
        kotsu: { m: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'p55',
        mentsu_count: 5,
        shuntsu_count: 4,
        kotsu_or_kantsu_count: 0,
        anko_or_ankan_count: 0,
        kantsu_count: 0,
        zihai_count: 0,
        yaochu_count: 0,
        menzen: false,
        tsumo: false,
        tanki: false,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'p55m234-m456p567=!s678'
      }, result
    )
  end

  test '喰タンロン（暗刻*1）：30府固定' do
    agari = [
      'p55',
      'm234-',
      'm888',
      'p567=!',
      's678'
    ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 30,
        fu_raw: 24,
        fu_components: { standard: 20, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 0, menzen: 0, kotsu_or_kantsu: 4 },
        shuntsu: { m: { '234' => 1 }, p: { '567' => 1 }, s: { '678' => 1 } },
        kotsu: { m: [ 0, 0, 0, 0, 0, 0, 0, 1, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'p55',
        mentsu_count: 5,
        shuntsu_count: 3,
        kotsu_or_kantsu_count: 1,
        anko_or_ankan_count: 1,
        kantsu_count: 0,
        zihai_count: 0,
        yaochu_count: 0,
        menzen: false,
        tsumo: false,
        tanki: false,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'p55m234-m888p567=!s678'
      }, result
    )
  end

  test '七対子ロン：25符固定' do
    agari = [ 'm11=!', 'm99', 'p22', 's33', 's77', 'z55', 'p55' ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 25,
        fu_raw: 25,
        fu_components: { standard: 25, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 0, menzen: 0, kotsu_or_kantsu: 0 },
        shuntsu: { m: {}, p: {}, s: {} },
        kotsu: { m: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'm11=!',
        mentsu_count: 7,
        shuntsu_count: 0,
        kotsu_or_kantsu_count: 0,
        anko_or_ankan_count: 0,
        kantsu_count: 0,
        zihai_count: 1,
        yaochu_count: 3,
        menzen: true,
        tsumo: false,
        tanki: true,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'm11=!m99p22s33s77z55p55'
      }, result
    )
  end

  test '七対子ツモ：25符固定' do
    agari = [ 'm11_!', 'm99', 'p22', 's33', 's77', 'z55', 'p55' ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 25,
        fu_raw: 25,
        fu_components: { standard: 25, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 0, menzen: 0, kotsu_or_kantsu: 0 },
        shuntsu: { m: {}, p: {}, s: {} },
        kotsu: { m: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'm11_!',
        shuntsu_count: 0,
        kotsu_or_kantsu_count: 0,
        anko_or_ankan_count: 0,
        kantsu_count: 0,
        zihai_count: 1,
        yaochu_count: 3,
        mentsu_count: 7,
        menzen: true,
        tsumo: true,
        tanki: true,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'm11_!m99p22s33s77z55p55'
      }, result
    )
  end

  test '嵌張ツモ：20 + 2(penchan) + 2(tsumo) = 24 -> 30' do
    agari = [
      'p55',
      'm123',
      'p123',
      's12_!3',
      's345'
    ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 30,
        fu_raw: 24,
        fu_components: { standard: 20, jantou: 0, tanki: 0, kanchan: 2, penchan: 0, tsumo: 2, menzen: 0, kotsu_or_kantsu: 0 },
        shuntsu: { m: { '123' => 1 }, p: { '123' => 1 }, s: { '123' => 1, '345' => 1 } },
        kotsu: { m: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'p55',
        mentsu_count: 5,
        shuntsu_count: 4,
        kotsu_or_kantsu_count: 0,
        anko_or_ankan_count: 0,
        kantsu_count: 0,
        zihai_count: 0,
        yaochu_count: 3,
        menzen: true,
        tsumo: true,
        tanki: false,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'p55m123p123s12_!3s345'
      }, result
    )
  end

  test '辺張ツモ：20 + 2(penchan) + 2(tsumo) = 24 -> 30' do
    agari = [
      'p55',
      'm123_!',
      'm234',
      'p456',
      's678'
    ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 30,
        fu_raw: 24,
        fu_components: { standard: 20, jantou: 0, tanki: 0, kanchan: 0, penchan: 2, tsumo: 2, menzen: 0, kotsu_or_kantsu: 0 },
        shuntsu: { m: { '123' => 1, '234' => 1 }, p: { '456' => 1 }, s: { '678' => 1 } },
        kotsu: { m: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'p55',
        mentsu_count: 5,
        shuntsu_count: 4,
        kotsu_or_kantsu_count: 0,
        anko_or_ankan_count: 0,
        kantsu_count: 0,
        zihai_count: 0,
        yaochu_count: 1,
        menzen: true,
        tsumo: true,
        tanki: false,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'p55m123_!m234p456s678'
      }, result
    )
  end

  test '暗刻（中張牌）* 2 + 門前ロン：20 + 4(anko) * 2 + 10(menzen) = 38 → 40' do
    agari = [
      'p55',
      'm222',
      'm678=!',
      'p444',
      's345'
    ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 40,
        fu_raw: 38,
        fu_components: { standard: 20, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 0, menzen: 10, kotsu_or_kantsu: 8 },
        shuntsu: { m: { '678' => 1 }, p: {}, s: { '345' => 1 } },
        kotsu: { m: [ 0, 1, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 1, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'p55',
        mentsu_count: 5,
        shuntsu_count: 2,
        kotsu_or_kantsu_count: 2,
        anko_or_ankan_count: 2,
        kantsu_count: 0,
        zihai_count: 0,
        yaochu_count: 0,
        menzen: true,
        tsumo: false,
        tanki: false,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'p55m222m678=!p444s345'
      }, result
    )
  end

  test '暗刻（么九牌）* 3 + 門前ロン：20 + 8(anko) * 3 + 10(menzen) = 54 → 60' do
    agari = [
      'p55',
      'm111',
      'm678=!',
      'p111',
      's111'
    ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 60,
        fu_raw: 54,
        fu_components: { standard: 20, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 0, menzen: 10, kotsu_or_kantsu: 24 },
        shuntsu: { m: { '678' => 1 }, p: {}, s: {} },
        kotsu: { m: [ 1, 0, 0, 0, 0, 0, 0, 0, 0 ], p: [ 1, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 1, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'p55',
        mentsu_count: 5,
        shuntsu_count: 1,
        kotsu_or_kantsu_count: 3,
        anko_or_ankan_count: 3,
        kantsu_count: 0,
        zihai_count: 0,
        yaochu_count: 3,
        menzen: true,
        tsumo: false,
        tanki: false,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'p55m111m678=!p111s111'
      }, result
    )
  end

  test '槓子（中張牌）+ 門前ツモ：20 + 16(kantsu) + 2(tsumo) = 38 → 40' do
    agari = [
      'p55',
      'm2222',
      'm678_!',
      'p234',
      's567'
    ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 40,
        fu_raw: 38,
        fu_components: { standard: 20, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 2, menzen: 0, kotsu_or_kantsu: 16 },
        shuntsu: { m: { '678' => 1 }, p: { '234' => 1 }, s: { '567' => 1 } },
        kotsu: { m: [ 0, 1, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'p55',
        mentsu_count: 5,
        shuntsu_count: 3,
        kotsu_or_kantsu_count: 1,
        anko_or_ankan_count: 1,
        kantsu_count: 1,
        zihai_count: 0,
        yaochu_count: 0,
        menzen: true,
        tsumo: true,
        tanki: false,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'p55m2222m678_!p234s567'
      }, result
    )
  end


  test '槓子（么九牌）+ 門前ツモ：20 + 32(kantsu) + 2(tsumo) = 54 → 60' do
    agari = [
      'p55',
      'm1111',
      'm678_!',
      'p234',
      's567'
    ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 60,
        fu_raw: 54,
        fu_components: { standard: 20, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 2, menzen: 0, kotsu_or_kantsu: 32 },
        shuntsu: { m: { '678' => 1 }, p: { '234' => 1 }, s: { '567' => 1 } },
        kotsu: { m: [ 1, 0, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'p55',
        mentsu_count: 5,
        shuntsu_count: 3,
        kotsu_or_kantsu_count: 1,
        anko_or_ankan_count: 1,
        kantsu_count: 1,
        zihai_count: 0,
        yaochu_count: 1,
        menzen: true,
        tsumo: true,
        tanki: false,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'p55m1111m678_!p234s567'
      }, result
    )
  end

  test '九蓮宝燈：mentsu_count = 1, fu = 0' do
    agari = [ 'm11112345678999=!' ]
    result = HandEvaluator.build_scoring_states(agari, 0, 0)
    assert_equal(
      {
        fu_total: 0,
        fu_raw: 0,
        fu_components: { standard: 20, jantou: 0, tanki: 0, kanchan: 0, penchan: 0, tsumo: 0, menzen: 0, kotsu_or_kantsu: 0 },
        shuntsu: { m: {}, p: {}, s: {} },
        kotsu: { m: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], p: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], s: [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], z: [ 0, 0, 0, 0, 0, 0, 0 ] },
        jantou: 'm11112345678999=!',
        mentsu_count: 1,
        shuntsu_count: 0,
        kotsu_or_kantsu_count: 0,
        anko_or_ankan_count: 0,
        kantsu_count: 0,
        zihai_count: 0,
        yaochu_count: 1,
        menzen: true,
        tsumo: false,
        tanki: false,
        pinfu: false,
        round_wind: 0,
        player_wind: 0,
        mentsu: 'm11112345678999=!'
      }, result
    )
  end
end
