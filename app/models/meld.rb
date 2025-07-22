# frozen_string_literal: true

class Meld < ApplicationRecord
  belongs_to :player_state
  belongs_to :tile
  belongs_to :action

  validates :player_state, presence: true
  validates :tile, presence: true
  validates :action, presence: true

  validate :validate_action_type

  private

    def validate_action_type
      return errors.add(:action, 'actionが存在しません') if action.nil?

      allowed_action_types = %w[pon chi daiminkan kakan ankan]
      return if allowed_action_types.include?(action.action_type)
      errors.add(:action, "#{action.action_type}は許可されていません")
    end
end
