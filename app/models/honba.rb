# frozen_string_literal: true

class Honba < ApplicationRecord
  belongs_to :round

  has_many :turns, dependent: :destroy
  has_many :tile_orders, dependent: :destroy
  has_many :scores, dependent: :destroy

  validates :round, presence: true
end
