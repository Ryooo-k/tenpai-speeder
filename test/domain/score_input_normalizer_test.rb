# frozen_string_literal: true

require 'test_helper'

class ScoreInputNormalizerTest < ActiveSupport::TestCase
  test '#normalize_hands returns counts' do
    # m123 p456 s999 z111
    hands = [
      Hand.create!(tile: tiles(:first_manzu_1), player_state: player_states(:ryo)),
      Hand.create!(tile: tiles(:first_manzu_2), player_state: player_states(:ryo)),
      Hand.create!(tile: tiles(:first_manzu_3), player_state: player_states(:ryo)),
      Hand.create!(tile: tiles(:first_pinzu_4), player_state: player_states(:ryo)),
      Hand.create!(tile: tiles(:first_pinzu_5), player_state: player_states(:ryo)),
      Hand.create!(tile: tiles(:first_pinzu_6), player_state: player_states(:ryo)),
      Hand.create!(tile: tiles(:first_souzu_9), player_state: player_states(:ryo)),
      Hand.create!(tile: tiles(:second_souzu_9), player_state: player_states(:ryo)),
      Hand.create!(tile: tiles(:third_souzu_9), player_state: player_states(:ryo)),
      Hand.create!(tile: tiles(:first_ton), player_state: player_states(:ryo)),
      Hand.create!(tile: tiles(:second_ton), player_state: player_states(:ryo)),
      Hand.create!(tile: tiles(:third_ton), player_state: player_states(:ryo))
    ]

    result = ScoreInputNormalizer.normalize_hands(hands)
    expected = {
      m: [ 1, 1, 1, 0, 0, 0, 0, 0, 0 ],
      p: [ 0, 0, 0, 1, 1, 1, 0, 0, 0 ],
      s: [ 0, 0, 0, 0, 0, 0, 0, 0, 3 ],
      z: [ 3, 0, 0, 0, 0, 0, 0 ]
    }
    assert_equal expected, result
  end

  test '#normalize_melds converts :pon melds and applies relation marks (-/=/+)' do
    # m111 z111
    melds = [
      Meld.create!(tile: tiles(:first_manzu_1), player_state: player_states(:ryo), kind: :pon, position: 0, from: :shimocha),
      Meld.create!(tile: tiles(:second_manzu_1), player_state: player_states(:ryo), kind: :pon, position: 1),
      Meld.create!(tile: tiles(:third_manzu_1), player_state: player_states(:ryo), kind: :pon, position: 2),
      Meld.create!(tile: tiles(:first_ton), player_state: player_states(:ryo), kind: :pon, position: 0, from: :toimen),
      Meld.create!(tile: tiles(:second_ton), player_state: player_states(:ryo), kind: :pon, position: 1),
      Meld.create!(tile: tiles(:third_ton), player_state: player_states(:ryo), kind: :pon, position: 2)
    ]

    result = ScoreInputNormalizer.normalize_melds(melds)
    assert_equal [ 'm111-', 'z111=' ], result
  end

  test '#normalize_melds converts :chi melds and marks the taken tile position' do
    # m123 p123
    melds = [
      Meld.create!(tile: tiles(:first_manzu_1), player_state: player_states(:ryo), kind: :chi, position: 0, from: :kamicha),
      Meld.create!(tile: tiles(:first_manzu_2), player_state: player_states(:ryo), kind: :chi, position: 1),
      Meld.create!(tile: tiles(:first_manzu_3), player_state: player_states(:ryo), kind: :chi, position: 2),
      Meld.create!(tile: tiles(:first_pinzu_1), player_state: player_states(:ryo), kind: :chi, position: 1),
      Meld.create!(tile: tiles(:first_pinzu_2), player_state: player_states(:ryo), kind: :chi, position: 0, from: :kamicha),
      Meld.create!(tile: tiles(:first_pinzu_3), player_state: player_states(:ryo), kind: :chi, position: 2)
    ]

    result = ScoreInputNormalizer.normalize_melds(melds)
    assert_equal [ 'm1+23', 'p12+3' ], result
  end

  test '#normalize_melds handles :kakan by upgrading the pon to four' do
    # m111 z1111
    melds = [
      Meld.create!(tile: tiles(:first_manzu_1), player_state: player_states(:ryo), kind: :pon, position: 0, from: :shimocha),
      Meld.create!(tile: tiles(:second_manzu_1), player_state: player_states(:ryo), kind: :pon, position: 1),
      Meld.create!(tile: tiles(:third_manzu_1), player_state: player_states(:ryo), kind: :pon, position: 2),
      Meld.create!(tile: tiles(:first_ton), player_state: player_states(:ryo), kind: :pon, position: 0, from: :toimen),
      Meld.create!(tile: tiles(:second_ton), player_state: player_states(:ryo), kind: :pon, position: 1),
      Meld.create!(tile: tiles(:third_ton), player_state: player_states(:ryo), kind: :pon, position: 2),
      Meld.create!(tile: tiles(:fourth_ton), player_state: player_states(:ryo), kind: :kakan, position: 3)
    ]

    result = ScoreInputNormalizer.normalize_melds(melds)
    assert_equal [ 'm111-', 'z1111=' ], result
  end

  test '#normalize_melds formats :daiminkan' do
    melds = [
      Meld.create!(tile: tiles(:first_ton), player_state: player_states(:ryo), kind: :daiminkan, position: 0, from: :toimen),
      Meld.create!(tile: tiles(:second_ton), player_state: player_states(:ryo), kind: :daiminkan, position: 1),
      Meld.create!(tile: tiles(:third_ton), player_state: player_states(:ryo), kind: :daiminkan, position: 2),
      Meld.create!(tile: tiles(:fourth_ton), player_state: player_states(:ryo), kind: :daiminkan, position: 3)
    ]

    result = ScoreInputNormalizer.normalize_melds(melds)
    assert_equal [ 'z1111=' ], result
  end

  test '#normalize_melds formats :ankan' do
    # z1111
    melds = [
      Meld.create!(tile: tiles(:first_ton), player_state: player_states(:ryo), kind: :ankan, position: 0, from: :toimen),
      Meld.create!(tile: tiles(:second_ton), player_state: player_states(:ryo), kind: :ankan, position: 1),
      Meld.create!(tile: tiles(:third_ton), player_state: player_states(:ryo), kind: :ankan, position: 2),
      Meld.create!(tile: tiles(:fourth_ton), player_state: player_states(:ryo), kind: :ankan, position: 3)
    ]

    result = ScoreInputNormalizer.normalize_melds(melds)
    assert_equal [ 'z1111' ], result
  end

  test '#normalize_target returns "m1_" when manzu_1 (tsumo)' do
    result = ScoreInputNormalizer.normalize_target(tiles(:first_manzu_1), :self)
    assert_equal 'm1_', result
  end

  test '#normalize_target returns "p9-" when pinzu_9 (shimocha)' do
    result = ScoreInputNormalizer.normalize_target(tiles(:first_pinzu_9), :shimocha)
    assert_equal 'p9-', result
  end

  test '#normalize_target returns "s5=" when souzu_5 (toimen)' do
    result = ScoreInputNormalizer.normalize_target(tiles(:first_souzu_5), :toimen)
    assert_equal 's5=', result
  end

  test '#normalize_target returns "z7+" when zihai_7 (kamicha)' do
    result = ScoreInputNormalizer.normalize_target(tiles(:first_chun), :kamicha)
    assert_equal 'z7+', result
  end
end
