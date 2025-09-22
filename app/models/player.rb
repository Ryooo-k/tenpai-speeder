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

  belongs_to :user, optional: true
  belongs_to :ai, optional: true
  belongs_to :game

  has_many :results, dependent: :destroy
  has_many :game_records, dependent: :destroy
  has_many :player_states, dependent: :destroy

  validates :game, presence: true
  validates :seat_order, presence: true

  validate :validate_player_type

  scope :ordered, -> { order(:seat_order) }
  scope :users, -> { where.not(user_id: nil) }
  scope :ais, -> { where.not(ai_id: nil) }

  def hands
    base_hands.present? ? base_hands.sorted : Hand.none
  end

  def rivers
    base_rivers.present? ? base_rivers.where(stolen: false) : River.none
  end

  def melds
    base_melds.present? ? base_melds.sorted : Meld.none
  end

  def current_state
    base_states.ordered.last
  end

  def receive(tile)
    current_state.hands.create!(tile:)
  end

  def draw(drawn_tile, step)
    player_states.create!(step:)
    create_drawn_hands(drawn_tile)
  end

  def discard(chosen_hand_id, step)
    chosen_hand = hands.find(chosen_hand_id)
    player_states.create!(step:)
    create_discarded_hands(chosen_hand)
    create_discarded_rivers(chosen_hand)
    chosen_hand.tile
  end

  def steal(target_player, furo_type, furo_tiles, discarded_tile, step)
    player_states.create!(step:)
    create_stole_hands(furo_tiles)
    create_stole_melds(target_player, furo_type, furo_tiles, discarded_tile)
  end

  def stolen(discarded_tile, step)
    player_states.create!(step:)
    create_stolen_rivers(discarded_tile)
  end

  # ai用打牌選択のメソッド
  # 現状は手牌の中からランダムに選択。aiの実装は別issueで対応。
  def choose
    current_state.hands.sample.id
  end

  def name
    user&.name || ai&.name
  end

  def ai?
    ai_id.present?
  end

  def user?
    user_id.present?
  end

  def host?
    self == game.host_player
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
    current_state.riichi?
  end

  def score
    game_records.ordered.last.score
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

  def can_furo?(target_tile, target_player)
    return if self == target_player
    can_pon?(target_tile) || can_chi?(target_tile, target_player)
  end

  def find_furo_candidates(target_tile, target_player)
    {
      pon: find_pon_candidates(target_tile),
      chi: find_chi_candidates(target_tile, target_player),
      kan: find_kan_candidates(target_tile)
    }.compact
  end

  def can_tsumo?
    HandEvaluator.can_tsumo?(hands, melds, game.round_wind_number, wind_number, situational_tsumo_yaku_list)
  end

  def can_ron?(tile)
    return false unless tenpai?
    HandEvaluator.can_ron?(hands, melds, tile, relation_from_current_player, game.round_wind_number, wind_number, situational_ron_yaku_list(tile))
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
      player_states
        .for_honba(game.latest_honba)
        .up_to_step(current_step_number)
    end

    def base_hands
      base_states.with_hands.ordered.last&.hands
    end

    def base_rivers
      base_states.with_rivers.ordered.last&.rivers
    end

    def base_melds
      Meld.where(player_state: base_states.with_melds)
    end

    def create_drawn_hands(drawn_tile)
      hands.each { |hand| current_state.hands.create!(tile_id: hand.tile_id) }
      current_state.hands.create!(tile: drawn_tile, drawn: true)
    end

    def create_discarded_hands(chosen_hand)
      new_hands = hands.select { |hand| hand.id != chosen_hand.id }
      new_hands.each { |hand| current_state.hands.create!(tile: hand.tile) }
    end

    def create_stole_hands(furo_tiles)
      new_hands = hands.reject { |hand| furo_tiles.include?(hand.tile) }
      new_hands.each { |hand| current_state.hands.create!(tile: hand.tile) }
    end

    def create_stole_melds(target_player, furo_type, furo_tiles, discarded_tile)
      relation_seat_number = (target_player.seat_order - seat_order) % PLAYERS_COUNT
      melds = build_melds(relation_seat_number, furo_tiles, discarded_tile)
      melds.each_with_index do |tile, position|
        from = tile == discarded_tile ? relation_seat_number : nil
        current_state.melds.create!(tile:, kind: furo_type, position:, from:)
      end
    end

    def build_melds(relation_seat_number, furo_tiles, discarded_tile)
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

    def create_discarded_rivers(chosen_hand)
      if rivers
        rivers.each do |river|
          current_state.rivers.create!(tile: river.tile, tsumogiri: river.tsumogiri?, stolen: river.stolen, created_at: river.created_at)
        end
      end
      current_state.rivers.create!(tile: chosen_hand.tile, tsumogiri: chosen_hand.drawn?)
    end

    def create_stolen_rivers(discarded_tile)
      rivers.each do |river|
        stolen = river.tile == discarded_tile || river.stolen?
        current_state.rivers.create!(tile: river.tile, tsumogiri: river.tsumogiri?, stolen:, created_at: river.created_at)
      end
    end

    def user_seat_number
      game.user_player.seat_order
    end

    def host_seat_number
      game.host_player.seat_order
    end

    def hand_tiles
      hands.map(&:tile)
    end

    def find_kan_candidates(target_tile)
      return unless can_kan?(target_tile)
      hands.select { |hand| hand.code == target_tile.code }
    end

    def can_kan?(target_tile)
      hand_tiles.map(&:code).tally[target_tile.code] == KAN_REQUIRED_HAND_COUNT
    end

    def find_pon_candidates(target_tile)
      return unless can_pon?(target_tile)
      hands.select { |hand| hand.code == target_tile.code }[..1]
    end

    def can_pon?(target_tile)
      codes = hand_tiles.map(&:code)
      return unless codes.include?(target_tile.code)
      codes.tally[target_tile.code] >= PON_REQUIRED_HAND_COUNT
    end

    def find_chi_candidates(target_tile, target_player)
      return unless can_chi?(target_tile, target_player)

      chi_candidates = []
      hand_codes = hand_tiles.map(&:code)
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

      hand_codes = hand_tiles.map(&:code)
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

    def shanten
      HandEvaluator.calculate_shanten(hands, melds)
    end

    def tenpai?
      shanten.zero?
    end

    def complete?
      shanten.negative?
    end

    def can_haitei_tsumo?
      game.remaining_tile_count.zero? && complete?
    end

    def can_houtei_ron?(tile)
      test_hands = hands.dup << tile
      shanten = HandEvaluator.calculate_shanten(test_hands, melds)
      game.remaining_tile_count.zero? && shanten.negative?
    end

    def can_rinshan_tsumo?
      return false unless complete?
      hands.any? { |hand| hand.drawn && hand.rinshan }
    end

    def can_chankan?(meld)
      return false unless meld.is_a?(Meld)

      test_hands = hands.dup << meld
      shanten = HandEvaluator.calculate_shanten(test_hands, melds)
      meld.kind == 'kakan' && shanten.negative?
    end

    def situational_tsumo_yaku_list
      {
        riichi: riichi?,
        haitei: can_haitei_tsumo?,
        rinshan: can_rinshan_tsumo?,
        double_riichi: false, # ツモ可否判定では不要のため false で固定
        tenhou: false,        # 同上
        ippatsu: false,       # 同上
        chiihou: false,       # ロン和了の状況役のため false で固定
        houtei: false,        # 同上
        chankan: false        # 同上
      }
    end

    def situational_ron_yaku_list(tile)
      {
        riichi: riichi?,
        houtei: can_houtei_ron?(tile),
        chankan: can_chankan?(tile),
        chiihou: false,       # ロン和了の状況役のため false で固定
        haitei: false,        # ロン和了の状況役のため false で固定
        rinshan: false,       # 同上
        double_riichi: false, # 同上
        tenhou: false,        # 同上
        ippatsu: false        # 同上
      }
    end
end
