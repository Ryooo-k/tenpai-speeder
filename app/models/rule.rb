# frozen_string_literal: true

class Rule < ApplicationRecord
  has_many :games

  validates :aka_dora, inclusion: { in: [ true, false ] }
  validates :round_type, presence: true

  enum round_type: {
    ikkyoku: 0,
    tonpuu: 1,
    tonnan: 2
  }
end
