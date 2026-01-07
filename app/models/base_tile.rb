# frozen_string_literal: true

class BaseTile < ApplicationRecord
  has_many :tiles

  validates :suit, presence: true
  validates :number, presence: true, inclusion: { in: 1..9 }
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  enum :suit, {
    manzu: 0,
    pinzu: 1,
    souzu: 2,
    zihai: 3
  }
end
