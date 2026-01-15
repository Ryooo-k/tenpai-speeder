# frozen_string_literal: true

# 麻雀ドメインの定数をまとめるためのモジュール。
# 必要なドメイン用の定数はこのモジュールに追加して他のクラスから参照させること。
module Mahjong
  module Constants
    TILES_PER_KIND = 4
    PLAYERS_COUNT = 4
    KAN_COUNT = 4
    KAN_REQUIRED_HAND_COUNT = 3
    PON_REQUIRED_HAND_COUNT = 2
    TILE_KIND_COUNT = 34
    NORMAL_AGARI_MENTSU_COUNT = 5
    CHIITOITSU_AGARI_MENTSU_COUNT = 7
    CHIITOITSU_PAIR_COUNT = 7
    FINAL_ROUND_NUMBER = 7
    INITIAL_HAND_SIZE = 13

    MAX_SHANTEN_COUNT = 13
    MAX_DRAW_COUNT = 122
    MAX_DORA_COUNT = 5
    MAX_KAN_COUNT = 4
    HAND_MAX_COUNT = 14

    WIND_NAMES = %w[東 南 西 北].freeze
    WIND_CODES = [ 27, 28, 29, 30 ].freeze
    TON_WIND_NUMBER = 0
    NAN_WIND_NUMBER = 1
    TON_TILE_CODE = 27

    RIICHI_BONUS = 1000
    HONBA_BONUS = 300
    TENPAI_POINT = {
      0 => 0,
      1 => 3000,
      2 => 1500,
      3 => 1000,
      4 => 0
    }.freeze
    DORA_CONVERSION_MPA = {
      8 => 0,
      17 => 9,
      26 => 18,
      30 => 27,
      33 => 31
    }.freeze

    RINSHAN_WALL = (122..125).to_a
    DORA_INDICATOR_ORDER_RANGE = (126..130)
    URADORA_INDICATOR_ORDER_RANGE = (131..135)
    AKA_DORA_TILE_CODES = [ 4, 13, 22 ].freeze # 5萬、5筒、5索の牌コード
    WAITING_TURN_HAND_COUNTS = [ 1, 4, 7, 10, 13 ].freeze
    KOKUSHI_TILE_CODES = [ 0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33 ].freeze
  end
end
