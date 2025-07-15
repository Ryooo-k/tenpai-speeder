# frozen_string_literal: true

class Ai < ApplicationRecord
  has_many :players, dependent: :destroy

  validates :version, presence: true
end
