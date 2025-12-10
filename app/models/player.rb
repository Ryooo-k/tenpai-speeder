# frozen_string_literal: true

class Player < ApplicationRecord
  PLAYERS_COUNT = 4
  TON_TILE_CODE = 27
  NAN_TILE_CODE = 28
  SHA_TILE_CODE = 29
  PEI_TILE_CODE = 30
  KAN_REQUIRED_HAND_COUNT = 3
  PON_REQUIRED_HAND_COUNT = 2
  SHIMOCHA_SEAT_NUMBER = 1
  TOIMEN_SEAT_NUMBER = 2
  KAMICHA_SEAT_NUMBER = 3
  WAITING_TURN_HAND_COUNTS = [ 1, 4, 7, 10, 13 ].freeze
  KAKAN_POSITION = 4
  KAN_COUNT = 4

  belongs_to :user, optional: true
  belongs_to :ai, optional: true
  belongs_to :game

  has_many :results, dependent: :destroy
  has_many :game_records, -> { order(honba_id: :desc) }, dependent: :destroy
  has_many :player_states, -> { order(:step_id) }, dependent: :destroy

  validates :game, presence: true
  validates :seat_order, presence: true

  validate :validate_player_type

  scope :users, -> { where.not(user_id: nil) }
  scope :ais, -> { where.not(ai_id: nil) }

  def hands
    return Hand.none unless base_hands.present?
    base_hands.sort_by { |hand| [ hand.drawn? ? 1 : 0, hand.code ] }
  end

  def rivers
    return River.none unless base_rivers.present?
    base_rivers.reject(&:stolen)
  end

  def rivers_with_rotation
    return River.none unless base_rivers.present?

    rotate_after_stolen_riichi = false

    base_rivers.map do |river|
      rotated = river.riichi? || (rotate_after_stolen_riichi && !river.stolen?)

      if river.riichi? && river.stolen?
        rotate_after_stolen_riichi = true
      elsif rotate_after_stolen_riichi && !river.stolen?
        rotate_after_stolen_riichi = false
      end

      [ river, rotated ]
    end.reject { |river, _| river.stolen? }
  end

  def melds
    return Meld.none unless base_melds_list.present?
    base_melds_list.map { |melds| melds.sort_by(&:position) }.flatten
  end

  def current_state
    base_states.last
  end

  def receive(tile)
    current_state.hands.create!(tile:)
  end

  def draw(drawn_tile, step)
    player_states.create!(step:)
    create_drawn_hands(drawn_tile)
  end

  def discard(chosen_hand_id, step)
    chosen_hand = hands.detect { |hand| hand.id == chosen_hand_id }
    riichi = current_state.riichi?
    player_states.create!(step:)
    create_discarded_hands(chosen_hand)
    create_discarded_rivers(chosen_hand, riichi)
    chosen_hand.tile
  end

  def steal(target_player, furo_type, furo_ids, discarded_tile_id, step)
    furo_hands = hands.select { |hand| furo_ids.include?(hand.id) }
    player_states.create!(step:)
    create_stole_hands(furo_hands)
    create_stole_melds(target_player, furo_type, furo_hands, discarded_tile_id)
  end

  def stolen(discarded_tile_id, step)
    player_states.create!(step:)
    create_stolen_rivers(discarded_tile_id)
  end

  def kan(type, ids, step)
    player_states.create!(step:)
    create_kan_melds(type, ids)
    create_kan_hands(ids)
  end

  # ai用 牌選択メソッド
  def choose
    if current_state.riichi?
      find_riichi_candidates.sample
    else
      hand_index = MahjongAi.infer(game, self)
      base_hands.sorted_base[hand_index]
    end
  end

  def name
    user&.name || ai&.name
  end

  def ai?
    ai_id.present?
  end

  def ai_version
    return if user?
    "v#{ai.version}"
  end

  def user?
    user_id.present?
  end

  def host?
    seat_order == game.latest_round.host_seat_number
  end

  def relation_from_user
    relation_seat_number = (user_seat_number - seat_order) % PLAYERS_COUNT

    case relation_seat_number
    when 0 then :self
    when 1 then :kamicha
    when 2 then :toimen
    when 3 then :shimocha
    end
  end

  def relation_from_current_player
    relation_seat_number = (game.current_player.seat_order - seat_order) % PLAYERS_COUNT

    case relation_seat_number
    when 0 then :self
    when 1 then :kamicha
    when 2 then :toimen
    when 3 then :shimocha
    end
  end

  def drawn?
    hands.any?(&:drawn?)
  end

  def riichi?
    base_states.any?(&:riichi)
  end

  def can_riichi?
    return false if riichi?
    tenpai? && (melds.empty? || melds.all? { |meld| meld.kind == 'ankan' })
  end

  def find_riichi_candidates
    return [] if melds.present? && melds.all? { |meld| meld.kind != 'ankan' }
    HandEvaluator.find_riichi_candidates(hands, melds)
  end

  def point
    latest_game_record.point
  end

  def add_point(addition)
    new_point = point + addition
    latest_game_record.update!(point: new_point)
  end

  def latest_game_record
    game_records.first
  end

  def score
    latest_game_record.score
  end

  def final_score
    latest_game_record.score + latest_game_record.point
  end

  def wind_number
    wind_number = seat_order - host_seat_number
    wind_number.positive? || wind_number.zero? ? wind_number : wind_number + PLAYERS_COUNT
  end

  def wind_name
    case wind_number
    when 0 then '東'
    when 1 then '南'
    when 2 then '西'
    when 3 then '北'
    end
  end

  def wind_code
    case wind_number
    when 0 then TON_TILE_CODE
    when 1 then NAN_TILE_CODE
    when 2 then SHA_TILE_CODE
    when 3 then PEI_TILE_CODE
    end
  end

  def can_ankan_or_kakan?
    can_ankan? || can_kakan?
  end

  def ankan_and_kakan_candidates
    {
      ankan: find_ankan_candidates,
      kakan: find_kakan_candidates
    }.compact
  end

  def can_furo?(target_tile, target_player)
    return false if self == target_player || riichi?
    can_pon?(target_tile) || can_chi?(target_tile, target_player)
  end

  def furo_candidates(target_player: nil, target_tile: nil)
    target_player ||= game.current_player
    target_tile ||= target_player&.rivers&.last&.tile

    return {} if target_tile.nil? || target_player == self

    {
      pon: find_pon_candidates(target_tile),
      chi: find_chi_candidates(target_tile, target_player),
      daiminkan: find_daiminkan_candidates(target_tile)
    }.compact
  end

  def can_tsumo?
    return false unless complete?
    situational_yaku_list = build_situational_yaku_list
    HandEvaluator.can_tsumo?(hands, melds, game.round_wind_number, wind_number, situational_yaku_list)
  end

  def can_ron?(tile)
    return false unless tenpai?
    situational_yaku_list = build_situational_yaku_list(tile:)
    HandEvaluator.can_ron?(hands, melds, tile, relation_from_current_player, game.round_wind_number, wind_number, situational_yaku_list)
  end

  def score_statements(tile: nil)
    target_hands = tile ? hands + [ tile ] : hands
    agari_tile = tile ? tile : hands.detect(&:drawn)
    situational_yaku_list = build_situational_yaku_list(tile:)
    dora_count_list = build_dora_count_list(tile:, ura: riichi?)

    HandEvaluator.get_score_statements(
      target_hands,
      melds,
      agari_tile,
      relation_from_current_player,
      game.round_wind_number,
      wind_number,
      situational_yaku_list,
      dora_count_list
    )
  end

  def tenpai?
    shanten.zero?
  end

  def shanten
    HandEvaluator.calculate_shanten(hands, melds)
  end

  def shanten_without_drawn
    HandEvaluator.calculate_shanten(hands_without_drawn, melds)
  end

  def shanten_decreased?
    (shanten - shanten_without_drawn).negative?
  end

  def outs
    HandEvaluator.find_outs(hands, melds, game.tiles, shanten)
  end

  def hands_to_lower_shanten_and_normal_outs
    unique_hands.each_with_object({}) do |hand, outs|
      tmp_hands = hands - [ hand ]
      new_shanten = HandEvaluator.calculate_shanten(tmp_hands, melds)

      if new_shanten < shanten_without_drawn
        normal_outs = HandEvaluator.find_normal_outs(tmp_hands, melds, game.tiles, new_shanten)
        outs[hand] = normal_outs
      else
        next
      end
    end
  end

  def hands_to_same_shanten_outs
    unique_hands.each_with_object({}) do |hand, outs|
      tmp_hands = hands - [ hand ]
      new_shanten = HandEvaluator.calculate_shanten(tmp_hands, melds)

      if new_shanten == shanten_without_drawn
        normal_outs = HandEvaluator.find_normal_outs(tmp_hands, melds, game.tiles, new_shanten)
        outs[hand] = normal_outs
      else
        next
      end
    end
  end

  def yaku_map_by_waiting_wining_tile
    return {} unless waiting_wining_tile?

    wining_tiles = HandEvaluator.find_wining_tiles(hands, melds, game.tiles)
    dora_count_list = build_dora_count_list(ura: false)

    wining_tiles.each_with_object({}) do |wining_tile, yaku_map|
      next if yaku_map[wining_tile.base_tile].present?

      target_hands = hands + [ wining_tile ]
      situational_yaku_list = build_situational_yaku_list(tile: wining_tile)
      relation = :toimen # self以外になるように設定（役の自摸がつかないようにする）
      score_statements = HandEvaluator.get_score_statements(
        target_hands, melds,
        wining_tile, relation,
        game.round_wind_number,
        wind_number,
        situational_yaku_list,
        dora_count_list
        )
      yaku_map[wining_tile.base_tile] = score_statements[:yaku_list]
    end
  end

  def waiting_wining_tile?
    shanten_without_drawn = HandEvaluator.calculate_shanten(hands_without_drawn, melds)
    shanten_without_drawn.zero? && waiting_turn?
  end

  private

    def validate_player_type
      if user.nil? && ai.nil?
        errors.add(:base, 'UserまたはAIのいずれかを指定してください')
      elsif user.present? && ai.present?
        errors.add(:base, 'UserとAIの両方を同時に指定することはできません')
      end
    end

    def current_step_number
      game.current_step_number
    end

    def base_states
      if player_states.loaded? && player_states.all? { |ps| ps.association(:step).loaded? }
        player_states.select do |ps|
          ps.step.honba_id == game.latest_honba.id &&
            ps.step.number <= current_step_number
        end
      else
        player_states
          .for_honba(game.latest_honba)
          .up_to_step(current_step_number)
      end.to_a
    end

    def base_hands
      base_states
        .select { |bs| bs.hands.present? }
        .sort_by { |bs| bs.step.number }
        .last&.hands
    end

    def base_rivers
      base_states
        .select { |bs| bs.rivers.present? }
        .sort_by { |bs| bs.step.number }
        .last&.rivers
    end

    def base_melds_list
      base_states
        .select { |bs| bs.melds.present? }
        .sort_by { |bs| bs.step.number }.reverse
        .map(&:melds)
    end

    def create_drawn_hands(drawn_tile)
      hands.each { |hand| current_state.hands.create!(tile_id: hand.tile_id) }
      current_state.hands.create!(tile: drawn_tile, drawn: true)
    end

    def create_discarded_hands(chosen_hand)
      new_hands = hands.select { |hand| hand.id != chosen_hand.id }
      new_hands.each { |hand| current_state.hands.create!(tile: hand.tile) }
    end

    def create_stole_hands(furo_hands)
      new_hands = hands.reject { |hand| furo_hands.include?(hand) }
      new_hands.each { |hand| current_state.hands.create!(tile: hand.tile) }
    end

    def create_stole_melds(target_player, furo_type, furo_hands, discarded_tile_id)
      relation_seat_number = (target_player.seat_order - seat_order) % PLAYERS_COUNT
      new_melds = build_melds(relation_seat_number, furo_hands, discarded_tile_id)

      new_melds.each_with_index do |tile, position|
        from = tile.id == discarded_tile_id ? relation_seat_number : nil
        current_state.melds.create!(tile:, kind: furo_type, position:, from:)
      end
    end

    def build_melds(relation_seat_number, furo_hands, discarded_tile_id)
      furo_tiles = furo_hands.map(&:tile)
      discarded_tile = game.tiles.detect { |tile| tile.id == discarded_tile_id }

      case relation_seat_number
      when SHIMOCHA_SEAT_NUMBER
        furo_tiles + [ discarded_tile ]
      when TOIMEN_SEAT_NUMBER
        head, *tail = furo_tiles
        [ head, discarded_tile, *tail ]
      when KAMICHA_SEAT_NUMBER
        [ discarded_tile ] + furo_tiles
      end
    end

    def create_kan_melds(type, ids)
      kind = type.to_s

      if kind == 'ankan'
        ankan_tiles = hands.select { |hand| ids.include?(hand.id) }.map(&:tile)
        ankan_tiles.each_with_index do |tile, position|
          current_state.melds.create!(tile:, kind:, position:)
        end
      else
        kakan_hand = hands.detect { |hand| ids.include?(hand.id) }
        return unless kakan_hand

        current_state.melds.create!(tile: kakan_hand.tile, kind:, position: KAKAN_POSITION)
      end
    end

    def create_kan_hands(ids)
      new_hands = hands.reject { |hand| ids.include?(hand.id) }
      new_hands.each { |hand| current_state.hands.create!(tile: hand.tile) }
    end

    def create_discarded_rivers(chosen_hand, riichi)
      if base_rivers.present?
        base_rivers.each do |river|
          current_state.rivers.create!(
            tile: river.tile,
            tsumogiri: river.tsumogiri?,
            stolen: river.stolen,
            riichi: river.riichi,
            created_at: river.created_at
          )
        end
      end
      current_state.rivers.create!(tile: chosen_hand.tile, tsumogiri: chosen_hand.drawn?, riichi:)
    end

    def create_stolen_rivers(discarded_tile_id)
      rivers.each do |river|
        stolen = river.tile.id == discarded_tile_id || river.stolen?
        current_state.rivers.create!(
          tile: river.tile,
          tsumogiri: river.tsumogiri?,
          stolen:,
          riichi: river.riichi,
          created_at: river.created_at
        )
      end
    end

    def user_seat_number
      game.user_player.seat_order
    end

    def host_seat_number
      game.host.seat_order
    end

    def find_daiminkan_candidates(target_tile)
      return unless can_daiminkan?(target_tile)
      hands.select { |hand| hand.code == target_tile.code }
    end

    def find_ankan_candidates
      hands.group_by(&:code).values.select { |group| group.size == 4 }
    end

    def find_kakan_candidates
      pon_melds = melds.select { |meld| meld.kind == 'pon' }.group_by(&:code)

      hands.each_with_object([]) do |hand, candidates|
        group = pon_melds[hand.code]
        next unless group

        candidates << group + [ hand ]
      end
    end

    def can_daiminkan?(target_tile)
      hands.map(&:code).tally[target_tile.code] == KAN_REQUIRED_HAND_COUNT
    end

    def can_ankan?
      if riichi?
        drawn_hand = hands.detect(&:drawn)
        ankan_candidates = hands.select { |hand| hand.code == drawn_hand.code }
        return if ankan_candidates.size != KAN_COUNT

        tiles = game.tiles
        before_wining_tiles = HandEvaluator.find_wining_tiles(hands_without_drawn, melds, tiles)

        test_hands = hands.reject { |hand| ankan_candidates.include?(hand) }
        test_melds = melds + ankan_candidates.map { |candidate| Meld.create(tile: candidate.tile, kind: 'ankan') }
        after_wining_tiles = HandEvaluator.find_wining_tiles(test_hands, test_melds, tiles)

        before_wining_tiles == after_wining_tiles
      else
        hands.map(&:code).tally.any? { |_, count| count == 4 }
      end
    end

    def can_kakan?
      pon_melds = melds.select { |meld| meld.kind == 'pon' }

      return unless pon_melds.present?

      pon_codes = pon_melds.map(&:code).tally.keys
      hands.any? { |hand| pon_codes.include?(hand.code) }
    end

    def find_pon_candidates(target_tile)
      return unless can_pon?(target_tile)
      hands.select { |hand| hand.code == target_tile.code }[..1]
    end

    def can_pon?(target_tile)
      codes = hands.map(&:code)
      return unless codes.include?(target_tile.code)
      codes.tally[target_tile.code] >= PON_REQUIRED_HAND_COUNT
    end

    def find_chi_candidates(target_tile, target_player)
      return unless can_chi?(target_tile, target_player)

      chi_candidates = []
      hand_codes = hands.map(&:code)
      possible_chi_table = build_possible_chi_table(target_tile)

      possible_chi_table.each do |possible_chi_codes|
        if possible_chi_codes.all? { |code| hand_codes.include?(code) }
          chi_candidates << possible_chi_codes.map do |chi_code|
                              hands.select { |hand| hand.code == chi_code }.first
                            end
        end
      end
      chi_candidates.blank? ? nil : chi_candidates
    end

    def can_chi?(target_tile, target_player)
      kamicha_seat_order = (target_player.seat_order + 1) % PLAYERS_COUNT
      return if seat_order != kamicha_seat_order || target_tile.code >= TON_TILE_CODE

      hand_codes = hands.map(&:code)
      possible_chi_table = build_possible_chi_table(target_tile)
      possible_chi_table.any? do |possible_chi_codes|
        possible_chi_codes.all? { |code| hand_codes.include?(code) }
      end
    end

    def build_possible_chi_table(tile)
      number = tile.number
      code = tile.code

      candidates = []
      candidates << [ code - 2, code - 1 ] if number >= 3
      candidates << [ code - 1, code + 1 ] if (2..8).include?(number)
      candidates << [ code + 1, code + 2 ] if number <= 7
      candidates
    end

    def complete?
      shanten.negative?
    end

    def build_situational_yaku_list(tile: nil)
      SituationalYakuListBuilder.new(self).build(tile)
    end

    def unique_hands
      checker = []

      hands.filter_map do |hand|
        next if checker.include?(hand.code)
        checker << hand.code
        hand
      end
    end

    def hands_without_drawn
      hands.reject(&:drawn)
    end

    def waiting_turn?
      WAITING_TURN_HAND_COUNTS.include?(hands.size) && hands.all? { |hand| !hand.drawn? }
    end

    def build_dora_count_list(tile: nil, dora: true, ura: true, aka: true)
      dora_count = dora ? count_dora(tile) : 0
      uradora_count = ura ? count_uradora(tile) : 0
      akadora_count = aka ? count_akadora(tile) : 0

      { dora: dora_count, ura: uradora_count, aka: akadora_count }
    end

    def count_dora(tile)
      dora_group = game.dora_tiles.group_by(&:id)
      targets = (hands + melds).map(&:tile)
      targets << tile if tile

      targets.map do |tile|
        dora_group.keys.include?(tile.id) ? dora_group[tile.id].size : 0
      end.sum
    end

    def count_uradora(tile)
      uradora_group = game.uradora_tiles.group_by(&:id)
      targets = (hands + melds).map(&:tile)
      targets << tile if tile

      targets.map do |tile|
        uradora_group.keys.include?(tile.id) ? uradora_group[tile.id].size : 0
      end.sum
    end

    def count_akadora(tile)
      targets = (hands + melds)
      targets << tile if tile
      targets.count { |tile| tile.aka? }
    end
end
