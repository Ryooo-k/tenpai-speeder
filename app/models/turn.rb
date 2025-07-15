# frozen_string_literal: true

class Turn < ApplicationRecord
  belongs_to :honba

  has_many :steps, dependent: :destroy

  validates :number, presence: true
  validates :honba, presence: true
end
