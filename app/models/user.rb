# frozen_string_literal: true

class User < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :games, dependent: :destroy
  has_many :favorites, dependent: :destroy

  validates :name, presence: true, length: { maximum: 10 }
end
