# frozen_string_literal: true

class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :game

  validates :user, presence: true
  validates :game, presence: true
end
