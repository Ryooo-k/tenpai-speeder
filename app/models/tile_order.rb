# frozen_string_literal: true

class TileOrder < ApplicationRecord
  belongs_to :honba
  belongs_to :tile

  validates :order, presence: true
end
