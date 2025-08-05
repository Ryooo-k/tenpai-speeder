# frozen_string_literal: true

class GameRecord < ApplicationRecord
  belongs_to :player
  belongs_to :honba, optional: true

  validates :score, presence: true
  validates :player, presence: true
  validates :honba, presence: true, on: :update
end
