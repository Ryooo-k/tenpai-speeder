# frozen_string_literal: true

class Player < ApplicationRecord
  PLAYERS_COUNT = 4

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
    current_state.rivers
  end

  def receive(tile)
    current_state.hands.create!(tile:)
  end

  def draw(drawn_tile, step)
    current_hand_tiles = current_state.hands.all.map(&:tile)
    player_states.create!(step:)
    create_drawn_hands(current_hand_tiles, drawn_tile)
  end

  def discard(chosen_hand_id, step)
    chosen_hand = current_state.hands.find(chosen_hand_id)
    current_hands = current_state.hands.all
    current_rivers = current_state.rivers.all
    player_states.create!(step:)
    create_discarded_hands(current_hands, chosen_hand)
    create_rivers(current_rivers, chosen_hand)
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

  def shimocha?(player)
    shimocha_seat_order = (player.seat_order + 1) % PLAYERS_COUNT
    seat_order == shimocha_seat_order
  end

  def toimen?(player)
    toimen_seat_order = (player.seat_order + 2) % PLAYERS_COUNT
    seat_order == toimen_seat_order
  end

  def kamicha?(player)
    kamicha_seat_order = (player.seat_order + 3) % PLAYERS_COUNT
    seat_order == kamicha_seat_order
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
      player_states.last
    end

    def create_drawn_hands(hand_tiles, drawn_tile)
      hand_tiles.each { |tile| current_state.hands.create!(tile:) }
      current_state.hands.create!(tile: drawn_tile, drawn: true)
    end

    def create_discarded_hands(current_hands, chosen_hand)
      new_hands = current_hands.select { |hand| hand.id != chosen_hand.id }
      new_hands.each { |hand| current_state.hands.create!(tile: hand.tile) }
    end

    def create_rivers(current_rivers, chosen_hand)
      current_rivers.each { |river| current_state.rivers.create!(tile: river.tile, tsumogiri: river.tsumogiri?) }
      current_state.rivers.create!(tile: chosen_hand.tile, tsumogiri: chosen_hand.drawn?)
    end
end
