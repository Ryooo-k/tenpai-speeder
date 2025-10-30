# frozen_string_literal: true

class GameMode < ApplicationRecord
  has_many :games

  validates :name, presence: true
  validates :description, presence: true
  validates :round_count, presence: true
  validates :mode_type, presence: true

  enum :mode_type, {
    training: 0,
    match: 1
  }
end
