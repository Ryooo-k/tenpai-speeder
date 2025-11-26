# frozen_string_literal: true

module HandEvaluator
  HAND_MAX_COUNT = 14
  NORMAL_AGARI_MENTSU_COUNT     = 5
  CHIITOITSU_AGARI_MENTSU_COUNT = 7
  RON_RE = /[\-\+\=]\!/
  MELDS_RE  = /[-+=](?!!)/
  YAOCHU_RE = /[z19]/
  ZIHAI_RE  = /\Az/
  TANKI_MACHI_RE      = /\A[mpsz](\d)\1[\-\+\=\_]\!\z/
  SANGEN_RE           = /\Az[567].*\z/
  KOTSU_OR_KANTSU_RE  = /\A[mpsz](\d)\1\1.*\z/
  ANKO_OR_ANKAN_RE = /\A[mpsz](\d)\1\1(?:\1|_\!)?\z/
  KANTSU_RE        = /\A[mpsz](\d)\1\1.*\1.*\z/
  KANCHAN_MACHI_RE = /\A[mps]\d\d[\-\+\=\_]\!\d\z/
  PENCHAN_MACHI_RE = /\A[mps](123[\-\+\=\_]\!|7[\-\+\=\_]\!89)\z/
  DRAGON_RE = /\Az[567]/
  SUUHAI_SUIT_RE = /[mps]/
  WINDS = %w[東 南 西 北]
  SUUHAI_SUITS = %w[m p s]
  MANZU_SUIT = 'm'
  PINZU_SUIT = 'p'
  SOUZU_SUIT = 's'
  ZIHAI_SUIT = 'z'
  AGARI_DISTANCE_MAP = JSON.parse(Rails.root.join('app/domain', 'agari_distance_map.json').read).freeze
  CHIITOITSU_PAIR_COUNT = 7
  KOKUSHI_TILE_CODES = [ 0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33 ].freeze
  MAX_SHANTEN_COUNT = 13
  MAX_RIICHI_CANDIDATE_COUNT = 2

  # 通常手の向聴数を計算するのに使用するリスト
  # [ manzu, pinzu, souzu, zihai ] の和了枚数テーブル
  NORMAL_AGARI_PATTERNS = [
    [ 0, 0, 0, 14 ],
    [ 0, 0, 2, 12 ],
    [ 0, 0, 3, 11 ],
    [ 0, 0, 5, 9 ],
    [ 0, 0, 6, 8 ],
    [ 0, 0, 8, 6 ],
    [ 0, 0, 9, 5 ],
    [ 0, 0, 11, 3 ],
    [ 0, 0, 12, 2 ],
    [ 0, 0, 14, 0 ],
    [ 0, 2, 0, 12 ],
    [ 0, 2, 3, 9 ],
    [ 0, 2, 6, 6 ],
    [ 0, 2, 9, 3 ],
    [ 0, 2, 12, 0 ],
    [ 0, 3, 0, 11 ],
    [ 0, 3, 2, 9 ],
    [ 0, 3, 3, 8 ],
    [ 0, 3, 5, 6 ],
    [ 0, 3, 6, 5 ],
    [ 0, 3, 8, 3 ],
    [ 0, 3, 9, 2 ],
    [ 0, 3, 11, 0 ],
    [ 0, 5, 0, 9 ],
    [ 0, 5, 3, 6 ],
    [ 0, 5, 6, 3 ],
    [ 0, 5, 9, 0 ],
    [ 0, 6, 0, 8 ],
    [ 0, 6, 2, 6 ],
    [ 0, 6, 3, 5 ],
    [ 0, 6, 5, 3 ],
    [ 0, 6, 6, 2 ],
    [ 0, 6, 8, 0 ],
    [ 0, 8, 0, 6 ],
    [ 0, 8, 3, 3 ],
    [ 0, 8, 6, 0 ],
    [ 0, 9, 0, 5 ],
    [ 0, 9, 2, 3 ],
    [ 0, 9, 3, 2 ],
    [ 0, 9, 5, 0 ],
    [ 0, 11, 0, 3 ],
    [ 0, 11, 3, 0 ],
    [ 0, 12, 0, 2 ],
    [ 0, 12, 2, 0 ],
    [ 0, 14, 0, 0 ],
    [ 2, 0, 0, 12 ],
    [ 2, 0, 3, 9 ],
    [ 2, 0, 6, 6 ],
    [ 2, 0, 9, 3 ],
    [ 2, 0, 12, 0 ],
    [ 2, 3, 0, 9 ],
    [ 2, 3, 3, 6 ],
    [ 2, 3, 6, 3 ],
    [ 2, 3, 9, 0 ],
    [ 2, 6, 0, 6 ],
    [ 2, 6, 3, 3 ],
    [ 2, 6, 6, 0 ],
    [ 2, 9, 0, 3 ],
    [ 2, 9, 3, 0 ],
    [ 2, 12, 0, 0 ],
    [ 3, 0, 0, 11 ],
    [ 3, 0, 2, 9 ],
    [ 3, 0, 3, 8 ],
    [ 3, 0, 5, 6 ],
    [ 3, 0, 6, 5 ],
    [ 3, 0, 8, 3 ],
    [ 3, 0, 9, 2 ],
    [ 3, 0, 11, 0 ],
    [ 3, 2, 0, 9 ],
    [ 3, 2, 3, 6 ],
    [ 3, 2, 6, 3 ],
    [ 3, 2, 9, 0 ],
    [ 3, 3, 0, 8 ],
    [ 3, 3, 2, 6 ],
    [ 3, 3, 3, 5 ],
    [ 3, 3, 5, 3 ],
    [ 3, 3, 6, 2 ],
    [ 3, 3, 8, 0 ],
    [ 3, 5, 0, 6 ],
    [ 3, 5, 3, 3 ],
    [ 3, 5, 6, 0 ],
    [ 3, 6, 0, 5 ],
    [ 3, 6, 2, 3 ],
    [ 3, 6, 3, 2 ],
    [ 3, 6, 5, 0 ],
    [ 3, 8, 0, 3 ],
    [ 3, 8, 3, 0 ],
    [ 3, 9, 0, 2 ],
    [ 3, 9, 2, 0 ],
    [ 3, 11, 0, 0 ],
    [ 5, 0, 0, 9 ],
    [ 5, 0, 3, 6 ],
    [ 5, 0, 6, 3 ],
    [ 5, 0, 9, 0 ],
    [ 5, 3, 0, 6 ],
    [ 5, 3, 3, 3 ],
    [ 5, 3, 6, 0 ],
    [ 5, 6, 0, 3 ],
    [ 5, 6, 3, 0 ],
    [ 5, 9, 0, 0 ],
    [ 6, 0, 0, 8 ],
    [ 6, 0, 2, 6 ],
    [ 6, 0, 3, 5 ],
    [ 6, 0, 5, 3 ],
    [ 6, 0, 6, 2 ],
    [ 6, 0, 8, 0 ],
    [ 6, 2, 0, 6 ],
    [ 6, 2, 3, 3 ],
    [ 6, 2, 6, 0 ],
    [ 6, 3, 0, 5 ],
    [ 6, 3, 2, 3 ],
    [ 6, 3, 3, 2 ],
    [ 6, 3, 5, 0 ],
    [ 6, 5, 0, 3 ],
    [ 6, 5, 3, 0 ],
    [ 6, 6, 0, 2 ],
    [ 6, 6, 2, 0 ],
    [ 6, 8, 0, 0 ],
    [ 8, 0, 0, 6 ],
    [ 8, 0, 3, 3 ],
    [ 8, 0, 6, 0 ],
    [ 8, 3, 0, 3 ],
    [ 8, 3, 3, 0 ],
    [ 8, 6, 0, 0 ],
    [ 9, 0, 0, 5 ],
    [ 9, 0, 2, 3 ],
    [ 9, 0, 3, 2 ],
    [ 9, 0, 5, 0 ],
    [ 9, 2, 0, 3 ],
    [ 9, 2, 3, 0 ],
    [ 9, 3, 0, 2 ],
    [ 9, 3, 2, 0 ],
    [ 9, 5, 0, 0 ],
    [ 11, 0, 0, 3 ],
    [ 11, 0, 3, 0 ],
    [ 11, 3, 0, 0 ],
    [ 12, 0, 0, 2 ],
    [ 12, 0, 2, 0 ],
    [ 12, 2, 0, 0 ],
    [ 14, 0, 0, 0 ]
  ].freeze

  class << self
    def can_tsumo?(hands, melds, round_wind, player_wind, situational_yaku_list)
      drawn_hand = hands.find { |hand| hand.drawn? }
      return false unless drawn_hand
      return true if situational_yaku_list.any? { |_, v|  v }

      normalized_hands, normalized_melds, normalized_drawn_tile = ScoreInputNormalizer.normalize(hands, melds, drawn_hand, :self)
      agari_all_patterns = build_agari_all_patters(normalized_hands, normalized_melds, normalized_drawn_tile)
      return true if agari_all_patterns.present? && normalized_melds.empty?

      scoring_state_table = agari_all_patterns.map { |agari_patterns| build_scoring_states(agari_patterns, round_wind, player_wind) }
      yaku_list = scoring_state_table.map { |scoring_states| build_yaku_list(scoring_states, situational_yaku_list) }.flatten
      yaku_list.present?
    end

    def can_ron?(hands, melds, target, relation, round_wind, player_wind, situational_yaku_list)
      test_hands = Array(hands) + [ target ]
      shanten = calculate_shanten(test_hands, melds)
      return true if situational_yaku_list[:houtei] || situational_yaku_list[:chankan] || (situational_yaku_list[:riichi] && shanten.negative?)

      normalized_hands, normalized_melds, normalized_target_tile = ScoreInputNormalizer.normalize(test_hands, melds, target, relation)
      agari_all_patterns = build_agari_all_patters(normalized_hands, normalized_melds, normalized_target_tile)
      scoring_state_table = agari_all_patterns.map { |agari_patterns| build_scoring_states(agari_patterns, round_wind, player_wind) }
      yaku_list = scoring_state_table.map { |scoring_states| build_yaku_list(scoring_states, situational_yaku_list) }.flatten
      yaku_list.present?
    end

    def get_score_statements(hands, melds, agari_tile, relation, round_wind, player_wind, situational_yaku_list)
      normalized_hands, normalized_melds, normalized_agari_tile = ScoreInputNormalizer.normalize(hands, melds, agari_tile, relation)
      agari_all_patterns = build_agari_all_patters(normalized_hands, normalized_melds, normalized_agari_tile)
      scoring_state_table = agari_all_patterns.map { |agari_patterns| build_scoring_states(agari_patterns, round_wind, player_wind) }
      all_score_statements = scoring_state_table.map do |scoring_states|
        yaku_list = build_yaku_list(scoring_states, situational_yaku_list)
        han_total = yaku_list.empty? ? 0 : yaku_list.sum { |yaku| yaku[:han].to_i }

        {
          tsumo: scoring_states[:tsumo],
          fu_total: scoring_states[:fu_total],
          fu_components: scoring_states[:fu_components],
          han_total:,
          yaku_list:
        }
      end
      all_score_statements.max_by { |score_summary| score_summary[:han_total] }
    end

    def calculate_shanten(hands, melds)
      compact_melds = melds.select { |meld| meld.position != 3 }
      normal_shanten = calculate_normal_shanten(hands, compact_melds)
      chiitoitsu_shanten = calculate_chiitoitsu_shanten(hands, compact_melds)
      kokushi_shanten = calculate_kokushi_shanten(hands, compact_melds)
      [ normal_shanten, chiitoitsu_shanten, kokushi_shanten ].min
    end

    def find_riichi_candidates(hands, melds)
      hands.select do |hand|
        test_hands = hands - [ hand ]
        shanten = calculate_shanten(test_hands, melds)
        shanten.zero?
      end
    end

    def find_outs(hands, melds, tiles, shanten)
      normal_outs = find_normal_outs(hands, melds, tiles, shanten)
      chiitoitsu_outs = find_chiitoitsu_outs(hands, melds, tiles)
      kokushi_outs = find_kokushi_outs(hands, melds, tiles)

      {
        normal: normal_outs,
        chiitoitsu: chiitoitsu_outs,
        kokushi: kokushi_outs
      }
    end

    def find_normal_outs(hands, melds, tiles, shanten)
      hand_and_meld_tiles = hands.map { |hand| hand.tile } + melds.map { |meld| meld.tile }

      tiles.select do |tile|
        next if hand_and_meld_tiles.include?(tile)

        test_hands = hands + [ tile ]
        new_shanten = calculate_shanten(test_hands, melds)
        new_shanten < shanten
      end.sort_by(&:code)
    end

    def find_wining_tiles(hands, melds, tiles)
      hand_and_meld_tiles = hands.map { |hand| hand.tile } + melds.map { |meld| meld.tile }

      tiles.select do |tile|
        next if hand_and_meld_tiles.include?(tile)

        test_hands = hands + [ tile ]
        shanten = calculate_shanten(test_hands, melds)
        shanten.negative?
      end.sort_by(&:code)
    end
  end

  private

    # privateメソッドを個別にテストするため、selfを付与
    class << self
      # suit: スートを表す文字列（例: 萬子："m", 筒子："p", 索子："s", 字牌："z"）
      # counts: 各面子候補の枚数カウント配列（0始まりで1〜9をi=0..8に対応）
      # i: 現在チェック中のインデックス（0〜8）
      def build_agari_mentsu(suit, counts, i)
        return [ [] ] if i == 9
        return build_agari_mentsu(suit, counts, i + 1) if counts[i].zero?

        shuntsu_list = []
        if suit != ZIHAI_SUIT && i < 7 && counts[i] > 0 && counts[i + 1] > 0 && counts[i + 2] > 0
          counts[i] -= 1
          counts[i + 1] -= 1
          counts[i + 2] -= 1
          shuntsu_list = build_agari_mentsu(suit, counts, i)

          # countsを元に戻す（バックトラック）
          counts[i] += 1
          counts[i + 1] += 1
          counts[i + 2] += 1

          shuntsu_list.each { |melds| melds.unshift("#{suit}#{i + 1}#{i + 2}#{i + 3}") }
        end

        kotsu_list = []
        if counts[i] >= 3
          counts[i] -= 3
          kotsu_list = build_agari_mentsu(suit, counts, i)

          # countsを元に戻す（バックトラック）
          counts[i] += 3

          kotsu_list.each { |melds| melds.unshift("#{suit}#{i + 1}#{i + 1}#{i + 1}") }
        end

        shuntsu_list + kotsu_list
      end

      def build_agari_mentsu_all(hands, melds)
        agari_mentsu_list = [ [] ]

        SUUHAI_SUITS.each do |suit|
          counts = hands[suit.to_sym]
          suuhai_agari_mentsu = build_agari_mentsu(suit, counts, 0)

          new_agari_mentsu = []
          agari_mentsu_list.each do |m|
            suuhai_agari_mentsu.each do |n|
              new_agari_mentsu << (m + n)
            end
          end
          agari_mentsu_list = new_agari_mentsu
        end

        zihai_counts = hands[ZIHAI_SUIT.to_sym]
        zihai_agari_mentsu = []
        (1..7).each do |n|
          count = zihai_counts[n - 1]
          next if count == 0
          return [] if count != 3
          zihai_agari_mentsu << "#{ZIHAI_SUIT}#{n}#{n}#{n}"
        end

        agari_mentsu_list.map { |mentsu| mentsu + zihai_agari_mentsu + melds }
      end

      def add_agari_mark(mentsu_list, agari_tile)
        suit   = agari_tile[0]
        second = agari_tile[1]
        tail   = agari_tile[2..] || ''
        regexp = /\A(#{Regexp.escape(suit)}.*#{Regexp.escape(second)})/

        results = []
        agari_mark = '!'
        mentsu_list.each_with_index do |mentsu, i|
          next if mentsu.match?(/[-+=]/)                # 副露表記はスキップ
          next if i > 0 && mentsu == mentsu_list[i - 1] # 連続重複の抑止

          replaced = mentsu.sub(regexp) { |head| "#{head}#{tail}#{agari_mark}" }
          next if replaced == mentsu

          new_mentsu_list = mentsu_list.dup
          new_mentsu_list[i] = replaced
          results << new_mentsu_list
        end

        results
      end

      def build_normal_agari_patterns(hands, melds, agari_tile)
        results = []

        hands.each do |suit, counts|
          (1..counts.length).each do |number|
            index = number - 1
            next if counts[index] < 2

            jantou = "#{suit}#{number}#{number}"
            counts[index] -= 2

            agari_mentsu_list = build_agari_mentsu_all(hands, melds)
            agari_mentsu_list.each do |mentsu_comb|
              with_head = [ jantou, *mentsu_comb ]
              with_agari_mark = add_agari_mark(with_head, agari_tile)
              with_agari_mark.each { |variant| results << variant }
            end

            counts[index] += 2 # バックトラック
          end
        end

        results
      end

      def build_chiitoitsu_agari_patterns(hands, agari_tile)
        return [] if hands.values.flatten.sum != HAND_MAX_COUNT
        return [] unless hands.values.flatten.all? { |count| count == 2 || count.zero? }

        pairs = []
        core = agari_tile[..1]
        mark = agari_tile[2]
        agari_mark = '!'

        hands.each do |suit, counts|
          counts.each_with_index do |count, i|
            next if count == 0

            number = i + 1
            target_tile = "#{suit}#{number}"
            pair = target_tile == core ? "#{target_tile}#{number}#{mark}#{agari_mark}" : "#{target_tile}#{number}"
            pairs << pair
          end
        end

        [ pairs ]
      end

      def build_kokushi_agari_patterns(hands, agari_tile)
        return [] if hands.values.flatten.sum != HAND_MAX_COUNT

        result = []
        core = agari_tile[..1]
        mark = agari_tile[2]
        agari_mark = '!'

        hands.each do |suit, counts|
          target_numbers = (suit.to_s == ZIHAI_SUIT) ? (1..7).to_a : [ 1, 9 ]

          target_numbers.each do |number|
            count = counts[number - 1]
            target_tile = "#{suit}#{number}"

            if count == 2
              piece = target_tile == core ? "#{target_tile}#{number}#{mark}#{agari_mark}" : "#{target_tile}#{number}"
              result.unshift(piece)
            elsif count == 1
              piece = target_tile == core ? "#{target_tile}#{mark}#{agari_mark}" : target_tile
              result << piece
            else
              return []
            end
          end
        end

        [ result ]
      end

      def build_chuurenpoutou_agari_patterns(hands, agari_tile)
        suit, hand_counts = hands.find { |_, values| values.sum == 14 }
        return [] unless suit && hand_counts
        mentsu = suit.to_s.dup

        9.times do |index|
          count = hand_counts[index]
          number = index + 1

          return [] if (number == 1 || number == 9) && count < 3
          return [] if count == 0

          possession_count = (number == agari_tile[1].to_i) ? (count - 1) : count
          mentsu << (number.to_s * possession_count)
        end

        mentsu << agari_tile[1..] << '!'
        [ [ mentsu ] ]
      end

      def build_agari_all_patters(hands, melds, agari_tile)
        normal_agari_patterns = build_normal_agari_patterns(hands, melds, agari_tile)
        chiitoitsu_agari_patterns = build_chiitoitsu_agari_patterns(hands, agari_tile)
        kokushi_agari_patterns = build_kokushi_agari_patterns(hands, agari_tile)
        chuurenpoutou_agari_patterns = build_chuurenpoutou_agari_patterns(hands, agari_tile)
        normal_agari_patterns + chiitoitsu_agari_patterns + kokushi_agari_patterns + chuurenpoutou_agari_patterns
      end

      def build_bonus_yaku_list(situational_yaku_list)
        if situational_yaku_list[:tenhou]
          return [ { name: '天和', han: 13 } ]
        elsif situational_yaku_list[:chiihou]
          return [ { name: '地和', han: 13 } ]
        end

        bonus_yaku_list = []
        bonus_yaku_list << { name: '立直',      han: 1 } if situational_yaku_list[:riichi] && !situational_yaku_list[:double_riichi]
        bonus_yaku_list << { name: 'ダブル立直', han: 2 } if situational_yaku_list[:double_riichi]
        bonus_yaku_list << { name: '一発',      han: 1 } if situational_yaku_list[:ippatsu]
        bonus_yaku_list << { name: '海底摸月',  han: 1 } if situational_yaku_list[:haitei]
        bonus_yaku_list << { name: '河底撈魚',  han: 1 } if situational_yaku_list[:houtei]
        bonus_yaku_list << { name: '嶺上開花',  han: 1 } if situational_yaku_list[:rinshan]
        bonus_yaku_list << { name: '槍槓',      han: 1 } if situational_yaku_list[:chankan]
        bonus_yaku_list
      end

      def build_dora_yaku_list(dora_count, ura_dora_count, aka_dora_count)
        dora_yaku_list = []
        dora_yaku_list << { name: 'ドラ',  han: dora_count } if dora_count.positive?
        dora_yaku_list << { name: '赤ドラ', han: aka_dora_count } if aka_dora_count.positive?
        dora_yaku_list << { name: '裏ドラ', han: ura_dora_count } if ura_dora_count.positive?
        dora_yaku_list
      end

      def build_scoring_states(agari_patterns, round_wind, player_wind)
        round_wind_re  = /\Az#{round_wind + 1}.*\z/
        player_wind_re = /\Az#{player_wind + 1}.*\z/
        scoring_states = build_initial_scoring_state(round_wind, player_wind)
        scoring_states[:jantou] = agari_patterns[0]
        scoring_states[:mentsu] = agari_patterns.join
        scoring_states[:mentsu_count] = agari_patterns.length

        agari_patterns.each do |mentsu|
          scoring_states[:tsumo] &&= !mentsu.match?(RON_RE)
          scoring_states[:menzen] &&= !mentsu.match?(MELDS_RE)
          scoring_states[:tanki] ||= mentsu.match?(TANKI_MACHI_RE)
          scoring_states[:yaochu_count] += 1 if mentsu.match?(YAOCHU_RE)
          scoring_states[:zihai_count]  += 1 if mentsu.match?(ZIHAI_RE)

          next if agari_patterns.length != NORMAL_AGARI_MENTSU_COUNT

          if mentsu == scoring_states[:jantou]
            scoring_states[:fu_components][:jantou] += 2 if mentsu.match?(round_wind_re) || mentsu.match?(player_wind_re)
            scoring_states[:fu_components][:jantou] += 2 if mentsu.match?(SANGEN_RE)
            scoring_states[:fu_components][:tanki] += 2 if scoring_states[:tanki]
          elsif mentsu.match(KOTSU_OR_KANTSU_RE)
            scoring_states[:kotsu_or_kantsu_count] += 1
            fu = mentsu.match?(YAOCHU_RE) ? 4 : 2

            if mentsu.match?(ANKO_OR_ANKAN_RE)
              fu *= 2
              scoring_states[:anko_or_ankan_count] += 1
            end

            if mentsu.match?(KANTSU_RE)
              fu *= 4
              scoring_states[:kantsu_count] += 1
            end
            scoring_states[:fu_components][:kotsu_or_kantsu] += fu

            suit = mentsu[0]
            number_index = mentsu[1].to_i - 1
            scoring_states[:kotsu][suit.to_sym][number_index] = 1
          else # 順子
            scoring_states[:shuntsu_count] += 1
            scoring_states[:fu_components][:kanchan] += 2 if mentsu.match?(KANCHAN_MACHI_RE)
            scoring_states[:fu_components][:penchan] += 2 if mentsu.match?(PENCHAN_MACHI_RE)

            # 順子の構成を記録（"123" などの数字列をキーにカウント）
            suit = mentsu[0]
            mentsu_number = mentsu.gsub(/[^\d]/, '')
            scoring_states[:shuntsu][suit.to_sym][mentsu_number] = scoring_states[:shuntsu][suit.to_sym].fetch(mentsu_number, 0) + 1
          end
        end

        if scoring_states[:mentsu_count] == CHIITOITSU_AGARI_MENTSU_COUNT
          scoring_states[:fu_components][:standard] = 25
          scoring_states[:fu_components][:tanki] = 0
          scoring_states[:fu_raw]   = 25
          scoring_states[:fu_total] = 25
        elsif scoring_states[:mentsu_count] == 5
          # 平和判定：門前かつ20符
          scoring_states[:pinfu] = (scoring_states[:menzen] && scoring_states[:fu_components].values.sum == 20)

          if scoring_states[:tsumo]
            scoring_states[:fu_components][:tsumo] += 2 unless scoring_states[:pinfu]
          else
            if scoring_states[:menzen]
              scoring_states[:fu_components][:menzen] += 10
            elsif scoring_states[:fu_components].values.sum == 20
              # 喰い平和は30符固定
              scoring_states[:fu_components][:standard] = 30
            end
          end

          scoring_states[:fu_raw] = scoring_states[:fu_components].values.sum
          scoring_states[:fu_total] = scoring_states[:fu_raw].ceil(-1)
        end

        scoring_states
      end

      def build_initial_scoring_state(round_wind, player_wind)
        {
          fu_total: 0,
          fu_raw: 0,
          fu_components: {
            standard: 20,
            jantou: 0,
            tanki: 0,
            kanchan: 0,
            penchan: 0,
            tsumo: 0,
            menzen: 0,
            kotsu_or_kantsu: 0
          },
          shuntsu: { m: {}, p: {}, s: {} },
          kotsu: {
            m: Array.new(9, 0), p: Array.new(9, 0), s: Array.new(9, 0),
            z: Array.new(7, 0)
          },
          jantou: '',
          shuntsu_count: 0,
          kotsu_or_kantsu_count: 0,
          anko_or_ankan_count: 0,
          kantsu_count: 0,
          zihai_count: 0,
          yaochu_count: 0,
          mentsu_count: 0,
          menzen: true,
          tsumo: true,
          tanki: false,
          pinfu: false,
          round_wind:, # 0: 東、1: 南、2: 西、3: 北
          player_wind:, # 0: 東、1: 南、2: 西、3: 北
          mentsu: ''
        }
      end

      def build_menzen_tsumo_yaku(state)
        state[:menzen] && state[:tsumo] ? { name: '門前清自摸和', han: 1 } : []
      end

      def build_fanpai_yaku(state)
        result = []
        round_wind_index = state[:round_wind]
        player_wind_index = state[:player_wind]
        zihai_kotsu = state[:kotsu][:z]

        result << { name: "場風 #{WINDS[round_wind_index]}", han: 1 } if !zihai_kotsu[round_wind_index].to_i.zero?
        result << { name: "自風 #{WINDS[player_wind_index]}", han: 1 } if !zihai_kotsu[player_wind_index].to_i.zero?
        result << { name: '翻牌 白', han: 1 } if !zihai_kotsu[4].to_i.zero?
        result << { name: '翻牌 發', han: 1 } if !zihai_kotsu[5].to_i.zero?
        result << { name: '翻牌 中', han: 1 } if !zihai_kotsu[6].to_i.zero?
        result
      end

      def build_pinfu_yaku(state)
        state[:pinfu] ? { name: '平和', han: 1 } : []
      end

      def build_tanyao_yaku(state)
        state[:yaochu_count].zero? ? { name: '断幺九', han: 1 } : []
      end

      def build_iipeikou_yaku(state)
        return [] unless state[:menzen]
        return [] if state[:shuntsu].empty?

        pair = 0
        SUUHAI_SUITS.each do |suit|
          next if state[:shuntsu][suit.to_sym].empty?
          state[:shuntsu][suit.to_sym].each_value do |count|
            pair += 1 if count > 3   # 同じ順子が4枚以上なら “2組” と数えるため+1
            pair += 1 if count > 1   # 同じ順子が2枚以上で1組
          end
        end

        pair == 1 ? { name: '一盃口', han: 1 } : []
      end

      def build_sanshoku_doujun_yaku(state)
        syuntsu = state[:shuntsu]
        syuntsu[:m].each_key do |sequence|
          if syuntsu[:m][sequence].to_i > 0 && syuntsu[:p][sequence].to_i > 0 && syuntsu[:s][sequence].to_i > 0
            han = state[:menzen] ? 2 : 1
            return { name: '三色同順', han: }
          end
        end
        []
      end

      def build_ikkitsuukan_yaku(state)
        SUUHAI_SUITS.each do |suit|
          next if state[:shuntsu][suit.to_sym].empty?

          has_123 = state[:shuntsu][suit.to_sym]['123'].to_i > 0
          has_456 = state[:shuntsu][suit.to_sym]['456'].to_i > 0
          has_789 = state[:shuntsu][suit.to_sym]['789'].to_i > 0

          if has_123 && has_456 && has_789
            han = state[:menzen] ? 2 : 1
            return { name: '一気通貫', han: }
          end
        end
        []
      end

      def build_chanta_yaku(state)
        yaochu_blocks = state[:yaochu_count] || state[:n_yaojiu] || 0
        shunzi_count  = state[:shuntsu_count] || state[:n_shunzi] || 0
        zihai_count   = state[:zihai_count] || state[:n_zipai] || 0
        menzen        = state[:menzen] || state[:menqian]

        if state[:yaochu_count] == 5 && state[:shuntsu_count].positive? && state[:zihai_count].positive?
          han = state[:menzen] ? 2 : 1
          { name: '混全帯幺九', han: }
        else
          []
        end
      end

      def build_chiitoitsu_yaku(state)
        state[:mentsu_count] == 7 ? { name: '七対子', han: 2 } : []
      end

      def build_toitoi_yaku(state)
        state[:kotsu_or_kantsu_count] == 4 ? { name: '対々和', han: 2 } : []
      end

      def build_sanankou_yaku(state)
        state[:anko_or_ankan_count] == 3 ? { name: '三暗刻', han: 2 } : []
      end

      def build_sankantsu_yaku(state)
        state[:kantsu_count] == 3 ? { name: '三槓子', han: 2 } : []
      end

      def build_sanshoku_dokou_yaku(state)
        kotsu = state[:kotsu]
        9.times do |i|
          return { name: '三色同刻', han: 2 } if kotsu[:m][i].to_i + kotsu[:p][i].to_i + kotsu[:s][i].to_i == 3
        end
        []
      end

      def build_honroutou_yaku(state)
        if state[:yaochu_count] == state[:mentsu_count] && state[:shuntsu_count].zero? && state[:zihai_count].positive?
          { name: '混老頭', han: 2 }
        else
          []
        end
      end

      def build_shosangen_yaku(state)
        kotsu = state[:kotsu]
        dragons_triplets =
          kotsu[:z][4].to_i +  # z5: 白
          kotsu[:z][5].to_i +  # z6: 發
          kotsu[:z][6].to_i    # z7: 中
        head_is_dragon = state[:jantou].match?(DRAGON_RE)

        if dragons_triplets == 2 && head_is_dragon
          { name: '小三元', han: 2 }
        else
          []
        end
      end

      def build_honitsu_yaku(state)
        used_zihai = (state[:zihai_count] > 0) || state[:jantou].start_with?(ZIHAI_SUIT)
        suits = state[:mentsu].scan(SUUHAI_SUIT_RE).uniq

        if suits.size == 1 && used_zihai
          han = state[:menzen] ? 3 : 2
          { name: '混一色', han: }
        else
          []
        end
      end

      def build_zyunchan_yaku(state)
        if state[:yaochu_count] == 5 && state[:shuntsu_count].positive? && state[:zihai_count].zero?
          han = han = state[:menzen] ? 3 : 2
          { name: '純全帯幺九', han: }
        else
          []
        end
      end

      def build_ryanpeikou_yaku(state)
        return [] unless state[:menzen]
        total_shuntsu = SUUHAI_SUITS.sum { |s| state[:shuntsu][s.to_sym].values.sum }
        return [] if total_shuntsu != 4

        pairs = SUUHAI_SUITS.sum do |suit|
          state[:shuntsu][suit.to_sym].values.sum { |count| count / 2 }
        end

        pairs == 2 ? { name: '二盃口', han: 3 } : []
      end

      def build_chinitsu_yaku(state)
        used_zihai = (state[:zihai_count] > 0) || state[:jantou].start_with?(ZIHAI_SUIT)
        suits = state[:mentsu].scan(SUUHAI_SUIT_RE).uniq

        if suits.size == 1 && !used_zihai
          han = state[:menzen] ? 6 : 5
          { name: '清一色', han: }
        else
          []
        end
      end

      def build_kokushi_yaku(state)
        return [] if state[:mentsu_count] != 13

        if state[:tanki]
          { name: '国士無双十三面', han: 13 }
        else
          { name: '国士無双', han: 13 }
        end
      end

      def build_suuankou_yaku(state)
        return [] if state[:anko_or_ankan_count] != 4

        if state[:tanki]
          { name: '四暗刻単騎', han: 13 }
        else
          { name: '四暗刻', han: 13 }
        end
      end

      def build_daisangen_yaku(state)
        dragons_triplets = state[:kotsu][:z][4].to_i + state[:kotsu][:z][5].to_i + state[:kotsu][:z][6].to_i
        return [] if dragons_triplets != 3
        { name: '大三元', han: 13 }
      end

      def build_shousuushi_yaku(state)
        z_kotsu = state[:kotsu][:z]
        winds_triplets = z_kotsu[0].to_i + z_kotsu[1].to_i + z_kotsu[2].to_i + z_kotsu[3].to_i

        if winds_triplets == 4
          { name: '大四喜', han: 13 }
        elsif winds_triplets == 3 && state[:jantou].start_with?(ZIHAI_SUIT)
          { name: '小四喜', han: 13 }
        else
          []
        end
      end

      def build_tsuuiisou_yaku(state)
        state[:zihai_count] == state[:mentsu_count] ? { name: '字一色', han: 13 } : []
      end

      def build_ryuuiisou_yaku(state)
        return [] if state[:mentsu].match?(/[mp]/)
        return [] if state[:mentsu].match?(/z[^6]/)
        return [] if state[:mentsu].match?(/s.*[1579]/)
        [ { name: '緑一色', han: 13 } ]
      end

      def build_chinroutou_yaku(state)
        if state[:kotsu_or_kantsu_count] == 4 && state[:yaochu_count] == 5 && state[:zihai_count].zero?
          { name: '清老頭', han: 13 }
        else
          []
        end
      end

      def build_suukantsu_yaku(state)
        state[:kantsu_count] == 4 ? { name: '四槓子', han: 13 } : []
      end

      def build_chuurenpoutou_yaku(state)
        return [] if state[:mentsu_count] != 1
        { name: '九蓮宝燈', han: 13 }
      end

      def build_yaku_list(scoring_states, situational_yaku_list)
        bonus_yaku_list = build_bonus_yaku_list(situational_yaku_list)
        yakuman_list = situational_yaku_list[:tenhou] || situational_yaku_list[:chiihou] ? bonus_yaku_list : []
        yakuman_list << build_kokushi_yaku(scoring_states)
        yakuman_list << build_suuankou_yaku(scoring_states)
        yakuman_list << build_daisangen_yaku(scoring_states)
        yakuman_list << build_shousuushi_yaku(scoring_states)
        yakuman_list << build_tsuuiisou_yaku(scoring_states)
        yakuman_list << build_ryuuiisou_yaku(scoring_states)
        yakuman_list << build_chinroutou_yaku(scoring_states)
        yakuman_list << build_suukantsu_yaku(scoring_states)
        yakuman_list << build_chuurenpoutou_yaku(scoring_states)
        flattened_yakuman_list = yakuman_list.flatten
        return flattened_yakuman_list if flattened_yakuman_list.present?

        yaku_list = []
        yaku_list << bonus_yaku_list
        yaku_list << build_menzen_tsumo_yaku(scoring_states)
        yaku_list << build_fanpai_yaku(scoring_states)
        yaku_list << build_pinfu_yaku(scoring_states)
        yaku_list << build_tanyao_yaku(scoring_states)
        yaku_list << build_iipeikou_yaku(scoring_states)
        yaku_list << build_sanshoku_doujun_yaku(scoring_states)
        yaku_list << build_ikkitsuukan_yaku(scoring_states)
        yaku_list << build_chanta_yaku(scoring_states)
        yaku_list << build_chiitoitsu_yaku(scoring_states)
        yaku_list << build_toitoi_yaku(scoring_states)
        yaku_list << build_sanankou_yaku(scoring_states)
        yaku_list << build_sankantsu_yaku(scoring_states)
        yaku_list << build_sanshoku_dokou_yaku(scoring_states)
        yaku_list << build_honroutou_yaku(scoring_states)
        yaku_list << build_shosangen_yaku(scoring_states)
        yaku_list << build_honitsu_yaku(scoring_states)
        yaku_list << build_zyunchan_yaku(scoring_states)
        yaku_list << build_ryanpeikou_yaku(scoring_states)
        yaku_list << build_chinitsu_yaku(scoring_states)
        yaku_list.flatten
      end

      def calculate_normal_shanten(hands, melds)
        manzu_code, pinzu_code, souzu_code, zihai_code = ShantenInputNormalizer.normalize(hands, melds)

        min_distance = Float::INFINITY
        NORMAL_AGARI_PATTERNS.each do |m_pattern, p_pattern, s_pattern, z_pattern|
          distance =
            AGARI_DISTANCE_MAP['suuhai'][manzu_code][m_pattern.to_s] +
            AGARI_DISTANCE_MAP['suuhai'][pinzu_code][p_pattern.to_s] +
            AGARI_DISTANCE_MAP['suuhai'][souzu_code][s_pattern.to_s] +
            AGARI_DISTANCE_MAP['zihai'][zihai_code][z_pattern.to_s]
          min_distance = distance if distance < min_distance
        end
        min_distance - 1
      end

      def calculate_chiitoitsu_shanten(hands, melds)
        return 7 if melds.present?
        code_counts = hands.map(&:code).tally
        pair_count = 0
        code_counts.each_value { |count| pair_count += 1 if count == 2 }
        CHIITOITSU_PAIR_COUNT - pair_count - 1
      end

      def calculate_kokushi_shanten(hands, melds)
        return 13 if melds.present?
        code_counts = hands.map(&:code).tally
        used_kokushi_codes = code_counts.select { |code, _| KOKUSHI_TILE_CODES.include?(code) }
        unique_count = used_kokushi_codes.keys.size
        has_head = used_kokushi_codes.values.any? { |count| count >= 2 }
        MAX_SHANTEN_COUNT - unique_count - (has_head ? 1 : 0)
      end

      def find_chiitoitsu_outs(hands, melds, tiles)
        return nil if melds.present?

        single_tile_codes = hands.map(&:code).tally.select { |_, count| count == 1 }.keys

        tiles.select do |tile|
          next if hands.map(&:tile).include?(tile)
          single_tile_codes.include?(tile.code)
        end.sort_by(&:code)
      end

      def find_kokushi_outs(hands, melds, tiles)
        return nil if melds.present?

        used_kokushi_codes = hands.map(&:code).select { |code| KOKUSHI_TILE_CODES.include?(code) }
        is_head = used_kokushi_codes.tally.values.any? { |count| count >= 2 }
        kokushi_tiles = tiles.select { |tile| KOKUSHI_TILE_CODES.include?(tile.code) }

        if is_head
          unused_codes = (KOKUSHI_TILE_CODES - used_kokushi_codes)
          kokushi_tiles.select { |tile| unused_codes.include?(tile.code) }.sort_by(&:code)
        else
          kokushi_tiles.reject { |tile| hands.include?(tile) }.sort_by(&:code)
        end
      end
    end
end
