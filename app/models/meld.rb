# frozen_string_literal: true

class Meld < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile
  belongs_to :action

  validates :player_states, presence: true
  validates :tile, presence: true
  validates :action, presence: true

  validate :validate_action_type

  private

    def validate_action_type
      action_type = %w[pon chi daiminkan kakan ankan]
      return if action_type.include?(action.action_type)
      errors.add(:action, "#{action.action_type}は許可されていません")
    end
end
