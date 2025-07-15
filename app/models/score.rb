# frozen_string_literal: true

class Score < ApplicationRecord
  belongs_to :player
  belongs_to :honba

  validates :score, presence: true
  validates :player, presence: true
  validates :honba, presence: true
end
