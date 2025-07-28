# frozen_string_literal: true

class GameMode < ApplicationRecord
  has_many :games

  validates :name, presence: true
  validates :description, presence: true
  validates :round_type, presence: true
  validates :mode_type, presence: true

  enum :round_type, {
    ikkyoku: 0,
    tonpuu: 1,
    tonnan: 2
  }
  enum :mode_type, {
    training: 0,
    match: 1
  }
end
