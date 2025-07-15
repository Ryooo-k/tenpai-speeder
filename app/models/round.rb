# frozen_string_literal: true

class Round < ApplicationRecord
  belongs_to :game

  has_many :honbas, dependent: :destroy

  validates :number, presence: true
  validates :host_position, presence: true
  validates :game, presence: true
end
