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

  def create_game_record(honba)
    game_records.create!(honba:)
  end

  def create_state(step)
    player_states.create!(step:)
  end

  def hands
    current_state.hands.all.map(&:tile).sort_by(&:code)
  end

  def rivers
    current_state.rivers.all.map(&:tile)
  end

  def receive(tile)
    current_state.hands.create!(tile:)
  end

  def draw(drawn_tile, step)
    current_hands = hands
    create_state(step)
    create_drawn_hands(current_hands, drawn_tile)
  end

  def discard(discarded_tile_id, step)
    hand = current_state.hands.find_by!(tile_id: discarded_tile_id)
    current_hands = hands
    current_rivers = rivers
    create_state(step)
    create_discarded_hands(current_hands, hand.tile)
    create_rivers(current_rivers, hand)
  end

  # ai用打牌選択のメソッド
  # 現状は手牌の中からランダムに選択。aiの実装は別issueで対応。
  def choose
    hands.sample.id
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

    def create_drawn_hands(hands, drawn_tile)
      hands.each { |tile| current_state.hands.create!(tile:) }
      current_state.hands.create!(tile: drawn_tile, drawn: true)
    end

    def create_discarded_hands(hands, discarded_tile)
      new_hands = hands.select { |tile| tile.id != discarded_tile.id }
      new_hands.each { |tile| current_state.hands.create!(tile:) }
    end

    def create_rivers(current_rivers, hand)
      current_rivers.each { |tile| current_state.rivers.create!(tile:) }
      current_state.rivers.create!(tile: hand.tile, tsumogiri: hand.drawn?)
    end
end
