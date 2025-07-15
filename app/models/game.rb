# frozen_string_literal: true

class Game < ApplicationRecord
  belongs_to :user
  belongs_to :game_mode
  belongs_to :rule

  has_many :players, dependent: :destroy
  has_many :results, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :rounds, dependent: :destroy
  has_many :tiles, dependent: :destroy

  validates :user, presence: true
  validates :game_mode, presence: true
  validates :rule, presence: true
end
