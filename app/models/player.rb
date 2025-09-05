# frozen_string_literal: true

class Player < ApplicationRecord
  PLAYERS_COUNT = 4
  TON_TILE_CODE = 27
  NAN_TILE_CODE = 28
  SHA_TILE_CODE = 29
  PEI_TILE_CODE = 30
  KAN_REQUIRED_HAND_COUNT = 3
  PON_REQUIRED_HAND_COUNT = 2

  belongs_to :user, optional: true
  belongs_to :ai, optional: true
  belongs_to :game

  has_many :results, dependent: :destroy
  has_many :game_records, dependent: :destroy
  has_many :actions, dependent: :destroy
  has_many :actions_from, class_name: 'Action', foreign_key: 'from_player_id', inverse_of: :from_player
  has_many :player_states, dependent: :destroy

  validates :seat_order, presence: true
  validates :game, presence: true

  validate :validate_player_type

  scope :ordered, -> { order(:seat_order) }
  scope :users, -> { where.not(user_id: nil) }
  scope :ais, -> { where.not(ai_id: nil) }

  def hands
    current_state.hands.sorted
  end

  def rivers
    current_rivers&.ordered
  end

  def receive(tile)
    current_state.hands.create!(tile:)
  end

  def draw(drawn_tile, step)
    current_hands = current_state.hands
    player_states.create!(step:)
    create_drawn_hands(current_hands, drawn_tile)
  end

  def discard(chosen_hand_id, step)
    chosen_hand = current_state.hands.find(chosen_hand_id)
    current_hands = current_state.hands
    player_states.create!(step:)
    create_discarded_hands(current_hands, chosen_hand)
    create_discarded_rivers(chosen_hand)
    chosen_hand.tile
  end

  def on_discard_called(discarded_tile, step)
    player_states.create!(step:)
    create_called_rivers(discarded_tile)
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

  def relation_from_user
    relation_seat_number = (user_seat_number - seat_order) % PLAYERS_COUNT

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

  def score
    game_records.ordered.last.score
  end

  def wind_name
    case wind_number
    when 0 then '東'
    when 1 then '北'
    when 2 then '西'
    when 3 then '南'
    end
  end

  def wind_code
    case wind_number
    when 0 then TON_TILE_CODE
    when 1 then PEI_TILE_CODE
    when 2 then SHA_TILE_CODE
    when 3 then NAN_TILE_CODE
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

  private

    def validate_player_type
      if user.nil? && ai.nil?
        errors.add(:base, 'UserまたはAIのいずれかを指定してください')
      elsif user.present? && ai.present?
        errors.add(:base, 'UserとAIの両方を同時に指定することはできません')
      end
    end

    def current_state
      player_states.ordered.last
    end

    def current_rivers
      player_states.with_rivers.last&.rivers
    end

    def create_drawn_hands(current_hands, drawn_tile)
      current_hands.each { |hand| current_state.hands.create!(tile_id: hand.tile_id) }
      current_state.hands.create!(tile: drawn_tile, drawn: true)
    end

    def create_discarded_hands(current_hands, chosen_hand)
      new_hands = current_hands.select { |hand| hand.id != chosen_hand.id }
      new_hands.each { |hand| current_state.hands.create!(tile: hand.tile) }
    end

    def create_discarded_rivers(chosen_hand)
      if current_rivers
        current_rivers.each do |river|
          current_state.rivers.create!(
            tile: river.tile,
            tsumogiri: river.tsumogiri?,
            called: river.called,
            created_at: river.created_at
          )
        end
      end
      current_state.rivers.create!(tile: chosen_hand.tile, tsumogiri: chosen_hand.drawn?)
    end

    def create_called_rivers(discarded_tile)
      current_rivers.each do |river|
        called = river.tile == discarded_tile || river.called?
        current_state.rivers.create!(
          tile: river.tile,
          tsumogiri: river.tsumogiri?,
          called:,
          created_at: river.created_at
        )
      end
    end

    def user_seat_number
      game.user_player.seat_order
    end

    def host_seat_number
      game.host_player.seat_order
    end

    def wind_number
      (host_seat_number - seat_order) % PLAYERS_COUNT
    end

    def hand_tiles
      hands.map(&:tile)
    end

    def find_kan_candidates(target_tile)
      return unless can_kan?(target_tile)
      hands.select { |hand| hand.tile.code == target_tile.code }
    end

    def can_kan?(target_tile)
      hand_tiles.map(&:code).tally[target_tile.code] == KAN_REQUIRED_HAND_COUNT
    end

    def find_pon_candidates(target_tile)
      return unless can_pon?(target_tile)
      hands.select { |hand| hand.tile.code == target_tile.code }[..1]
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
                              hands.select { |hand| hand.tile.code == chi_code }.first
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
      candidates << [code - 2, code - 1] if number >= 3
      candidates << [code - 1, code + 1] if (2..8).include?(number)
      candidates << [code + 1, code + 2] if number <= 7
      candidates
    end
end
