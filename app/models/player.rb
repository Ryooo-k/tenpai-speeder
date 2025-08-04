# frozen_string_literal: true

class Player < ApplicationRecord
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
    state.hands.all
  end

  def receive(tile)
    state.hands.create!(tile:)
    game.current_honba.increment!(:draw_count)
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
