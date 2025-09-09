# frozen_string_literal: true

class PlayerState < ApplicationRecord
  belongs_to :player
  belongs_to :step

  has_many :hands, dependent: :destroy
  has_many :rivers, dependent: :destroy
  has_many :melds, dependent: :destroy

  validates :riichi, inclusion: { in: [ true, false ] }
  validates :player, presence: true
  validates :step, presence: true

  scope :ordered, -> { order(step_id: :asc) }
  scope :up_to_step, ->(n) { joins(:step).where(steps: { number: ..n }) }
  scope :with_hands, -> { where.associated(:hands) }
  scope :with_rivers, -> { where.associated(:rivers) }
  scope :with_melds, -> { where.associated(:melds) }
end
