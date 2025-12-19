# frozen_string_literal: true

class Result < ApplicationRecord
  belongs_to :game
  belongs_to :player

  validates :score, presence: true
  validates :rank, presence: true
end
