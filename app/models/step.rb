# frozen_string_literal: true

class Step < ApplicationRecord
  belongs_to :honba

  has_many :player_states, dependent: :destroy

  validates :honba, presence: true
  validates :number, presence: true
end
