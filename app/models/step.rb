# frozen_string_literal: true

class Step < ApplicationRecord
  belongs_to :turn

  has_many :player_states, dependent: :destroy

  validates :number, presence: true
  validates :turn, presence: true
end
