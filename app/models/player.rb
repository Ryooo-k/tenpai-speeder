# frozen_string_literal: true

class Player < ApplicationRecord
  PLAYERS_COUNT = 4
  TON_TILE_CODE = 27
  NAN_TILE_CODE = 28
  SHA_TILE_CODE = 29
  PEI_TILE_CODE = 30

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
    create_rivers(chosen_hand)
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
    case wind_seat_number
    when 0 then '東'
    when 1 then '北'
    when 2 then '西'
    when 3 then '南'
    end
  end

  def wind_code
    case wind_seat_number
    when 0 then TON_TILE_CODE
    when 1 then PEI_TILE_CODE
    when 2 then SHA_TILE_CODE
    when 3 then NAN_TILE_CODE
    end
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

    def create_rivers(chosen_hand)
      current_rivers.each { |river| current_state.rivers.create!(tile: river.tile, tsumogiri: river.tsumogiri?) } if current_rivers
      current_state.rivers.create!(tile: chosen_hand.tile, tsumogiri: chosen_hand.drawn?)
    end

    def user_seat_number
      game.user_player.seat_order
    end

    def host_seat_number
      game.host_player.seat_order
    end

    def wind_seat_number
      (host_seat_number - seat_order) % PLAYERS_COUNT
    end
end
