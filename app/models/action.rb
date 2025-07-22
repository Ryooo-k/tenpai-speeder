# frozen_string_literal: true

class Action < ApplicationRecord
  belongs_to :step
  belongs_to :player
  belongs_to :from_player, class_name: 'Player', foreign_key: 'from_player_id', inverse_of: :actions_from, optional: true

  has_many :melds, dependent: :destroy

  validates :action_type, presence: true
  validates :step, presence: true
  validates :player, presence: true

  validate :validate_from_player

  enum :action_type, {
    draw: 0,
    discard: 1,
    pon: 2,
    chi: 3,
    daiminkan: 4,
    kakan: 5,
    ankan: 6,
    riichi: 7,
    tsumo: 8,
    ron: 9,
    pass: 10
  }

  private

    def validate_from_player
      if action_type.in?(%w[pon chi daiminkan ron]) && from_player.nil?
        errors.add(:from_player, "#{action_type}の時はfrom_playerが必要です")
      end
    end
end
