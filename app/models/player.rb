# frozen_string_literal: true

class Player < ApplicationRecord
  PLAYERS_COUNT = 4

  belongs_to :user, optional: true
  belongs_to :ai, optional: true
  belongs_to :game

  has_many :results, dependent: :destroy
  has_many :scores, dependent: :destroy
  has_many :actions, dependent: :destroy
  has_many :actions_from, class_name: 'Action', foreign_key: 'from_player_id', inverse_of: :from_player
  has_many :player_states, dependent: :destroy

  validates :seat_order, presence: true
  validates :game, presence: true

  validate :validate_player_type

  scope :ordered, -> { order(:seat_order) }

  # ユーザー認証機能を実装後、削除する。
  scope :user, -> { where.not(user_id: nil).first }

  def create_score(honba)
    scores.create!(honba:)
  end

  def create_state(step)
    player_states.create!(step:)
  end

  def state
    player_states.last
  end

  def hands
    state.hands.all.map(&:tile).sort_by(&:code)
  end

  def receive(tile)
    state.hands.create!(tile:)
    game.current_honba.increment!(:draw_count)
  end

  def name
    user&.name || ai&.name
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
end
